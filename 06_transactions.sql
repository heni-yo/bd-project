-- Script 06 : demos transactions + concurrence.
-- Pre-requis : scripts 01 a 05 executes.

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET DEFINE OFF;

-- ============================================================
-- PARTIE A : DEMOS TRANSACTIONS (COMMIT / ROLLBACK / SAVEPOINT)
-- On manipule un etudiant temporaire T777.
-- ============================================================

-- Nettoyage pour pouvoir rejouer le script
DELETE FROM NOTE            WHERE id_insc_ped IN (
    SELECT id_insc_ped FROM INSCRIPTION_PED WHERE id_insc_adm IN (
        SELECT id_insc_adm FROM INSCRIPTION_ADM WHERE cne = 'T777'));
DELETE FROM INSCRIPTION_PED WHERE id_insc_adm IN (
    SELECT id_insc_adm FROM INSCRIPTION_ADM WHERE cne = 'T777');
DELETE FROM INSCRIPTION_ADM WHERE cne = 'T777';
DELETE FROM ETUDIANT        WHERE cne = 'T777';
COMMIT;

-- Demo 1 : COMMIT reussi (les donnees sont persistees)
PROMPT ====================================================
PROMPT  DEMO 1 : COMMIT reussi
PROMPT ====================================================

INSERT INTO ETUDIANT (cne, nom, prenom, date_naissance, sexe, email)
VALUES ('T777', 'TRANS', 'Demo', DATE '2000-01-01', 'M', 'trans.demo@etu.ma');

COMMIT;

SELECT cne, nom, prenom FROM ETUDIANT WHERE cne = 'T777';
-- Attendu : 1 ligne (TRANS / Demo).

-- Demo 2 : ROLLBACK (la modification est annulee)
PROMPT ====================================================
PROMPT  DEMO 2 : ROLLBACK
PROMPT ====================================================

UPDATE ETUDIANT SET nom = 'MODIFIE_AVANT_ROLLBACK' WHERE cne = 'T777';

-- Dans la session courante, le nom est temporairement modifie.
SELECT 'AVANT ROLLBACK' AS moment, nom FROM ETUDIANT WHERE cne = 'T777';

ROLLBACK;

-- Apres le ROLLBACK, on retrouve la valeur d'avant.
SELECT 'APRES ROLLBACK' AS moment, nom FROM ETUDIANT WHERE cne = 'T777';

-- Demo 3 : SAVEPOINT (annuler une partie d'une transaction)
PROMPT ====================================================
PROMPT  DEMO 3 : SAVEPOINT + rollback partiel
PROMPT ====================================================

DECLARE
    v_nom VARCHAR2(50);
BEGIN
    -- 1re modification.
    UPDATE ETUDIANT SET nom = 'VERSION_1' WHERE cne = 'T777';

    SAVEPOINT sp_step1;

    -- 2e modification (sera annulee).
    UPDATE ETUDIANT SET nom = 'VERSION_2' WHERE cne = 'T777';

    SELECT nom INTO v_nom FROM ETUDIANT WHERE cne = 'T777';
    DBMS_OUTPUT.PUT_LINE('[Avant rollback partiel] nom = ' || v_nom);

    -- Retour au savepoint : VERSION_1 est conservee, VERSION_2 annulee.
    ROLLBACK TO SAVEPOINT sp_step1;

    SELECT nom INTO v_nom FROM ETUDIANT WHERE cne = 'T777';
    DBMS_OUTPUT.PUT_LINE('[Apres rollback partiel] nom = ' || v_nom);

    COMMIT;

    SELECT nom INTO v_nom FROM ETUDIANT WHERE cne = 'T777';
    DBMS_OUTPUT.PUT_LINE('[Apres COMMIT final] nom = ' || v_nom);
END;
/

-- Attendu :
--   [Avant rollback partiel] nom = VERSION_2
--   [Apres rollback partiel] nom = VERSION_1
--   [Apres COMMIT final]     nom = VERSION_1

-- Nettoyage de T777 avant la partie concurrence
DELETE FROM ETUDIANT WHERE cne = 'T777';
COMMIT;

-- ============================================================
-- PARTIE B : PROC_SAISIR_NOTE_CONCURRENT
-- Saisit une note en posant un verrou exclusif sur la ligne
-- INSCRIPTION_PED (SELECT ... FOR UPDATE). Si deux sessions
-- essaient de saisir la meme note, la 2e attend la 1re.
-- Aucune dependance a un package systeme privilegie.
-- ============================================================

CREATE OR REPLACE PROCEDURE PROC_SAISIR_NOTE_CONCURRENT (
    p_cne           IN VARCHAR2,
    p_annee_libelle IN VARCHAR2,
    p_code_module   IN VARCHAR2,
    p_note_examen   IN NUMBER,
    p_note_cc       IN NUMBER
) IS
    v_id_insc_ped   INSCRIPTION_PED.id_insc_ped%TYPE;
    v_id_note       NOTE.id_note%TYPE;
    v_poids_examen  NUMBER;
    v_poids_cc      NUMBER;
    v_note_finale   NUMBER;
BEGIN
    -- Recherche de l'inscription pedagogique (sans verrou).
    BEGIN
        SELECT ip.id_insc_ped INTO v_id_insc_ped
          FROM INSCRIPTION_PED ip
          JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
          JOIN ANNEE_UNIV      a  ON a.id_annee     = ia.id_annee
          JOIN MODULE          m  ON m.id_module    = ip.id_module
         WHERE ia.cne        = p_cne
           AND a.libelle     = p_annee_libelle
           AND m.code_module = p_code_module;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20050,
                'Inscription pedagogique introuvable : '
                || p_cne || ' / ' || p_code_module || ' / ' || p_annee_libelle);
    END;

    -- Pose du verrou : toute autre session qui refera ce SELECT
    -- FOR UPDATE sur la meme ligne devra attendre notre COMMIT.
    SELECT id_insc_ped INTO v_id_insc_ped
      FROM INSCRIPTION_PED
     WHERE id_insc_ped = v_id_insc_ped
       FOR UPDATE;

    DBMS_OUTPUT.PUT_LINE('[' || USER || '] VERROU POSE sur id_insc_ped='
                         || v_id_insc_ped);

    -- Calcul de la note finale a partir des parametres.
    SELECT TO_NUMBER(valeur) INTO v_poids_examen
      FROM PARAMETRE WHERE code_param = 'POIDS_EXAMEN';
    SELECT TO_NUMBER(valeur) INTO v_poids_cc
      FROM PARAMETRE WHERE code_param = 'POIDS_CC';

    v_note_finale := ROUND(
        p_note_examen * v_poids_examen + p_note_cc * v_poids_cc, 2);

    -- UPDATE si la note existe deja, sinon INSERT.
    BEGIN
        SELECT id_note INTO v_id_note
          FROM NOTE WHERE id_insc_ped = v_id_insc_ped;

        UPDATE NOTE
           SET note_examen = p_note_examen,
               note_cc     = p_note_cc,
               note_finale = v_note_finale,
               date_saisie = SYSDATE,
               validee     = 1
         WHERE id_note     = v_id_note;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO NOTE
                (note_examen, note_cc, note_finale, session_type,
                 date_saisie, validee, id_insc_ped)
            VALUES
                (p_note_examen, p_note_cc, v_note_finale, 'NORMALE',
                 SYSDATE, 1, v_id_insc_ped);
    END;

    -- COMMIT : libere le verrou, les autres sessions peuvent continuer.
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[' || USER || '] COMMIT -> verrou libere, '
                         || 'note_finale = ' || v_note_finale);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[' || USER || '] ROLLBACK -> ' || SQLERRM);
        RAISE;
END PROC_SAISIR_NOTE_CONCURRENT;
/

-- Verification de la compilation
DECLARE
    v_status user_objects.status%TYPE;
BEGIN
    SELECT status INTO v_status
      FROM user_objects
     WHERE object_name = 'PROC_SAISIR_NOTE_CONCURRENT'
       AND object_type = 'PROCEDURE';
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  PROC_SAISIR_NOTE_CONCURRENT : ' || v_status);
    DBMS_OUTPUT.PUT_LINE('====================================================');
END;
/

-- Test rapide en une seule session (juste pour verifier que la procedure
-- fonctionne). La demo de concurrence vraie se fait en Partie C.
PROMPT ====================================================
PROMPT  TEST MONO-SESSION de PROC_SAISIR_NOTE_CONCURRENT
PROMPT  (E002 / SMI1001 / 2025-2026)
PROMPT ====================================================
BEGIN
    PROC_SAISIR_NOTE_CONCURRENT(
        p_cne           => 'E002',
        p_annee_libelle => '2025-2026',
        p_code_module   => 'SMI1001',
        p_note_examen   => 12,
        p_note_cc       => 13);
END;
/

-- Verification du resultat
SELECT m.code_module, n.note_examen, n.note_cc, n.note_finale
  FROM NOTE             n
  JOIN INSCRIPTION_PED  ip ON ip.id_insc_ped = n.id_insc_ped
  JOIN INSCRIPTION_ADM  ia ON ia.id_insc_adm = ip.id_insc_adm
  JOIN MODULE           m  ON m.id_module    = ip.id_module
 WHERE ia.cne = 'E002'
   AND m.code_module = 'SMI1001';

-- ============================================================
-- PARTIE C : DEMO A DEUX SESSIONS (a faire manuellement)
-- ============================================================

/*
================================================================================
  DEMO CONCURRENCE - MODE D'EMPLOI (2 SESSIONS SQL DEVELOPER)
  (Aucun sleep artificiel : on laisse la Session A "ouverte" sans COMMIT.)
================================================================================

PREREQUIS
---------
- Script 06 execute au moins une fois (procedure compilee).
- Ouvrir DEUX fenetres SQL Worksheet connectees au MEME schema Oracle.
- Activer DBMS Output dans les DEUX fenetres (View > DBMS Output > +).
- Cible : note de E002 / SMI1001 / 2025-2026.

--------------------------------------------------------------------------------
  SCENARIO 1 : Verrouillage avec attente (comportement par defaut Oracle)
  Principe : Session A prend le verrou et NE COMMIT PAS tout de suite.
             Session B tente une modification de la meme ligne et est BLOQUEE.
             Tant que A n'a pas COMMIT ni ROLLBACK, B attend.
--------------------------------------------------------------------------------

ETAPE 1 (Session A) - Poser le verrou manuellement (SANS committer) :

    SET SERVEROUTPUT ON;

    SELECT ip.id_insc_ped, n.note_examen, n.note_cc, n.note_finale
      FROM INSCRIPTION_PED ip
      JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
      JOIN ANNEE_UNIV      a  ON a.id_annee     = ia.id_annee
      JOIN MODULE          m  ON m.id_module    = ip.id_module
      LEFT JOIN NOTE       n  ON n.id_insc_ped  = ip.id_insc_ped
     WHERE ia.cne        = 'E002'
       AND a.libelle     = '2025-2026'
       AND m.code_module = 'SMI1001'
       FOR UPDATE OF ip.id_insc_ped;

    -- [VERROU POSE] par Session A. NE PAS COMMITER.
    -- Passer immediatement a l'etape 2 dans l'autre fenetre.


ETAPE 2 (Session B) - Tenter la meme modification via la procedure :

    SET SERVEROUTPUT ON;
    BEGIN
        PROC_SAISIR_NOTE_CONCURRENT(
            p_cne           => 'E002',
            p_annee_libelle => '2025-2026',
            p_code_module   => 'SMI1001',
            p_note_examen   => 5,
            p_note_cc       => 5);
    END;
    /

    -- Session B EST BLOQUEE : aucun retour, aucune erreur, juste attente.
    -- SQL Developer affiche "Statement running..." tant que A n'a pas termine.


ETAPE 3 (Session A) - Moderniser la note, puis COMMIT :

    UPDATE NOTE
       SET note_examen = 18, note_cc = 19, note_finale = 0.6*18 + 0.4*19,
           date_saisie = SYSDATE, validee = 1
     WHERE id_insc_ped = (SELECT ip.id_insc_ped
                            FROM INSCRIPTION_PED ip
                            JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
                            JOIN ANNEE_UNIV      a  ON a.id_annee     = ia.id_annee
                            JOIN MODULE          m  ON m.id_module    = ip.id_module
                           WHERE ia.cne = 'E002' AND a.libelle = '2025-2026'
                             AND m.code_module = 'SMI1001');

    COMMIT;
    -- [VERROU LIBERE]


ETAPE 4 (Session B) - Se debloque automatiquement :

    -- Session B reprend immediatement la main.
    -- Elle pose son propre verrou, applique sa mise a jour (examen=5, cc=5),
    -- et COMMIT a son tour.
    -- Affichage dans DBMS Output de Session B :
    --   [<USER>] VERROU POSE sur id_insc_ped=...
    --   [<USER>] COMMIT -> verrou libere, note_finale = 5


RESULTAT FINAL :
    La valeur persistee dans NOTE est celle de Session B (derniere a COMMIT).
    Les deux UPDATE ont ete SERIALISES par le verrou : aucun lost update.

--------------------------------------------------------------------------------
  SCENARIO 2 : Verification du resultat final
--------------------------------------------------------------------------------

    SELECT m.code_module, n.note_examen, n.note_cc, n.note_finale,
           TO_CHAR(n.date_saisie,'YYYY-MM-DD HH24:MI:SS') AS date_saisie
      FROM NOTE              n
      JOIN INSCRIPTION_PED   ip ON ip.id_insc_ped = n.id_insc_ped
      JOIN INSCRIPTION_ADM   ia ON ia.id_insc_adm = ip.id_insc_adm
      JOIN MODULE            m  ON m.id_module    = ip.id_module
     WHERE ia.cne = 'E002' AND m.code_module = 'SMI1001';

Attendu : examen=5, cc=5, finale=5.0 (valeur de Session B).

--------------------------------------------------------------------------------
  SCENARIO 3 : Verification via la table JOURNAL (audit)
--------------------------------------------------------------------------------

    SELECT id_journal, type_operation, cle_enregistrement,
           TO_CHAR(date_operation,'HH24:MI:SS') AS heure, utilisateur
      FROM JOURNAL
     WHERE nom_table = 'NOTE'
       AND date_operation >= SYSTIMESTAMP - INTERVAL '10' MINUTE
     ORDER BY id_journal DESC;

Attendu : deux lignes UPDATE sur le meme ID_NOTE, horodatages differents.
          Les deux mises a jour sont tracees independamment.

--------------------------------------------------------------------------------
  VARIANTE NOWAIT (detection immediate de conflit, sans attente)
--------------------------------------------------------------------------------

Pour tester le mode "fail-fast" sans modifier la procedure, executer dans une
Session B alternative :

    SELECT id_insc_ped FROM INSCRIPTION_PED
     WHERE id_insc_ped = (
         SELECT ip.id_insc_ped FROM INSCRIPTION_PED ip
           JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
           JOIN MODULE m ON m.id_module = ip.id_module
          WHERE ia.cne='E002' AND a.libelle='2025-2026' AND m.code_module='SMI1001')
     FOR UPDATE NOWAIT;

Pendant que la Session A detient le verrou, la Session B recoit IMMEDIATEMENT :
    ORA-00054: resource busy and acquire with NOWAIT specified

Utile pour ne pas bloquer un utilisateur final : on remonte l'erreur tout de
suite et on l'informe que la ressource est occupee.

--------------------------------------------------------------------------------
  NETTOYAGE (optionnel, apres la demo)
--------------------------------------------------------------------------------

Pour remettre E002 dans son etat initial (note echec a 7.2) :

    UPDATE NOTE n
       SET note_examen = 8, note_cc = 6, note_finale = 7.2,
           date_saisie = SYSDATE, validee = 1
     WHERE id_insc_ped = (
         SELECT ip.id_insc_ped FROM INSCRIPTION_PED ip
           JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
           JOIN MODULE m ON m.id_module = ip.id_module
          WHERE ia.cne='E002' AND a.libelle='2025-2026' AND m.code_module='SMI1001');
    COMMIT;
================================================================================
*/

-- ============================================================
-- PARTIE D : RAPPEL THEORIQUE (utile pour le rapport)
-- ============================================================

/*
ACID (proprietes d'une transaction) :
  A - Atomicite  : tout-ou-rien (COMMIT valide tout, ROLLBACK annule tout).
  C - Coherence  : la base reste coherente (contraintes respectees).
  I - Isolation  : les transactions concurrentes ne se voient pas entre elles.
  D - Durabilite : une fois COMMITee, la transaction survit aux pannes.

READ COMMITTED (niveau d'isolation par defaut Oracle) :
  - Chaque requete voit l'etat COMMIT au moment ou elle COMMENCE.
  - Pas de lecture "sale" (jamais de donnees non commitees d'autres sessions).
  - Les modifications non commitees des autres sessions sont invisibles.
  - Alternative plus stricte : ALTER SESSION SET ISOLATION LEVEL SERIALIZABLE.

SELECT ... FOR UPDATE :
  - Pose un verrou exclusif sur les lignes lues.
  - Variantes utiles :
       FOR UPDATE          : attente illimitee (par defaut)
       FOR UPDATE NOWAIT   : erreur ORA-00054 immediate si deja verrouille
       FOR UPDATE WAIT n   : attente max n secondes, sinon ORA-30006
       FOR UPDATE SKIP LOCKED : ignore les lignes deja verrouillees

Lost update (mise a jour perdue) :
  SANS verrouillage :
     A : lit solde=1000, ecrit 1200 (=1000+200) ; COMMIT.
     B : lit solde=1000 (avant A), ecrit 1300 (=1000+300) ; COMMIT.
     -> les 200 de A sont perdus (il faudrait 1500).
  AVEC SELECT ... FOR UPDATE :
     B attend le COMMIT de A, relit 1200, ecrit 1500 ; COMMIT.
     -> aucune perte, les mises a jour sont serialisees.

C'est exactement ce que fait PROC_SAISIR_NOTE_CONCURRENT : empecher
deux enseignants d'ecraser la meme note en meme temps.
*/

-- ============================================================
-- PARTIE E : CONFIRMATION FINALE
-- ============================================================

DECLARE
    v_proc_status user_objects.status%TYPE;
BEGIN
    SELECT status INTO v_proc_status
      FROM user_objects
     WHERE object_name = 'PROC_SAISIR_NOTE_CONCURRENT'
       AND object_type = 'PROCEDURE';

    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  SCRIPT 06 - TRANSACTIONS & CONCURRENCE');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  Demos transactions (A,B,C)   : executees');
    DBMS_OUTPUT.PUT_LINE('  PROC_SAISIR_NOTE_CONCURRENT  : ' || v_proc_status);
    DBMS_OUTPUT.PUT_LINE('  Test mono-session            : execute');
    DBMS_OUTPUT.PUT_LINE('  Demo 2 sessions (Partie C)   : a lancer manuellement');
    DBMS_OUTPUT.PUT_LINE('====================================================');
END;
/

-- FIN DU SCRIPT 06 ------------------------------------------------------------

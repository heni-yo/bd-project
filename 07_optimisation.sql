-- Script 07 : optimisation des requetes + reprise sur panne.
-- Pre-requis : scripts 01 a 06 executes.
-- Compte etudiant standard (pas de droits DBA requis).

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET DEFINE OFF;
SET LINESIZE 200;
SET PAGESIZE 50;

-- PLAN_TABLE est disponible par defaut dans Oracle >= 10g.
-- Si ORA-02404, demander au DBA : @?/rdbms/admin/utlxplan.sql

-- ============================================================
-- PARTIE A : OPTIMISATION DES REQUETES
-- On analyse 2 requetes representatives avec EXPLAIN PLAN et on
-- compare le cout selon que les index sont utilises ou pas.
-- ============================================================

-- Requete 1 : releve de notes d'un etudiant pour une annee.
-- Croisement de 6 tables avec filtre sur (cne, annee).

PROMPT ====================================================
PROMPT  REQUETE 1 : Releve de notes E001 / 2024-2025
PROMPT ====================================================

-- Execution simple (voir le resultat)
SELECT et.cne, m.code_module, m.libelle AS module_lib, m.coefficient,
       n.note_examen, n.note_cc, n.note_finale
  FROM ETUDIANT        et
  JOIN INSCRIPTION_ADM ia ON ia.cne         = et.cne
  JOIN ANNEE_UNIV      a  ON a.id_annee     = ia.id_annee
  JOIN INSCRIPTION_PED ip ON ip.id_insc_adm = ia.id_insc_adm
  JOIN MODULE          m  ON m.id_module    = ip.id_module
  LEFT JOIN NOTE       n  ON n.id_insc_ped  = ip.id_insc_ped
 WHERE et.cne      = 'E001'
   AND a.libelle   = '2024-2025'
 ORDER BY m.code_module;

-- Plan d'execution
PROMPT ====================================================
PROMPT  Plan d'execution - REQUETE 1
PROMPT ====================================================

EXPLAIN PLAN SET STATEMENT_ID = 'Q1_RELEVE' FOR
SELECT et.cne, m.code_module, m.libelle AS module_lib, m.coefficient,
       n.note_examen, n.note_cc, n.note_finale
  FROM ETUDIANT        et
  JOIN INSCRIPTION_ADM ia ON ia.cne         = et.cne
  JOIN ANNEE_UNIV      a  ON a.id_annee     = ia.id_annee
  JOIN INSCRIPTION_PED ip ON ip.id_insc_adm = ia.id_insc_adm
  JOIN MODULE          m  ON m.id_module    = ip.id_module
  LEFT JOIN NOTE       n  ON n.id_insc_ped  = ip.id_insc_ped
 WHERE et.cne      = 'E001'
   AND a.libelle   = '2024-2025'
 ORDER BY m.code_module;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q1_RELEVE', 'TYPICAL'));

/* Analyse
   - Avec les index du script 01 on doit voir INDEX UNIQUE/RANGE SCAN
     sur PK_ETUDIANT, IDX_INSC_ADM_ETUD, UK_ANNEE_LIBELLE, etc.
   - NESTED LOOPS est attendu grace aux filtres precis.
   - Un TABLE ACCESS FULL sur une grosse table serait a eviter.
   - En production, lancer DBMS_STATS.GATHER_SCHEMA_STATS(USER) pour
     que l'optimiseur ait des stats recentes. */

-- Comparaison : on force un FULL SCAN avec le hint /*+ FULL(ia) */
-- pour voir que le cout augmente --> les index servent bien a quelque chose.

PROMPT ====================================================
PROMPT  REQUETE 1 (variante avec /*+ FULL(ia) */) - plan
PROMPT ====================================================

EXPLAIN PLAN SET STATEMENT_ID = 'Q1_FULL' FOR
SELECT /*+ FULL(ia) */ et.cne, m.code_module
  FROM ETUDIANT        et
  JOIN INSCRIPTION_ADM ia ON ia.cne         = et.cne
  JOIN ANNEE_UNIV      a  ON a.id_annee     = ia.id_annee
  JOIN INSCRIPTION_PED ip ON ip.id_insc_adm = ia.id_insc_adm
  JOIN MODULE          m  ON m.id_module    = ip.id_module
 WHERE et.cne    = 'E001'
   AND a.libelle = '2024-2025';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q1_FULL', 'TYPICAL'));

-- On doit voir TABLE ACCESS FULL sur INSCRIPTION_ADM et un cout superieur
-- au plan nominal --> preuve concrete que l'index IDX_INSC_ADM_ETUD sert.

-- Requete 2 : moyenne ponderee par etudiant/annee (agregation).

PROMPT ====================================================
PROMPT  REQUETE 2 : Moyenne ponderee par etudiant / annee
PROMPT ====================================================

SELECT ia.cne,
       a.libelle AS annee,
       ROUND(SUM(n.note_finale * m.coefficient)
           / NULLIF(SUM(m.coefficient), 0), 2) AS moyenne_ponderee,
       COUNT(n.id_note) AS nb_notes
  FROM INSCRIPTION_ADM  ia
  JOIN ANNEE_UNIV       a  ON a.id_annee     = ia.id_annee
  JOIN INSCRIPTION_PED  ip ON ip.id_insc_adm = ia.id_insc_adm
  JOIN MODULE           m  ON m.id_module    = ip.id_module
  JOIN NOTE             n  ON n.id_insc_ped  = ip.id_insc_ped
 GROUP BY ia.cne, a.libelle
 ORDER BY ia.cne, a.libelle;

-- Plan d'execution
PROMPT ====================================================
PROMPT  Plan d'execution - REQUETE 2
PROMPT ====================================================

EXPLAIN PLAN SET STATEMENT_ID = 'Q2_MOYENNES' FOR
SELECT ia.cne,
       a.libelle AS annee,
       ROUND(SUM(n.note_finale * m.coefficient)
           / NULLIF(SUM(m.coefficient), 0), 2) AS moyenne_ponderee
  FROM INSCRIPTION_ADM  ia
  JOIN ANNEE_UNIV       a  ON a.id_annee     = ia.id_annee
  JOIN INSCRIPTION_PED  ip ON ip.id_insc_adm = ia.id_insc_adm
  JOIN MODULE           m  ON m.id_module    = ip.id_module
  JOIN NOTE             n  ON n.id_insc_ped  = ip.id_insc_ped
 GROUP BY ia.cne, a.libelle;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q2_MOYENNES', 'TYPICAL'));

/* Analyse
   Sans filtre WHERE, Oracle prefere souvent HASH JOIN + FULL TABLE SCAN.
   C'est normal et efficace pour une agregation globale : un scan sequentiel
   + hash est plus rapide que l'utilisation d'index sur de gros volumes.

   Les index ne sont donc pas toujours benefiques : tout depend du filtre,
   de la selectivite et des stats. L'optimiseur Oracle (CBO) choisit.

   Pistes pour le rapport :
   - Toujours filtrer par annee courante (AND a.est_courante = 1).
   - Rafraichir les stats : DBMS_STATS.GATHER_TABLE_STATS(USER, 'NOTE').
   - Vues materialisees pour les tableaux de bord tres consultes.
   - Surveiller les index inutilises (V$OBJECT_USAGE). */

-- ============================================================
-- PARTIE B : REPRISE SUR PANNE + STRATEGIE DE SAUVEGARDE
-- ============================================================

/*
Mecanismes Oracle (rappel pour le rapport)
------------------------------------------
REDO log     : fichiers sequentiels qui enregistrent toutes les modifs.
               Au COMMIT, les redo sont forces sur disque. Permettent de
               rejouer les changements apres un crash.
UNDO         : anciennes valeurs avant modification. Sert a ROLLBACK et a
               la lecture coherente pour les autres sessions.
COMMIT       : rend les modifs durables et visibles.
ROLLBACK     : annule les modifs non commitees grace aux donnees UNDO.
ARCHIVELOG   : mode optionnel ou Oracle archive les redo logs. Permet
               de restaurer a n'importe quel point dans le temps.
Instance recovery : automatique au redemarrage apres un crash :
               REDO forward (rejoue les modifs commitees) puis UNDO
               rollback (annule les transactions en cours au crash).

Ce que ce projet demontre vraiment :
  [x] COMMIT / ROLLBACK / SAVEPOINT          (script 06)
  [x] SELECT ... FOR UPDATE                  (script 06)
  [x] Journalisation applicative dans JOURNAL (script 05)
  [x] Snapshot par CTAS                      (ci-dessous)
  [x] Export texte via SPOOL                 (ci-dessous)
  [ ] REDO/UNDO/ARCHIVELOG : automatique Oracle, pas demontrable
      depuis un compte etudiant (privileges DBA requis).

Strategies de sauvegarde compatibles compte etudiant :
  A. CTAS (Create Table As Select) : snapshot rapide dans la meme base.
     - Ne sauvegarde pas les contraintes / index / triggers.
  B. SPOOL : export texte CSV depuis SQL Developer ou SQL*Plus.
     - Re-import manuel via INSERT ou SQL*Loader.
  C. expdp (Data Pump) : export complet, mais demande un DIRECTORY
     Oracle et des droits d'export -> hors perimetre ici.
*/

-- Exemple 1 : snapshot via CTAS (une table BCK_* par table du projet).

PROMPT ====================================================
PROMPT  EXEMPLE 1 : Snapshot CTAS des tables principales
PROMPT ====================================================

-- On supprime les snapshots precedents pour pouvoir rejouer.
BEGIN
    DECLARE
        TYPE t_list IS TABLE OF VARCHAR2(30);
        v_bcks t_list := t_list(
            'BCK_NOTE','BCK_INSCRIPTION_PED','BCK_INSCRIPTION_ADM',
            'BCK_MODULE','BCK_SEMESTRE','BCK_ANNEE_UNIV',
            'BCK_FILIERE','BCK_ENSEIGNANT','BCK_ETUDIANT',
            'BCK_PARAMETRE','BCK_JOURNAL'
        );
    BEGIN
        FOR i IN 1 .. v_bcks.COUNT LOOP
            BEGIN
                EXECUTE IMMEDIATE 'DROP TABLE ' || v_bcks(i)
                                   || ' CASCADE CONSTRAINTS';
            EXCEPTION
                WHEN OTHERS THEN
                    IF SQLCODE != -942 THEN RAISE; END IF;
            END;
        END LOOP;
    END;
END;
/

-- Creation des snapshots (donnees seulement, pas les contraintes)
CREATE TABLE BCK_ETUDIANT         AS SELECT * FROM ETUDIANT;
CREATE TABLE BCK_ENSEIGNANT       AS SELECT * FROM ENSEIGNANT;
CREATE TABLE BCK_FILIERE          AS SELECT * FROM FILIERE;
CREATE TABLE BCK_ANNEE_UNIV       AS SELECT * FROM ANNEE_UNIV;
CREATE TABLE BCK_SEMESTRE         AS SELECT * FROM SEMESTRE;
CREATE TABLE BCK_MODULE           AS SELECT * FROM MODULE;
CREATE TABLE BCK_INSCRIPTION_ADM  AS SELECT * FROM INSCRIPTION_ADM;
CREATE TABLE BCK_INSCRIPTION_PED  AS SELECT * FROM INSCRIPTION_PED;
CREATE TABLE BCK_NOTE             AS SELECT * FROM NOTE;
CREATE TABLE BCK_PARAMETRE        AS SELECT * FROM PARAMETRE;
-- JOURNAL volontairement ignore (peut etre enorme).

-- Comptage des lignes sauvegardees (ORDER BY 1 car UNION ALL)
SELECT 'BCK_ETUDIANT'         AS snapshot, COUNT(*) AS nb FROM BCK_ETUDIANT
UNION ALL SELECT 'BCK_ENSEIGNANT',       COUNT(*) FROM BCK_ENSEIGNANT
UNION ALL SELECT 'BCK_FILIERE',          COUNT(*) FROM BCK_FILIERE
UNION ALL SELECT 'BCK_ANNEE_UNIV',       COUNT(*) FROM BCK_ANNEE_UNIV
UNION ALL SELECT 'BCK_SEMESTRE',         COUNT(*) FROM BCK_SEMESTRE
UNION ALL SELECT 'BCK_MODULE',           COUNT(*) FROM BCK_MODULE
UNION ALL SELECT 'BCK_INSCRIPTION_ADM',  COUNT(*) FROM BCK_INSCRIPTION_ADM
UNION ALL SELECT 'BCK_INSCRIPTION_PED',  COUNT(*) FROM BCK_INSCRIPTION_PED
UNION ALL SELECT 'BCK_NOTE',             COUNT(*) FROM BCK_NOTE
UNION ALL SELECT 'BCK_PARAMETRE',        COUNT(*) FROM BCK_PARAMETRE
ORDER BY 1;

/*
Exemple de restauration applicative :

    INSERT INTO ETUDIANT
    SELECT * FROM BCK_ETUDIANT WHERE cne = 'E001'
    AND NOT EXISTS (SELECT 1 FROM ETUDIANT WHERE cne = 'E001');
    COMMIT;
*/

-- Exemple 2 : export CSV via SPOOL (bloc commente, a activer au besoin).
-- Le fichier est cree dans le repertoire courant de la session SQL*Plus.

/*
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SET TRIMSPOOL ON
SET LINESIZE 500

SPOOL etudiants_export.csv

SELECT cne || ';' || nom || ';' || prenom || ';' ||
       TO_CHAR(date_naissance,'YYYY-MM-DD') || ';' ||
       email || ';' || NVL(telephone,'')
  FROM ETUDIANT
 ORDER BY cne;

SPOOL OFF

-- Pour re-importer ailleurs : SQL*Loader ou script PL/SQL ligne par ligne.
*/

-- ============================================================
-- PARTIE C : VERIFICATION FINALE
-- ============================================================

DECLARE
    v_nb_plans    NUMBER;
    v_nb_bcks     NUMBER;
BEGIN
    SELECT COUNT(DISTINCT statement_id) INTO v_nb_plans
      FROM plan_table
     WHERE statement_id IN ('Q1_RELEVE','Q1_FULL','Q2_MOYENNES');

    SELECT COUNT(*) INTO v_nb_bcks
      FROM user_tables
     WHERE table_name LIKE 'BCK\_%' ESCAPE '\';

    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  SCRIPT 07 - OPTIMISATION & REPRISE');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  Plans d''execution analyses : ' || v_nb_plans || ' / 3');
    DBMS_OUTPUT.PUT_LINE('  Tables snapshot BCK_*       : ' || v_nb_bcks);
    DBMS_OUTPUT.PUT_LINE('  Partie B (theorie + CTAS + SPOOL) : documentee');
    DBMS_OUTPUT.PUT_LINE('====================================================');
END;
/

-- FIN DU SCRIPT 07 ------------------------------------------------------------

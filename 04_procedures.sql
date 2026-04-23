-- Script 04 : package metier PKG_SCOLARITE (procedures + fonctions).
-- Pre-requis : scripts 01, 02, 03 executes.
-- Rejouable : utilise CREATE OR REPLACE PACKAGE.

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET DEFINE OFF;

-- ============================================================
-- PARTIE A : SPECIFICATION DU PACKAGE
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_SCOLARITE AS
    -- Codes d'erreur metier (plage -20000..-20999 pour RAISE_APPLICATION_ERROR)
    C_ERR_ETUDIANT_INCONNU      CONSTANT NUMBER := -20001;
    C_ERR_FILIERE_INCONNUE      CONSTANT NUMBER := -20002;
    C_ERR_ANNEE_INCONNUE        CONSTANT NUMBER := -20003;
    C_ERR_MODULE_INCONNU        CONSTANT NUMBER := -20004;
    C_ERR_DEJA_INSCRIT_ADM      CONSTANT NUMBER := -20010;
    C_ERR_DEJA_INSCRIT_PED      CONSTANT NUMBER := -20011;
    C_ERR_INSC_ADM_INTROUVABLE  CONSTANT NUMBER := -20020;
    C_ERR_INSC_ADM_INACTIVE     CONSTANT NUMBER := -20021;
    C_ERR_INSC_PED_INTROUVABLE  CONSTANT NUMBER := -20022;
    C_ERR_NOTE_INVALIDE         CONSTANT NUMBER := -20030;
    C_ERR_PARAM_INTROUVABLE     CONSTANT NUMBER := -20040;

    -- Inscrit un etudiant pour une annee et une filiere donnees.
    -- Echoue si l'etudiant est deja inscrit pour cette annee.
    PROCEDURE PROC_INSCRIRE_ETUDIANT (
        p_cne           IN VARCHAR2,
        p_code_filiere  IN VARCHAR2,
        p_annee_libelle IN VARCHAR2,
        p_annee_etude   IN NUMBER DEFAULT 1
    );

    -- Inscrit un etudiant a un module. Necessite une inscription
    -- administrative active pour l'annee.
    PROCEDURE PROC_INSCRIRE_PEDAGOGIQUE (
        p_cne           IN VARCHAR2,
        p_annee_libelle IN VARCHAR2,
        p_code_module   IN VARCHAR2
    );

    -- Saisit ou met a jour la note d'un etudiant pour un module.
    -- Calcule la note finale via les parametres POIDS_EXAMEN / POIDS_CC.
    PROCEDURE PROC_SAISIR_NOTE (
        p_cne           IN VARCHAR2,
        p_annee_libelle IN VARCHAR2,
        p_code_module   IN VARCHAR2,
        p_note_examen   IN NUMBER,
        p_note_cc       IN NUMBER,
        p_session_type  IN VARCHAR2 DEFAULT 'NORMALE',
        p_valider       IN NUMBER   DEFAULT 1
    );

    -- Moyenne ponderee d'un semestre. NULL si aucune note.
    FUNCTION FUNC_MOYENNE_SEMESTRE (
        p_cne           IN VARCHAR2,
        p_annee_libelle IN VARCHAR2,
        p_numero_sem    IN NUMBER
    ) RETURN NUMBER;

    -- Etat d'une annee : VALIDE / NON VALIDE / INCOMPLET.
    FUNCTION FUNC_VALIDER_ANNEE (
        p_cne           IN VARCHAR2,
        p_annee_libelle IN VARCHAR2
    ) RETURN VARCHAR2;

END PKG_SCOLARITE;
/

-- ============================================================
-- PARTIE B : CORPS DU PACKAGE
-- ============================================================

CREATE OR REPLACE PACKAGE BODY PKG_SCOLARITE AS

    -- Helper : lit un parametre numerique depuis la table PARAMETRE.
    FUNCTION f_get_param_num (p_code IN VARCHAR2) RETURN NUMBER IS
        v_val NUMBER;
    BEGIN
        SELECT TO_NUMBER(valeur) INTO v_val
          FROM PARAMETRE
         WHERE code_param = p_code;
        RETURN v_val;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(C_ERR_PARAM_INTROUVABLE,
                'Parametre introuvable : ' || p_code);
    END;

    -- ========== PROC_INSCRIRE_ETUDIANT ==========
    PROCEDURE PROC_INSCRIRE_ETUDIANT (
        p_cne           IN VARCHAR2,
        p_code_filiere  IN VARCHAR2,
        p_annee_libelle IN VARCHAR2,
        p_annee_etude   IN NUMBER DEFAULT 1
    ) IS
        v_cne           ETUDIANT.cne%TYPE;
        v_id_filiere    FILIERE.id_filiere%TYPE;
        v_id_annee      ANNEE_UNIV.id_annee%TYPE;
        v_nb_existant   NUMBER;
    BEGIN
        -- Resolution des cles naturelles (etudiant, filiere, annee).
        BEGIN
            SELECT cne INTO v_cne FROM ETUDIANT WHERE cne = p_cne;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(C_ERR_ETUDIANT_INCONNU,
                    'Etudiant inconnu : ' || p_cne);
        END;

        BEGIN
            SELECT id_filiere INTO v_id_filiere
              FROM FILIERE WHERE code_filiere = p_code_filiere;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(C_ERR_FILIERE_INCONNUE,
                    'Filiere inconnue : ' || p_code_filiere);
        END;

        BEGIN
            SELECT id_annee INTO v_id_annee
              FROM ANNEE_UNIV WHERE libelle = p_annee_libelle;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(C_ERR_ANNEE_INCONNUE,
                    'Annee universitaire inconnue : ' || p_annee_libelle);
        END;

        -- Verification de l'unicite (un etudiant = une inscription par annee).
        SELECT COUNT(*) INTO v_nb_existant
          FROM INSCRIPTION_ADM
         WHERE cne = p_cne AND id_annee = v_id_annee;

        IF v_nb_existant > 0 THEN
            RAISE_APPLICATION_ERROR(C_ERR_DEJA_INSCRIT_ADM,
                'Etudiant ' || p_cne || ' deja inscrit pour ' || p_annee_libelle);
        END IF;

        INSERT INTO INSCRIPTION_ADM
            (date_inscription, statut, annee_etude, actif,
             cne, id_filiere, id_annee)
        VALUES
            (SYSDATE, 'INSCRIT', p_annee_etude, 1,
             p_cne, v_id_filiere, v_id_annee);

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('[OK] Inscription admin : ' || p_cne
            || ' -> ' || p_code_filiere || ' / ' || p_annee_libelle
            || ' (annee ' || p_annee_etude || ')');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END PROC_INSCRIRE_ETUDIANT;

    -- ========== PROC_INSCRIRE_PEDAGOGIQUE ==========
    PROCEDURE PROC_INSCRIRE_PEDAGOGIQUE (
        p_cne           IN VARCHAR2,
        p_annee_libelle IN VARCHAR2,
        p_code_module   IN VARCHAR2
    ) IS
        v_id_insc_adm   INSCRIPTION_ADM.id_insc_adm%TYPE;
        v_actif         INSCRIPTION_ADM.actif%TYPE;
        v_id_module     MODULE.id_module%TYPE;
        v_nb_existant   NUMBER;
    BEGIN
        -- On cherche l'inscription admin de l'etudiant pour cette annee.
        BEGIN
            SELECT ia.id_insc_adm, ia.actif
              INTO v_id_insc_adm, v_actif
              FROM INSCRIPTION_ADM ia
              JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
             WHERE ia.cne = p_cne
               AND a.libelle = p_annee_libelle;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(C_ERR_INSC_ADM_INTROUVABLE,
                    'Aucune inscription administrative pour '
                    || p_cne || ' en ' || p_annee_libelle);
        END;

        IF v_actif <> 1 THEN
            RAISE_APPLICATION_ERROR(C_ERR_INSC_ADM_INACTIVE,
                'Inscription administrative inactive pour '
                || p_cne || ' en ' || p_annee_libelle);
        END IF;

        BEGIN
            SELECT id_module INTO v_id_module
              FROM MODULE WHERE code_module = p_code_module;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(C_ERR_MODULE_INCONNU,
                    'Module inconnu : ' || p_code_module);
        END;

        -- Anti-doublon sur (inscription admin, module).
        SELECT COUNT(*) INTO v_nb_existant
          FROM INSCRIPTION_PED
         WHERE id_insc_adm = v_id_insc_adm
           AND id_module   = v_id_module;

        IF v_nb_existant > 0 THEN
            RAISE_APPLICATION_ERROR(C_ERR_DEJA_INSCRIT_PED,
                'Etudiant ' || p_cne || ' deja inscrit au module '
                || p_code_module || ' en ' || p_annee_libelle);
        END IF;

        INSERT INTO INSCRIPTION_PED
            (date_inscription, statut, id_insc_adm, id_module)
        VALUES
            (SYSDATE, 'ACTIF', v_id_insc_adm, v_id_module);

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('[OK] Inscription ped : ' || p_cne
            || ' -> ' || p_code_module || ' (' || p_annee_libelle || ')');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END PROC_INSCRIRE_PEDAGOGIQUE;

    -- ========== PROC_SAISIR_NOTE ==========
    PROCEDURE PROC_SAISIR_NOTE (
        p_cne           IN VARCHAR2,
        p_annee_libelle IN VARCHAR2,
        p_code_module   IN VARCHAR2,
        p_note_examen   IN NUMBER,
        p_note_cc       IN NUMBER,
        p_session_type  IN VARCHAR2 DEFAULT 'NORMALE',
        p_valider       IN NUMBER   DEFAULT 1
    ) IS
        v_id_insc_ped   INSCRIPTION_PED.id_insc_ped%TYPE;
        v_poids_examen  NUMBER;
        v_poids_cc      NUMBER;
        v_note_finale   NUMBER;
        v_nb_existant   NUMBER;
    BEGIN
        -- Validation des notes avant de passer aux contraintes CHECK.
        IF p_note_examen IS NULL OR p_note_examen < 0 OR p_note_examen > 20 THEN
            RAISE_APPLICATION_ERROR(C_ERR_NOTE_INVALIDE,
                'Note d examen invalide : ' || p_note_examen || ' (attendu 0..20)');
        END IF;
        IF p_note_cc IS NULL OR p_note_cc < 0 OR p_note_cc > 20 THEN
            RAISE_APPLICATION_ERROR(C_ERR_NOTE_INVALIDE,
                'Note de controle continu invalide : ' || p_note_cc || ' (attendu 0..20)');
        END IF;
        IF p_session_type NOT IN ('NORMALE','RATTRAPAGE') THEN
            RAISE_APPLICATION_ERROR(C_ERR_NOTE_INVALIDE,
                'Session invalide : ' || p_session_type
                || ' (attendu NORMALE ou RATTRAPAGE)');
        END IF;

        -- Resolution de l'inscription pedagogique.
        BEGIN
            SELECT ip.id_insc_ped INTO v_id_insc_ped
              FROM INSCRIPTION_PED  ip
              JOIN INSCRIPTION_ADM  ia ON ia.id_insc_adm = ip.id_insc_adm
              JOIN ANNEE_UNIV       a  ON a.id_annee     = ia.id_annee
              JOIN MODULE           m  ON m.id_module    = ip.id_module
             WHERE ia.cne        = p_cne
               AND a.libelle     = p_annee_libelle
               AND m.code_module = p_code_module;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(C_ERR_INSC_PED_INTROUVABLE,
                    'Aucune inscription pedagogique pour '
                    || p_cne || ' au module ' || p_code_module
                    || ' en ' || p_annee_libelle);
        END;

        -- Calcul de la note finale d'apres les parametres du systeme.
        v_poids_examen := f_get_param_num('POIDS_EXAMEN');
        v_poids_cc     := f_get_param_num('POIDS_CC');

        v_note_finale := ROUND(
            p_note_examen * v_poids_examen + p_note_cc * v_poids_cc, 2);

        -- Si la note existe deja on met a jour, sinon on insere.
        SELECT COUNT(*) INTO v_nb_existant
          FROM NOTE WHERE id_insc_ped = v_id_insc_ped;

        IF v_nb_existant > 0 THEN
            UPDATE NOTE
               SET note_examen  = p_note_examen,
                   note_cc      = p_note_cc,
                   note_finale  = v_note_finale,
                   session_type = p_session_type,
                   date_saisie  = SYSDATE,
                   validee      = p_valider
             WHERE id_insc_ped  = v_id_insc_ped;

            DBMS_OUTPUT.PUT_LINE('[OK] Note mise a jour : ' || p_cne
                || ' / ' || p_code_module
                || ' -> finale = ' || v_note_finale);
        ELSE
            INSERT INTO NOTE
                (note_examen, note_cc, note_finale, session_type,
                 date_saisie, validee, id_insc_ped)
            VALUES
                (p_note_examen, p_note_cc, v_note_finale, p_session_type,
                 SYSDATE, p_valider, v_id_insc_ped);

            DBMS_OUTPUT.PUT_LINE('[OK] Note inseree : ' || p_cne
                || ' / ' || p_code_module
                || ' -> finale = ' || v_note_finale);
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END PROC_SAISIR_NOTE;

    -- ========== FUNC_MOYENNE_SEMESTRE ==========
    FUNCTION FUNC_MOYENNE_SEMESTRE (
        p_cne           IN VARCHAR2,
        p_annee_libelle IN VARCHAR2,
        p_numero_sem    IN NUMBER
    ) RETURN NUMBER IS
        v_moyenne NUMBER;
    BEGIN
        SELECT ROUND(
                   SUM(n.note_finale * m.coefficient)
                 / NULLIF(SUM(m.coefficient), 0), 2)
          INTO v_moyenne
          FROM INSCRIPTION_ADM   ia
          JOIN ANNEE_UNIV        a  ON a.id_annee      = ia.id_annee
          JOIN INSCRIPTION_PED   ip ON ip.id_insc_adm  = ia.id_insc_adm
          JOIN MODULE            m  ON m.id_module     = ip.id_module
          JOIN SEMESTRE          s  ON s.id_semestre   = m.id_semestre
          JOIN NOTE              n  ON n.id_insc_ped   = ip.id_insc_ped
         WHERE ia.cne      = p_cne
           AND a.libelle   = p_annee_libelle
           AND s.numero    = p_numero_sem;

        RETURN v_moyenne;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END FUNC_MOYENNE_SEMESTRE;

    -- ========== FUNC_VALIDER_ANNEE ==========
    -- S'appuie sur la vue V_VALIDATION_ANNEE pour ne pas dupliquer la logique.
    FUNCTION FUNC_VALIDER_ANNEE (
        p_cne           IN VARCHAR2,
        p_annee_libelle IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_etat VARCHAR2(20);
    BEGIN
        SELECT etat_annee INTO v_etat
          FROM V_VALIDATION_ANNEE
         WHERE cne    = p_cne
           AND annee  = p_annee_libelle;

        RETURN v_etat;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'INCOMPLET';
    END FUNC_VALIDER_ANNEE;

END PKG_SCOLARITE;
/

-- ============================================================
-- PARTIE C : VERIFICATION DE LA COMPILATION
-- ============================================================
DECLARE
    v_status_spec user_objects.status%TYPE;
    v_status_body user_objects.status%TYPE;
BEGIN
    SELECT status INTO v_status_spec
      FROM user_objects
     WHERE object_name = 'PKG_SCOLARITE' AND object_type = 'PACKAGE';

    SELECT status INTO v_status_body
      FROM user_objects
     WHERE object_name = 'PKG_SCOLARITE' AND object_type = 'PACKAGE BODY';

    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  PACKAGE PKG_SCOLARITE');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  Specification : ' || v_status_spec);
    DBMS_OUTPUT.PUT_LINE('  Body          : ' || v_status_body);
    DBMS_OUTPUT.PUT_LINE('====================================================');
END;
/

-- ============================================================
-- PARTIE D : TESTS FONCTIONNELS
-- Utilise un etudiant temporaire T999 que l'on cree et supprime
-- autour des tests pour pouvoir rejouer le script.
-- ============================================================

PROMPT ====================================================
PROMPT  PREPARATION : nettoyage prealable + creation T999
PROMPT ====================================================

DELETE FROM NOTE            WHERE id_insc_ped IN (
    SELECT id_insc_ped FROM INSCRIPTION_PED WHERE id_insc_adm IN (
        SELECT id_insc_adm FROM INSCRIPTION_ADM WHERE cne = 'T999'));
DELETE FROM INSCRIPTION_PED WHERE id_insc_adm IN (
    SELECT id_insc_adm FROM INSCRIPTION_ADM WHERE cne = 'T999');
DELETE FROM INSCRIPTION_ADM WHERE cne = 'T999';
DELETE FROM ETUDIANT        WHERE cne = 'T999';
COMMIT;

INSERT INTO ETUDIANT (cne, nom, prenom, date_naissance, sexe, email)
VALUES ('T999', 'TEST', 'User', DATE '2000-01-01', 'M', 'test.user@etu.ma');
COMMIT;

-- Test 1 : inscription administrative (cas nominal)
PROMPT ====================================================
PROMPT  TEST 1 : PROC_INSCRIRE_ETUDIANT (T999 / SMI / 2025-2026)
PROMPT ====================================================
BEGIN
    PKG_SCOLARITE.PROC_INSCRIRE_ETUDIANT('T999', 'SMI', '2025-2026', 1);
END;
/

-- Test 2 : inscription pedagogique a deux modules
PROMPT ====================================================
PROMPT  TEST 2 : PROC_INSCRIRE_PEDAGOGIQUE (T999 -> SMI1001, SMI1002)
PROMPT ====================================================
BEGIN
    PKG_SCOLARITE.PROC_INSCRIRE_PEDAGOGIQUE('T999', '2025-2026', 'SMI1001');
    PKG_SCOLARITE.PROC_INSCRIRE_PEDAGOGIQUE('T999', '2025-2026', 'SMI1002');
END;
/

-- Test 3 : saisie de note (insertion puis mise a jour)
PROMPT ====================================================
PROMPT  TEST 3 : PROC_SAISIR_NOTE
PROMPT          Calcul attendu : 0.6 * examen + 0.4 * cc
PROMPT ====================================================

-- Saisie initiale
BEGIN
    PKG_SCOLARITE.PROC_SAISIR_NOTE('T999','2025-2026','SMI1001', 12, 14);
    PKG_SCOLARITE.PROC_SAISIR_NOTE('T999','2025-2026','SMI1002',  8, 10);
END;
/

-- Re-saisie : met a jour la premiere note.
BEGIN
    PKG_SCOLARITE.PROC_SAISIR_NOTE('T999','2025-2026','SMI1001', 16, 18);
END;
/

-- Verification
SELECT m.code_module,
       n.note_examen, n.note_cc, n.note_finale,
       n.session_type, n.validee
  FROM NOTE           n
  JOIN INSCRIPTION_PED ip ON ip.id_insc_ped = n.id_insc_ped
  JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
  JOIN MODULE          m  ON m.id_module    = ip.id_module
 WHERE ia.cne = 'T999'
 ORDER BY m.code_module;

-- Test 4 : moyenne semestre
PROMPT ====================================================
PROMPT  TEST 4 : FUNC_MOYENNE_SEMESTRE
PROMPT ====================================================

SELECT 'T999 S1 2025-2026' AS cible,
       PKG_SCOLARITE.FUNC_MOYENNE_SEMESTRE('T999','2025-2026',1) AS moyenne
  FROM DUAL
UNION ALL
SELECT 'E001 S1 2024-2025',
       PKG_SCOLARITE.FUNC_MOYENNE_SEMESTRE('E001','2024-2025',1)
  FROM DUAL
UNION ALL
SELECT 'E001 S2 2024-2025',
       PKG_SCOLARITE.FUNC_MOYENNE_SEMESTRE('E001','2024-2025',2)
  FROM DUAL;

-- Test 5 : validation d'une annee
PROMPT ====================================================
PROMPT  TEST 5 : FUNC_VALIDER_ANNEE
PROMPT ====================================================

SELECT 'E001 2024-2025' AS cible,
       PKG_SCOLARITE.FUNC_VALIDER_ANNEE('E001','2024-2025') AS etat
  FROM DUAL
UNION ALL
SELECT 'E002 2025-2026',
       PKG_SCOLARITE.FUNC_VALIDER_ANNEE('E002','2025-2026')
  FROM DUAL
UNION ALL
SELECT 'T999 2025-2026',
       PKG_SCOLARITE.FUNC_VALIDER_ANNEE('T999','2025-2026')
  FROM DUAL;

-- Test 6 : cas d'erreur (etudiant inconnu)
PROMPT ====================================================
PROMPT  TEST 6 : erreur attendue (etudiant inconnu)
PROMPT ====================================================
BEGIN
    PKG_SCOLARITE.PROC_INSCRIRE_ETUDIANT('Z999','SMI','2025-2026');
    DBMS_OUTPUT.PUT_LINE('[KO] Aucune erreur levee (probleme)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Erreur capturee : ' || SQLERRM);
END;
/

-- Test 7 : cas d'erreur (deja inscrit pour cette annee)
PROMPT ====================================================
PROMPT  TEST 7 : erreur attendue (T999 deja inscrit pour 2025-2026)
PROMPT ====================================================
BEGIN
    PKG_SCOLARITE.PROC_INSCRIRE_ETUDIANT('T999','SMI','2025-2026');
    DBMS_OUTPUT.PUT_LINE('[KO] Aucune erreur levee (probleme)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Erreur capturee : ' || SQLERRM);
END;
/

-- Test 8 : cas d'erreur (note hors de 0..20)
PROMPT ====================================================
PROMPT  TEST 8 : erreur attendue (note invalide)
PROMPT ====================================================
BEGIN
    PKG_SCOLARITE.PROC_SAISIR_NOTE('T999','2025-2026','SMI1001', 25, 10);
    DBMS_OUTPUT.PUT_LINE('[KO] Aucune erreur levee (probleme)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Erreur capturee : ' || SQLERRM);
END;
/

-- Nettoyage final (on efface T999)
PROMPT ====================================================
PROMPT  NETTOYAGE FINAL : suppression T999
PROMPT ====================================================

DELETE FROM NOTE            WHERE id_insc_ped IN (
    SELECT id_insc_ped FROM INSCRIPTION_PED WHERE id_insc_adm IN (
        SELECT id_insc_adm FROM INSCRIPTION_ADM WHERE cne = 'T999'));
DELETE FROM INSCRIPTION_PED WHERE id_insc_adm IN (
    SELECT id_insc_adm FROM INSCRIPTION_ADM WHERE cne = 'T999');
DELETE FROM INSCRIPTION_ADM WHERE cne = 'T999';
DELETE FROM ETUDIANT        WHERE cne = 'T999';
COMMIT;

PROMPT ====================================================
PROMPT  Script 04 termine avec succes.
PROMPT ====================================================

-- FIN DU SCRIPT 04 ------------------------------------------------------------

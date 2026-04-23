-- Script 05 : journalisation automatique via triggers AFTER
-- INSERT/UPDATE/DELETE sur les tables sensibles.
-- Pre-requis : scripts 01 a 04 executes.
-- Rejouable : utilise CREATE OR REPLACE TRIGGER.

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET DEFINE OFF;

-- ============================================================
-- PARTIE A : PREPARATION
-- Nettoyage de l'etudiant de test T888 avant de creer les
-- triggers : on evite d'avoir des lignes de DELETE dans JOURNAL.
-- ============================================================

DELETE FROM NOTE            WHERE id_insc_ped IN (
    SELECT id_insc_ped FROM INSCRIPTION_PED WHERE id_insc_adm IN (
        SELECT id_insc_adm FROM INSCRIPTION_ADM WHERE cne = 'T888'));
DELETE FROM INSCRIPTION_PED WHERE id_insc_adm IN (
    SELECT id_insc_adm FROM INSCRIPTION_ADM WHERE cne = 'T888');
DELETE FROM INSCRIPTION_ADM WHERE cne = 'T888';
DELETE FROM ETUDIANT        WHERE cne = 'T888';
COMMIT;

-- ============================================================
-- PARTIE B : TRIGGERS DE JOURNALISATION
-- Un trigger par table, qui gere a la fois INSERT, UPDATE et DELETE
-- via les predicats INSERTING / UPDATING / DELETING.
-- Format : "col1=val1|col2=val2|..." (compact et lisible).
-- Pas de PRAGMA AUTONOMOUS_TRANSACTION : l'audit suit le sort de
-- la transaction metier (rollback annule aussi l'audit).
-- ============================================================

-- Trigger 1 : ETUDIANT

CREATE OR REPLACE TRIGGER TRG_AUD_ETUDIANT
AFTER INSERT OR UPDATE OR DELETE ON ETUDIANT
FOR EACH ROW
DECLARE
    v_type VARCHAR2(10);
    v_cle  VARCHAR2(100);
    v_old  VARCHAR2(4000) := NULL;
    v_new  VARCHAR2(4000) := NULL;
BEGIN
    IF INSERTING THEN v_type := 'INSERT';
    ELSIF UPDATING THEN v_type := 'UPDATE';
    ELSE v_type := 'DELETE';
    END IF;

    IF DELETING THEN
        v_cle := 'CNE=' || :OLD.cne;
    ELSE
        v_cle := 'CNE=' || :NEW.cne;
    END IF;

    IF UPDATING OR DELETING THEN
        v_old := 'cne='         || :OLD.cne
              || '|nom='        || :OLD.nom
              || '|prenom='     || :OLD.prenom
              || '|date_naiss=' || NVL(TO_CHAR(:OLD.date_naissance,'YYYY-MM-DD'),'NULL')
              || '|sexe='       || NVL(:OLD.sexe,'NULL')
              || '|email='      || :OLD.email
              || '|telephone='  || NVL(:OLD.telephone,'NULL')
              || '|actif='      || :OLD.actif;
    END IF;

    IF INSERTING OR UPDATING THEN
        v_new := 'cne='         || :NEW.cne
              || '|nom='        || :NEW.nom
              || '|prenom='     || :NEW.prenom
              || '|date_naiss=' || NVL(TO_CHAR(:NEW.date_naissance,'YYYY-MM-DD'),'NULL')
              || '|sexe='       || NVL(:NEW.sexe,'NULL')
              || '|email='      || :NEW.email
              || '|telephone='  || NVL(:NEW.telephone,'NULL')
              || '|actif='      || :NEW.actif;
    END IF;

    INSERT INTO JOURNAL (nom_table, type_operation, cle_enregistrement,
                         ancienne_valeur, nouvelle_valeur)
    VALUES ('ETUDIANT', v_type, v_cle, v_old, v_new);
END;
/

-- Trigger 2 : INSCRIPTION_ADM

CREATE OR REPLACE TRIGGER TRG_AUD_INSC_ADM
AFTER INSERT OR UPDATE OR DELETE ON INSCRIPTION_ADM
FOR EACH ROW
DECLARE
    v_type VARCHAR2(10);
    v_cle  VARCHAR2(100);
    v_old  VARCHAR2(4000) := NULL;
    v_new  VARCHAR2(4000) := NULL;
BEGIN
    IF INSERTING THEN v_type := 'INSERT';
    ELSIF UPDATING THEN v_type := 'UPDATE';
    ELSE v_type := 'DELETE';
    END IF;

    IF DELETING THEN
        v_cle := 'ID_INSC_ADM=' || :OLD.id_insc_adm;
    ELSE
        v_cle := 'ID_INSC_ADM=' || :NEW.id_insc_adm;
    END IF;

    IF UPDATING OR DELETING THEN
        v_old := 'id_insc_adm='  || :OLD.id_insc_adm
              || '|cne='         || :OLD.cne
              || '|id_filiere='  || :OLD.id_filiere
              || '|id_annee='    || :OLD.id_annee
              || '|annee_etude=' || :OLD.annee_etude
              || '|statut='      || :OLD.statut
              || '|actif='       || :OLD.actif
              || '|date_insc='   || NVL(TO_CHAR(:OLD.date_inscription,'YYYY-MM-DD'),'NULL');
    END IF;

    IF INSERTING OR UPDATING THEN
        v_new := 'id_insc_adm='  || :NEW.id_insc_adm
              || '|cne='         || :NEW.cne
              || '|id_filiere='  || :NEW.id_filiere
              || '|id_annee='    || :NEW.id_annee
              || '|annee_etude=' || :NEW.annee_etude
              || '|statut='      || :NEW.statut
              || '|actif='       || :NEW.actif
              || '|date_insc='   || NVL(TO_CHAR(:NEW.date_inscription,'YYYY-MM-DD'),'NULL');
    END IF;

    INSERT INTO JOURNAL (nom_table, type_operation, cle_enregistrement,
                         ancienne_valeur, nouvelle_valeur)
    VALUES ('INSCRIPTION_ADM', v_type, v_cle, v_old, v_new);
END;
/

-- Trigger 3 : INSCRIPTION_PED

CREATE OR REPLACE TRIGGER TRG_AUD_INSC_PED
AFTER INSERT OR UPDATE OR DELETE ON INSCRIPTION_PED
FOR EACH ROW
DECLARE
    v_type VARCHAR2(10);
    v_cle  VARCHAR2(100);
    v_old  VARCHAR2(4000) := NULL;
    v_new  VARCHAR2(4000) := NULL;
BEGIN
    IF INSERTING THEN v_type := 'INSERT';
    ELSIF UPDATING THEN v_type := 'UPDATE';
    ELSE v_type := 'DELETE';
    END IF;

    IF DELETING THEN
        v_cle := 'ID_INSC_PED=' || :OLD.id_insc_ped;
    ELSE
        v_cle := 'ID_INSC_PED=' || :NEW.id_insc_ped;
    END IF;

    IF UPDATING OR DELETING THEN
        v_old := 'id_insc_ped=' || :OLD.id_insc_ped
              || '|id_insc_adm='|| :OLD.id_insc_adm
              || '|id_module='  || :OLD.id_module
              || '|statut='     || :OLD.statut
              || '|date_insc='  || NVL(TO_CHAR(:OLD.date_inscription,'YYYY-MM-DD'),'NULL');
    END IF;

    IF INSERTING OR UPDATING THEN
        v_new := 'id_insc_ped=' || :NEW.id_insc_ped
              || '|id_insc_adm='|| :NEW.id_insc_adm
              || '|id_module='  || :NEW.id_module
              || '|statut='     || :NEW.statut
              || '|date_insc='  || NVL(TO_CHAR(:NEW.date_inscription,'YYYY-MM-DD'),'NULL');
    END IF;

    INSERT INTO JOURNAL (nom_table, type_operation, cle_enregistrement,
                         ancienne_valeur, nouvelle_valeur)
    VALUES ('INSCRIPTION_PED', v_type, v_cle, v_old, v_new);
END;
/

-- Trigger 4 : NOTE

CREATE OR REPLACE TRIGGER TRG_AUD_NOTE
AFTER INSERT OR UPDATE OR DELETE ON NOTE
FOR EACH ROW
DECLARE
    v_type VARCHAR2(10);
    v_cle  VARCHAR2(100);
    v_old  VARCHAR2(4000) := NULL;
    v_new  VARCHAR2(4000) := NULL;
BEGIN
    IF INSERTING THEN v_type := 'INSERT';
    ELSIF UPDATING THEN v_type := 'UPDATE';
    ELSE v_type := 'DELETE';
    END IF;

    IF DELETING THEN
        v_cle := 'ID_NOTE=' || :OLD.id_note;
    ELSE
        v_cle := 'ID_NOTE=' || :NEW.id_note;
    END IF;

    IF UPDATING OR DELETING THEN
        v_old := 'id_note='     || :OLD.id_note
              || '|id_insc_ped='|| :OLD.id_insc_ped
              || '|examen='     || NVL(TO_CHAR(:OLD.note_examen),'NULL')
              || '|cc='         || NVL(TO_CHAR(:OLD.note_cc),'NULL')
              || '|finale='     || NVL(TO_CHAR(:OLD.note_finale),'NULL')
              || '|session='    || :OLD.session_type
              || '|validee='    || :OLD.validee
              || '|date_saisie='|| NVL(TO_CHAR(:OLD.date_saisie,'YYYY-MM-DD HH24:MI:SS'),'NULL');
    END IF;

    IF INSERTING OR UPDATING THEN
        v_new := 'id_note='     || :NEW.id_note
              || '|id_insc_ped='|| :NEW.id_insc_ped
              || '|examen='     || NVL(TO_CHAR(:NEW.note_examen),'NULL')
              || '|cc='         || NVL(TO_CHAR(:NEW.note_cc),'NULL')
              || '|finale='     || NVL(TO_CHAR(:NEW.note_finale),'NULL')
              || '|session='    || :NEW.session_type
              || '|validee='    || :NEW.validee
              || '|date_saisie='|| NVL(TO_CHAR(:NEW.date_saisie,'YYYY-MM-DD HH24:MI:SS'),'NULL');
    END IF;

    INSERT INTO JOURNAL (nom_table, type_operation, cle_enregistrement,
                         ancienne_valeur, nouvelle_valeur)
    VALUES ('NOTE', v_type, v_cle, v_old, v_new);
END;
/

-- ============================================================
-- PARTIE C : VERIFICATION
-- ============================================================

DECLARE
    v_nb_total   NUMBER;
    v_nb_valid   NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_nb_total
      FROM user_triggers
     WHERE trigger_name IN
           ('TRG_AUD_ETUDIANT','TRG_AUD_INSC_ADM',
            'TRG_AUD_INSC_PED','TRG_AUD_NOTE');

    SELECT COUNT(*) INTO v_nb_valid
      FROM user_objects
     WHERE object_type = 'TRIGGER'
       AND status      = 'VALID'
       AND object_name IN
           ('TRG_AUD_ETUDIANT','TRG_AUD_INSC_ADM',
            'TRG_AUD_INSC_PED','TRG_AUD_NOTE');

    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  TRIGGERS DE JOURNALISATION');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  Crees  : ' || v_nb_total || ' / 4');
    DBMS_OUTPUT.PUT_LINE('  Valides: ' || v_nb_valid || ' / 4');
    DBMS_OUTPUT.PUT_LINE('====================================================');
END;
/

-- ============================================================
-- PARTIE D : TESTS
-- On cree T888, on lui fait faire un cycle complet (INSERT/UPDATE
-- /DELETE), puis on lit JOURNAL pour voir les traces.
-- ============================================================

PROMPT ====================================================
PROMPT  TEST 1 : INSERT (etudiant + inscription + note)
PROMPT ====================================================

-- Creation de l'etudiant
INSERT INTO ETUDIANT (cne, nom, prenom, date_naissance, sexe, email, telephone)
VALUES ('T888', 'AUDIT', 'Test', DATE '2001-03-15', 'M', 'audit.test@etu.ma', '0600000000');
COMMIT;

-- Inscription administrative
BEGIN
    PKG_SCOLARITE.PROC_INSCRIRE_ETUDIANT('T888', 'SMI', '2025-2026', 1);
END;
/

-- Inscription pedagogique
BEGIN
    PKG_SCOLARITE.PROC_INSCRIRE_PEDAGOGIQUE('T888', '2025-2026', 'SMI1001');
END;
/

-- Premiere saisie de note
BEGIN
    PKG_SCOLARITE.PROC_SAISIR_NOTE('T888', '2025-2026', 'SMI1001', 10, 12);
END;
/

PROMPT ====================================================
PROMPT  TEST 2 : UPDATE (modification d'une note)
PROMPT ====================================================

-- Re-saisie : UPDATE sur la note
BEGIN
    PKG_SCOLARITE.PROC_SAISIR_NOTE('T888', '2025-2026', 'SMI1001', 15, 16);
END;
/

-- Modification directe des coordonnees etudiant
UPDATE ETUDIANT
   SET telephone = '0611111111',
       adresse   = 'Adresse mise a jour'
 WHERE cne = 'T888';
COMMIT;

PROMPT ====================================================
PROMPT  TEST 3 : DELETE (suppression en cascade manuelle)
PROMPT ====================================================

-- DELETE dans l'ordre inverse des FK
DELETE FROM NOTE
 WHERE id_insc_ped IN (
       SELECT id_insc_ped FROM INSCRIPTION_PED
        WHERE id_insc_adm IN (
              SELECT id_insc_adm FROM INSCRIPTION_ADM WHERE cne = 'T888'));

DELETE FROM INSCRIPTION_PED
 WHERE id_insc_adm IN (SELECT id_insc_adm FROM INSCRIPTION_ADM WHERE cne = 'T888');

DELETE FROM INSCRIPTION_ADM WHERE cne = 'T888';
DELETE FROM ETUDIANT        WHERE cne = 'T888';
COMMIT;

-- ============================================================
-- PARTIE E : LECTURE DU JOURNAL
-- On filtre sur la derniere minute pour ne voir que les traces
-- generees par ce run (pas l'historique).
-- ============================================================

PROMPT ====================================================
PROMPT  JOURNAL : entrees de la derniere minute
PROMPT ====================================================

SELECT id_journal,
       nom_table,
       type_operation                                  AS op,
       cle_enregistrement                              AS cle,
       utilisateur                                     AS utilisateur,
       TO_CHAR(date_operation,'YYYY-MM-DD HH24:MI:SS') AS date_op
  FROM JOURNAL
 WHERE date_operation >= SYSTIMESTAMP - INTERVAL '1' MINUTE
 ORDER BY id_journal;

PROMPT ====================================================
PROMPT  JOURNAL : detail des anciennes / nouvelles valeurs
PROMPT ====================================================

SELECT id_journal,
       nom_table,
       type_operation    AS op,
       cle_enregistrement,
       DBMS_LOB.SUBSTR(ancienne_valeur, 250, 1) AS ancienne_valeur,
       DBMS_LOB.SUBSTR(nouvelle_valeur, 250, 1) AS nouvelle_valeur
  FROM JOURNAL
 WHERE date_operation >= SYSTIMESTAMP - INTERVAL '1' MINUTE
 ORDER BY id_journal;

PROMPT ====================================================
PROMPT  JOURNAL : comptage par table et par operation (derniere minute)
PROMPT ====================================================

SELECT nom_table, type_operation, COUNT(*) AS nb
  FROM JOURNAL
 WHERE date_operation >= SYSTIMESTAMP - INTERVAL '1' MINUTE
 GROUP BY nom_table, type_operation
 ORDER BY nom_table, type_operation;

-- ============================================================
-- PARTIE F : CONFIRMATION FINALE
-- ============================================================

DECLARE
    v_nb_trigger NUMBER;
    v_nb_audits  NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_nb_trigger
      FROM user_triggers
     WHERE trigger_name LIKE 'TRG_AUD_%';

    SELECT COUNT(*) INTO v_nb_audits
      FROM JOURNAL
     WHERE date_operation >= SYSTIMESTAMP - INTERVAL '1' MINUTE;

    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  SCRIPT 05 TERMINE AVEC SUCCES');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  Triggers de journalisation crees : ' || v_nb_trigger || ' / 4');
    DBMS_OUTPUT.PUT_LINE('  Entrees JOURNAL generees par tests : ' || v_nb_audits);
    DBMS_OUTPUT.PUT_LINE('====================================================');
END;
/

-- FIN DU SCRIPT 05 ------------------------------------------------------------

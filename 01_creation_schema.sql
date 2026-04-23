-- Script 01 : creation du schema (tables, sequences, triggers, index, parametres).
-- Oracle - SQL Developer. Rejouable : le script nettoie avant de recreer.

SET SERVEROUTPUT ON;
SET FEEDBACK ON;

-- ============================================================
-- SECTION 1 : SUPPRESSION DES OBJETS EXISTANTS
-- Oracle n'a pas de "DROP IF EXISTS" : on capte ORA-00942 /
-- ORA-02289 pour ignorer les objets qui n'existent pas.
-- ============================================================

-- 1.1 Tables : ordre fixe, du plus dependant vers le moins dependant.
BEGIN
    DECLARE
        TYPE t_list IS TABLE OF VARCHAR2(30);
        v_tables t_list := t_list(
            'NOTE',
            'INSCRIPTION_PED',
            'INSCRIPTION_ADM',
            'MODULE',
            'SEMESTRE',
            'ANNEE_UNIV',
            'FILIERE',
            'ENSEIGNANT',
            'ETUDIANT',
            'PARAMETRE',
            'JOURNAL'
        );
    BEGIN
        FOR i IN 1 .. v_tables.COUNT LOOP
            BEGIN
                EXECUTE IMMEDIATE
                    'DROP TABLE ' || v_tables(i) || ' CASCADE CONSTRAINTS';
                DBMS_OUTPUT.PUT_LINE('Table supprimee : ' || v_tables(i));
            EXCEPTION
                WHEN OTHERS THEN
                    IF SQLCODE != -942 THEN RAISE; END IF;
            END;
        END LOOP;
    END;
END;
/

-- 1.2 Sequences.
BEGIN
    DECLARE
        TYPE t_list IS TABLE OF VARCHAR2(30);
        v_seqs t_list := t_list(
            'SEQ_ENSEIGNANT',
            'SEQ_FILIERE',
            'SEQ_ANNEE',
            'SEQ_SEMESTRE',
            'SEQ_MODULE',
            'SEQ_INSC_ADM',
            'SEQ_INSC_PED',
            'SEQ_NOTE',
            'SEQ_JOURNAL'
        );
    BEGIN
        FOR i IN 1 .. v_seqs.COUNT LOOP
            BEGIN
                EXECUTE IMMEDIATE 'DROP SEQUENCE ' || v_seqs(i);
                DBMS_OUTPUT.PUT_LINE('Sequence supprimee : ' || v_seqs(i));
            EXCEPTION
                WHEN OTHERS THEN
                    IF SQLCODE != -2289 THEN RAISE; END IF;
            END;
        END LOOP;
    END;
END;
/

-- ============================================================
-- SECTION 2 : SEQUENCES
-- Une par table avec PK numerique. ETUDIANT et PARAMETRE ont
-- des cles naturelles, donc pas de sequence pour eux.
-- ============================================================

CREATE SEQUENCE SEQ_ENSEIGNANT
    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE SEQUENCE SEQ_FILIERE
    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE SEQUENCE SEQ_ANNEE
    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE SEQUENCE SEQ_SEMESTRE
    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE SEQUENCE SEQ_MODULE
    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE SEQUENCE SEQ_INSC_ADM
    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE SEQUENCE SEQ_INSC_PED
    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE SEQUENCE SEQ_NOTE
    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- Cache actif car le journal grossit vite.
CREATE SEQUENCE SEQ_JOURNAL
    START WITH 1 INCREMENT BY 1 CACHE 20 NOCYCLE;

-- ============================================================
-- SECTION 3 : TABLES
-- Ordre qui respecte les cles etrangeres.
-- ============================================================

-- 3.1 ETUDIANT
CREATE TABLE ETUDIANT (
    cne             VARCHAR2(15)    NOT NULL,
    nom             VARCHAR2(50)    NOT NULL,
    prenom          VARCHAR2(50)    NOT NULL,
    date_naissance  DATE            NOT NULL,
    lieu_naissance  VARCHAR2(50),
    sexe            CHAR(1),
    email           VARCHAR2(100)   NOT NULL,
    telephone       VARCHAR2(20),
    adresse         VARCHAR2(200),
    actif           NUMBER(1)       DEFAULT 1 NOT NULL,
    date_creation   DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_etudiant          PRIMARY KEY (cne),
    CONSTRAINT uk_etudiant_email    UNIQUE (email),
    CONSTRAINT ck_etudiant_sexe     CHECK (sexe IN ('M','F')),
    CONSTRAINT ck_etudiant_actif    CHECK (actif IN (0,1))
);

-- 3.2 ENSEIGNANT
CREATE TABLE ENSEIGNANT (
    id_enseignant   NUMBER(10)      NOT NULL,
    nom             VARCHAR2(50)    NOT NULL,
    prenom          VARCHAR2(50)    NOT NULL,
    email           VARCHAR2(100)   NOT NULL,
    grade           VARCHAR2(30),
    specialite      VARCHAR2(100),
    CONSTRAINT pk_enseignant        PRIMARY KEY (id_enseignant),
    CONSTRAINT uk_enseignant_email  UNIQUE (email),
    CONSTRAINT ck_enseignant_grade  CHECK (grade IN
        ('PROFESSEUR','MAITRE_CONF','VACATAIRE','ASSISTANT'))
);

-- 3.3 FILIERE
CREATE TABLE FILIERE (
    id_filiere      NUMBER(10)      NOT NULL,
    code_filiere    VARCHAR2(10)    NOT NULL,
    libelle         VARCHAR2(100)   NOT NULL,
    duree_annees    NUMBER(1)       NOT NULL,
    CONSTRAINT pk_filiere           PRIMARY KEY (id_filiere),
    CONSTRAINT uk_filiere_code      UNIQUE (code_filiere),
    CONSTRAINT ck_filiere_duree     CHECK (duree_annees BETWEEN 1 AND 5)
);

-- 3.4 ANNEE_UNIV
CREATE TABLE ANNEE_UNIV (
    id_annee        NUMBER(10)      NOT NULL,
    libelle         VARCHAR2(10)    NOT NULL,
    date_debut      DATE            NOT NULL,
    date_fin        DATE            NOT NULL,
    est_courante    NUMBER(1)       DEFAULT 0 NOT NULL,
    CONSTRAINT pk_annee             PRIMARY KEY (id_annee),
    CONSTRAINT uk_annee_libelle     UNIQUE (libelle),
    CONSTRAINT ck_annee_dates       CHECK (date_fin > date_debut),
    CONSTRAINT ck_annee_courante    CHECK (est_courante IN (0,1))
);

-- 3.5 SEMESTRE (un seul S1, S2... par filiere grace a la contrainte unique)
CREATE TABLE SEMESTRE (
    id_semestre     NUMBER(10)      NOT NULL,
    numero          NUMBER(2)       NOT NULL,
    libelle         VARCHAR2(10)    NOT NULL,
    id_filiere      NUMBER(10)      NOT NULL,
    CONSTRAINT pk_semestre          PRIMARY KEY (id_semestre),
    CONSTRAINT fk_semestre_filiere  FOREIGN KEY (id_filiere)
        REFERENCES FILIERE (id_filiere),
    CONSTRAINT uk_semestre_fil_num  UNIQUE (id_filiere, numero),
    CONSTRAINT ck_semestre_numero   CHECK (numero BETWEEN 1 AND 10)
);

-- 3.6 MODULE (un seul enseignant responsable par module)
CREATE TABLE MODULE (
    id_module       NUMBER(10)      NOT NULL,
    code_module     VARCHAR2(15)    NOT NULL,
    libelle         VARCHAR2(100)   NOT NULL,
    coefficient     NUMBER(3,1)     NOT NULL,
    volume_horaire  NUMBER(4),
    id_semestre     NUMBER(10)      NOT NULL,
    id_enseignant   NUMBER(10)      NOT NULL,
    CONSTRAINT pk_module            PRIMARY KEY (id_module),
    CONSTRAINT fk_module_semestre   FOREIGN KEY (id_semestre)
        REFERENCES SEMESTRE (id_semestre),
    CONSTRAINT fk_module_enseignant FOREIGN KEY (id_enseignant)
        REFERENCES ENSEIGNANT (id_enseignant),
    CONSTRAINT uk_module_code       UNIQUE (code_module),
    CONSTRAINT ck_module_coef       CHECK (coefficient > 0),
    CONSTRAINT ck_module_vol        CHECK (volume_horaire IS NULL OR volume_horaire >= 0)
);

-- 3.7 INSCRIPTION_ADM (une inscription par etudiant et par annee)
CREATE TABLE INSCRIPTION_ADM (
    id_insc_adm      NUMBER(10)     NOT NULL,
    date_inscription DATE           DEFAULT SYSDATE NOT NULL,
    statut           VARCHAR2(15)   NOT NULL,
    annee_etude      NUMBER(1)      NOT NULL,
    actif            NUMBER(1)      DEFAULT 1 NOT NULL,
    cne              VARCHAR2(15)   NOT NULL,
    id_filiere       NUMBER(10)     NOT NULL,
    id_annee         NUMBER(10)     NOT NULL,
    CONSTRAINT pk_insc_adm          PRIMARY KEY (id_insc_adm),
    CONSTRAINT fk_insc_adm_etud     FOREIGN KEY (cne)
        REFERENCES ETUDIANT (cne),
    CONSTRAINT fk_insc_adm_filiere  FOREIGN KEY (id_filiere)
        REFERENCES FILIERE (id_filiere),
    CONSTRAINT fk_insc_adm_annee    FOREIGN KEY (id_annee)
        REFERENCES ANNEE_UNIV (id_annee),
    CONSTRAINT uk_insc_adm_etud_an  UNIQUE (cne, id_annee),
    CONSTRAINT ck_insc_adm_statut   CHECK (statut IN ('INSCRIT','SUSPENDU','DIPLOME')),
    CONSTRAINT ck_insc_adm_annee_e  CHECK (annee_etude BETWEEN 1 AND 5),
    CONSTRAINT ck_insc_adm_actif    CHECK (actif IN (0,1))
);

-- 3.8 INSCRIPTION_PED (inscription a un module, liee a INSCRIPTION_ADM)
CREATE TABLE INSCRIPTION_PED (
    id_insc_ped      NUMBER(10)     NOT NULL,
    date_inscription DATE           DEFAULT SYSDATE NOT NULL,
    statut           VARCHAR2(10)   NOT NULL,
    id_insc_adm      NUMBER(10)     NOT NULL,
    id_module        NUMBER(10)     NOT NULL,
    CONSTRAINT pk_insc_ped          PRIMARY KEY (id_insc_ped),
    CONSTRAINT fk_insc_ped_adm      FOREIGN KEY (id_insc_adm)
        REFERENCES INSCRIPTION_ADM (id_insc_adm),
    CONSTRAINT fk_insc_ped_module   FOREIGN KEY (id_module)
        REFERENCES MODULE (id_module),
    CONSTRAINT uk_insc_ped_adm_mod  UNIQUE (id_insc_adm, id_module),
    CONSTRAINT ck_insc_ped_statut   CHECK (statut IN ('ACTIF','ABANDON'))
);

-- 3.9 NOTE
-- La colonne s'appelle session_type : SESSION est un mot reserve Oracle.
CREATE TABLE NOTE (
    id_note         NUMBER(10)      NOT NULL,
    note_examen     NUMBER(4,2),
    note_cc         NUMBER(4,2),
    note_finale     NUMBER(4,2),
    session_type    VARCHAR2(15)    NOT NULL,
    date_saisie     DATE            DEFAULT SYSDATE NOT NULL,
    validee         NUMBER(1)       DEFAULT 0 NOT NULL,
    id_insc_ped     NUMBER(10)      NOT NULL,
    CONSTRAINT pk_note              PRIMARY KEY (id_note),
    CONSTRAINT fk_note_insc_ped     FOREIGN KEY (id_insc_ped)
        REFERENCES INSCRIPTION_PED (id_insc_ped),
    CONSTRAINT uk_note_insc_ped     UNIQUE (id_insc_ped),
    CONSTRAINT ck_note_examen       CHECK (note_examen IS NULL OR note_examen BETWEEN 0 AND 20),
    CONSTRAINT ck_note_cc           CHECK (note_cc IS NULL OR note_cc BETWEEN 0 AND 20),
    CONSTRAINT ck_note_finale       CHECK (note_finale IS NULL OR note_finale BETWEEN 0 AND 20),
    CONSTRAINT ck_note_session      CHECK (session_type IN ('NORMALE','RATTRAPAGE')),
    CONSTRAINT ck_note_validee      CHECK (validee IN (0,1))
);

-- 3.10 PARAMETRE (poids examen, poids CC, seuil de validation)
CREATE TABLE PARAMETRE (
    code_param      VARCHAR2(30)    NOT NULL,
    valeur          VARCHAR2(100)   NOT NULL,
    description     VARCHAR2(200),
    date_maj        DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_parametre         PRIMARY KEY (code_param)
);

-- 3.11 JOURNAL (table d'audit, alimentee par les triggers du script 05)
CREATE TABLE JOURNAL (
    id_journal          NUMBER(12)      NOT NULL,
    nom_table           VARCHAR2(30)    NOT NULL,
    type_operation      VARCHAR2(10)    NOT NULL,
    cle_enregistrement  VARCHAR2(100)   NOT NULL,
    ancienne_valeur     CLOB,
    nouvelle_valeur     CLOB,
    date_operation      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    utilisateur         VARCHAR2(30)    DEFAULT USER NOT NULL,
    CONSTRAINT pk_journal           PRIMARY KEY (id_journal),
    CONSTRAINT ck_journal_op        CHECK (type_operation IN ('INSERT','UPDATE','DELETE'))
);

-- ============================================================
-- SECTION 4 : TRIGGERS BEFORE INSERT (auto-remplissage des PK)
-- Chaque trigger remplit la cle primaire avec la sequence si
-- l'appelant n'a pas fourni de valeur explicite.
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_BI_ENSEIGNANT
BEFORE INSERT ON ENSEIGNANT
FOR EACH ROW
BEGIN
    IF :NEW.id_enseignant IS NULL THEN
        :NEW.id_enseignant := SEQ_ENSEIGNANT.NEXTVAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_BI_FILIERE
BEFORE INSERT ON FILIERE
FOR EACH ROW
BEGIN
    IF :NEW.id_filiere IS NULL THEN
        :NEW.id_filiere := SEQ_FILIERE.NEXTVAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_BI_ANNEE
BEFORE INSERT ON ANNEE_UNIV
FOR EACH ROW
BEGIN
    IF :NEW.id_annee IS NULL THEN
        :NEW.id_annee := SEQ_ANNEE.NEXTVAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_BI_SEMESTRE
BEFORE INSERT ON SEMESTRE
FOR EACH ROW
BEGIN
    IF :NEW.id_semestre IS NULL THEN
        :NEW.id_semestre := SEQ_SEMESTRE.NEXTVAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_BI_MODULE
BEFORE INSERT ON MODULE
FOR EACH ROW
BEGIN
    IF :NEW.id_module IS NULL THEN
        :NEW.id_module := SEQ_MODULE.NEXTVAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_BI_INSC_ADM
BEFORE INSERT ON INSCRIPTION_ADM
FOR EACH ROW
BEGIN
    IF :NEW.id_insc_adm IS NULL THEN
        :NEW.id_insc_adm := SEQ_INSC_ADM.NEXTVAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_BI_INSC_PED
BEFORE INSERT ON INSCRIPTION_PED
FOR EACH ROW
BEGIN
    IF :NEW.id_insc_ped IS NULL THEN
        :NEW.id_insc_ped := SEQ_INSC_PED.NEXTVAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_BI_NOTE
BEFORE INSERT ON NOTE
FOR EACH ROW
BEGIN
    IF :NEW.id_note IS NULL THEN
        :NEW.id_note := SEQ_NOTE.NEXTVAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_BI_JOURNAL
BEFORE INSERT ON JOURNAL
FOR EACH ROW
BEGIN
    IF :NEW.id_journal IS NULL THEN
        :NEW.id_journal := SEQ_JOURNAL.NEXTVAL;
    END IF;
END;
/

-- ============================================================
-- SECTION 5 : INDEX SECONDAIRES
-- Oracle cree deja un index pour chaque PK et UNIQUE. On ajoute
-- ici des index sur les colonnes de jointure les plus utilisees.
-- ============================================================

CREATE INDEX idx_etudiant_nom        ON ETUDIANT (nom, prenom);

CREATE INDEX idx_insc_adm_etud       ON INSCRIPTION_ADM (cne);
CREATE INDEX idx_insc_adm_filiere    ON INSCRIPTION_ADM (id_filiere);
CREATE INDEX idx_insc_adm_annee      ON INSCRIPTION_ADM (id_annee);

CREATE INDEX idx_insc_ped_adm        ON INSCRIPTION_PED (id_insc_adm);
CREATE INDEX idx_insc_ped_module     ON INSCRIPTION_PED (id_module);

CREATE INDEX idx_module_sem          ON MODULE (id_semestre);
CREATE INDEX idx_module_ens          ON MODULE (id_enseignant);

CREATE INDEX idx_semestre_fil        ON SEMESTRE (id_filiere);

CREATE INDEX idx_journal_date        ON JOURNAL (date_operation);
CREATE INDEX idx_journal_table       ON JOURNAL (nom_table, type_operation);

-- ============================================================
-- SECTION 6 : PARAMETRES INITIAUX
-- Ponderations et seuil de validation. Modifiables sans recompiler
-- le code : les procedures les relisent a chaque saisie.
-- ============================================================

INSERT INTO PARAMETRE (code_param, valeur, description)
VALUES ('POIDS_EXAMEN', '0.6',
        'Ponderation de la note d examen dans la note finale (entre 0 et 1)');

INSERT INTO PARAMETRE (code_param, valeur, description)
VALUES ('POIDS_CC', '0.4',
        'Ponderation de la note de controle continu dans la note finale (entre 0 et 1)');

INSERT INTO PARAMETRE (code_param, valeur, description)
VALUES ('SEUIL_VALIDATION', '10',
        'Note minimale pour valider un module ou un semestre (sur 20)');

COMMIT;

-- ============================================================
-- SECTION 7 : VERIFICATION
-- Compte les objets crees pour valider l'installation.
-- ============================================================

DECLARE
    v_nb_tables    NUMBER;
    v_nb_seq       NUMBER;
    v_nb_trigger   NUMBER;
    v_nb_index     NUMBER;
    v_nb_param     NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_nb_tables
      FROM user_tables
     WHERE table_name IN (
         'ETUDIANT','ENSEIGNANT','FILIERE','ANNEE_UNIV',
         'SEMESTRE','MODULE','INSCRIPTION_ADM','INSCRIPTION_PED',
         'NOTE','PARAMETRE','JOURNAL'
     );

    SELECT COUNT(*) INTO v_nb_seq
      FROM user_sequences
     WHERE sequence_name IN (
         'SEQ_ENSEIGNANT','SEQ_FILIERE','SEQ_ANNEE','SEQ_SEMESTRE',
         'SEQ_MODULE','SEQ_INSC_ADM','SEQ_INSC_PED','SEQ_NOTE',
         'SEQ_JOURNAL'
     );

    SELECT COUNT(*) INTO v_nb_trigger
      FROM user_triggers
     WHERE trigger_name IN (
         'TRG_BI_ENSEIGNANT','TRG_BI_FILIERE','TRG_BI_ANNEE',
         'TRG_BI_SEMESTRE','TRG_BI_MODULE','TRG_BI_INSC_ADM',
         'TRG_BI_INSC_PED','TRG_BI_NOTE','TRG_BI_JOURNAL'
     );

    SELECT COUNT(*) INTO v_nb_index
      FROM user_indexes
     WHERE index_name IN (
         'IDX_ETUDIANT_NOM',
         'IDX_INSC_ADM_ETUD','IDX_INSC_ADM_FILIERE','IDX_INSC_ADM_ANNEE',
         'IDX_INSC_PED_ADM','IDX_INSC_PED_MODULE',
         'IDX_MODULE_SEM','IDX_MODULE_ENS',
         'IDX_SEMESTRE_FIL',
         'IDX_JOURNAL_DATE','IDX_JOURNAL_TABLE'
     );

    SELECT COUNT(*) INTO v_nb_param
      FROM PARAMETRE
     WHERE code_param IN ('POIDS_EXAMEN','POIDS_CC','SEUIL_VALIDATION');

    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  SCHEMA SCOLARITE UNIVERSITAIRE - INSTALLATION OK');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  Tables creees     : ' || v_nb_tables  || ' / 11');
    DBMS_OUTPUT.PUT_LINE('  Sequences creees  : ' || v_nb_seq     || ' / 9');
    DBMS_OUTPUT.PUT_LINE('  Triggers crees    : ' || v_nb_trigger || ' / 9');
    DBMS_OUTPUT.PUT_LINE('  Index secondaires : ' || v_nb_index   || ' / 11');
    DBMS_OUTPUT.PUT_LINE('  Parametres charges: ' || v_nb_param   || ' / 3');
    DBMS_OUTPUT.PUT_LINE('====================================================');
END;
/

-- FIN DU SCRIPT 01 ------------------------------------------------------------

-- Script 02 : jeu de donnees de test.
-- Pre-requis : 01_creation_schema.sql execute.
-- Rejouable : efface les donnees avant de les recharger.

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET DEFINE OFF;  -- evite que SQL Developer interprete les '&'

-- ============================================================
-- SECTION 1 : NETTOYAGE
-- DELETE dans l'ordre inverse des FK. On ne touche pas a
-- PARAMETRE (gere par le script 01) ni a JOURNAL (audit).
-- ============================================================

DELETE FROM NOTE;
DELETE FROM INSCRIPTION_PED;
DELETE FROM INSCRIPTION_ADM;
DELETE FROM MODULE;
DELETE FROM SEMESTRE;
DELETE FROM ANNEE_UNIV;
DELETE FROM FILIERE;
DELETE FROM ENSEIGNANT;
DELETE FROM ETUDIANT;
COMMIT;

-- ============================================================
-- SECTION 2 : ENSEIGNANTS (4)
-- Les PK numeriques sont remplies automatiquement par les
-- triggers BEFORE INSERT du script 01.
-- ============================================================

INSERT INTO ENSEIGNANT (nom, prenom, email, grade, specialite)
VALUES ('EL AMRANI', 'Mohamed', 'mohamed.amrani@univ.ma', 'PROFESSEUR',  'Informatique');

INSERT INTO ENSEIGNANT (nom, prenom, email, grade, specialite)
VALUES ('BENALI',    'Fatima',  'fatima.benali@univ.ma',  'MAITRE_CONF', 'Mathematiques');

INSERT INTO ENSEIGNANT (nom, prenom, email, grade, specialite)
VALUES ('CHAOUI',    'Karim',   'karim.chaoui@univ.ma',   'VACATAIRE',   'Langues');

INSERT INTO ENSEIGNANT (nom, prenom, email, grade, specialite)
VALUES ('TAZI',      'Laila',   'laila.tazi@univ.ma',     'MAITRE_CONF', 'Physique');

-- ============================================================
-- SECTION 3 : FILIERES (2)
-- ============================================================

INSERT INTO FILIERE (code_filiere, libelle, duree_annees)
VALUES ('SMI', 'Sciences Mathematiques et Informatique', 3);

INSERT INTO FILIERE (code_filiere, libelle, duree_annees)
VALUES ('SMA', 'Sciences Mathematiques Appliquees',      3);

-- ============================================================
-- SECTION 4 : ANNEES UNIVERSITAIRES
-- 2024-2025 : historique, 2025-2026 : courante.
-- ============================================================

INSERT INTO ANNEE_UNIV (libelle, date_debut, date_fin, est_courante)
VALUES ('2024-2025', DATE '2024-09-01', DATE '2025-06-30', 0);

INSERT INTO ANNEE_UNIV (libelle, date_debut, date_fin, est_courante)
VALUES ('2025-2026', DATE '2025-09-01', DATE '2026-06-30', 1);

-- ============================================================
-- SECTION 5 : SEMESTRES (2 par filiere)
-- ============================================================

INSERT INTO SEMESTRE (numero, libelle, id_filiere)
VALUES (1, 'S1',
        (SELECT id_filiere FROM FILIERE WHERE code_filiere = 'SMI'));

INSERT INTO SEMESTRE (numero, libelle, id_filiere)
VALUES (2, 'S2',
        (SELECT id_filiere FROM FILIERE WHERE code_filiere = 'SMI'));

INSERT INTO SEMESTRE (numero, libelle, id_filiere)
VALUES (1, 'S1',
        (SELECT id_filiere FROM FILIERE WHERE code_filiere = 'SMA'));

INSERT INTO SEMESTRE (numero, libelle, id_filiere)
VALUES (2, 'S2',
        (SELECT id_filiere FROM FILIERE WHERE code_filiere = 'SMA'));

-- ============================================================
-- SECTION 6 : MODULES (7)
-- Les references aux semestres et enseignants sont resolues
-- par sous-requete sur les codes (plus lisible que des IDs).
-- ============================================================

-- SMI S1
INSERT INTO MODULE (code_module, libelle, coefficient, volume_horaire,
                    id_semestre, id_enseignant)
VALUES ('SMI1001', 'Algorithmique 1', 3, 60,
        (SELECT s.id_semestre FROM SEMESTRE s
           JOIN FILIERE f ON f.id_filiere = s.id_filiere
         WHERE f.code_filiere = 'SMI' AND s.numero = 1),
        (SELECT id_enseignant FROM ENSEIGNANT WHERE email = 'mohamed.amrani@univ.ma'));

INSERT INTO MODULE (code_module, libelle, coefficient, volume_horaire,
                    id_semestre, id_enseignant)
VALUES ('SMI1002', 'Base de Donnees 1', 4, 80,
        (SELECT s.id_semestre FROM SEMESTRE s
           JOIN FILIERE f ON f.id_filiere = s.id_filiere
         WHERE f.code_filiere = 'SMI' AND s.numero = 1),
        (SELECT id_enseignant FROM ENSEIGNANT WHERE email = 'mohamed.amrani@univ.ma'));

INSERT INTO MODULE (code_module, libelle, coefficient, volume_horaire,
                    id_semestre, id_enseignant)
VALUES ('SMI1003', 'Anglais', 1, 30,
        (SELECT s.id_semestre FROM SEMESTRE s
           JOIN FILIERE f ON f.id_filiere = s.id_filiere
         WHERE f.code_filiere = 'SMI' AND s.numero = 1),
        (SELECT id_enseignant FROM ENSEIGNANT WHERE email = 'karim.chaoui@univ.ma'));

-- SMI S2
INSERT INTO MODULE (code_module, libelle, coefficient, volume_horaire,
                    id_semestre, id_enseignant)
VALUES ('SMI2001', 'Algorithmique 2', 3, 60,
        (SELECT s.id_semestre FROM SEMESTRE s
           JOIN FILIERE f ON f.id_filiere = s.id_filiere
         WHERE f.code_filiere = 'SMI' AND s.numero = 2),
        (SELECT id_enseignant FROM ENSEIGNANT WHERE email = 'mohamed.amrani@univ.ma'));

INSERT INTO MODULE (code_module, libelle, coefficient, volume_horaire,
                    id_semestre, id_enseignant)
VALUES ('SMI2002', 'Base de Donnees 2', 4, 80,
        (SELECT s.id_semestre FROM SEMESTRE s
           JOIN FILIERE f ON f.id_filiere = s.id_filiere
         WHERE f.code_filiere = 'SMI' AND s.numero = 2),
        (SELECT id_enseignant FROM ENSEIGNANT WHERE email = 'mohamed.amrani@univ.ma'));

-- SMA S1
INSERT INTO MODULE (code_module, libelle, coefficient, volume_horaire,
                    id_semestre, id_enseignant)
VALUES ('SMA1001', 'Analyse 1', 4, 80,
        (SELECT s.id_semestre FROM SEMESTRE s
           JOIN FILIERE f ON f.id_filiere = s.id_filiere
         WHERE f.code_filiere = 'SMA' AND s.numero = 1),
        (SELECT id_enseignant FROM ENSEIGNANT WHERE email = 'fatima.benali@univ.ma'));

INSERT INTO MODULE (code_module, libelle, coefficient, volume_horaire,
                    id_semestre, id_enseignant)
VALUES ('SMA1002', 'Algebre 1', 3, 60,
        (SELECT s.id_semestre FROM SEMESTRE s
           JOIN FILIERE f ON f.id_filiere = s.id_filiere
         WHERE f.code_filiere = 'SMA' AND s.numero = 1),
        (SELECT id_enseignant FROM ENSEIGNANT WHERE email = 'laila.tazi@univ.ma'));

-- ============================================================
-- SECTION 7 : ETUDIANTS (6)
-- Le CNE est la cle, on le fournit directement.
-- ============================================================

INSERT INTO ETUDIANT (cne, nom, prenom, date_naissance, lieu_naissance, sexe,
                      email, telephone, adresse)
VALUES ('E001', 'ALAMI',    'Youssef', DATE '2003-05-12', 'Rabat',      'M',
        'y.alami@etu.ma',    '0612345678', '12 Rue des Orangers, Rabat');

INSERT INTO ETUDIANT (cne, nom, prenom, date_naissance, lieu_naissance, sexe,
                      email, telephone, adresse)
VALUES ('E002', 'BENNANI',  'Sara',    DATE '2004-02-20', 'Casablanca', 'F',
        's.bennani@etu.ma',  '0623456789', '5 Avenue Mohamed V, Casablanca');

INSERT INTO ETUDIANT (cne, nom, prenom, date_naissance, lieu_naissance, sexe,
                      email, telephone, adresse)
VALUES ('E003', 'CHAKIR',   'Ahmed',   DATE '2003-11-08', 'Fes',        'M',
        'a.chakir@etu.ma',   '0634567890', '8 Boulevard Hassan II, Fes');

INSERT INTO ETUDIANT (cne, nom, prenom, date_naissance, lieu_naissance, sexe,
                      email, telephone, adresse)
VALUES ('E004', 'DAOUDI',   'Imane',   DATE '2004-06-15', 'Marrakech',  'F',
        'i.daoudi@etu.ma',   '0645678901', '3 Rue Jamaa el Fna, Marrakech');

INSERT INTO ETUDIANT (cne, nom, prenom, date_naissance, lieu_naissance, sexe,
                      email, telephone, adresse)
VALUES ('E005', 'EL FASSI', 'Omar',    DATE '2003-03-22', 'Tanger',     'M',
        'o.elfassi@etu.ma',  '0656789012', '15 Avenue d Espagne, Tanger');

INSERT INTO ETUDIANT (cne, nom, prenom, date_naissance, lieu_naissance, sexe,
                      email, telephone, adresse)
VALUES ('E006', 'FILALI',   'Nora',    DATE '2004-08-30', 'Agadir',     'F',
        'n.filali@etu.ma',   '0667890123', '22 Rue de la Plage, Agadir');

-- ============================================================
-- SECTION 8 : INSCRIPTIONS ADMINISTRATIVES
-- E001 est inscrit 2 fois (2024-2025 puis 2025-2026, car il a
-- valide sa 1re annee). Les autres sont en 1re annee 2025-2026.
-- ============================================================

-- E001 en 2024-2025 (historique)
INSERT INTO INSCRIPTION_ADM (date_inscription, statut, annee_etude,
                             cne, id_filiere, id_annee)
VALUES (DATE '2024-09-15', 'INSCRIT', 1,
        'E001',
        (SELECT id_filiere FROM FILIERE    WHERE code_filiere = 'SMI'),
        (SELECT id_annee   FROM ANNEE_UNIV WHERE libelle      = '2024-2025'));

-- E001 en 2025-2026 (courante, annee 2)
INSERT INTO INSCRIPTION_ADM (date_inscription, statut, annee_etude,
                             cne, id_filiere, id_annee)
VALUES (DATE '2025-09-10', 'INSCRIT', 2,
        'E001',
        (SELECT id_filiere FROM FILIERE    WHERE code_filiere = 'SMI'),
        (SELECT id_annee   FROM ANNEE_UNIV WHERE libelle      = '2025-2026'));

-- E002 (SMI)
INSERT INTO INSCRIPTION_ADM (date_inscription, statut, annee_etude,
                             cne, id_filiere, id_annee)
VALUES (DATE '2025-09-12', 'INSCRIT', 1,
        'E002',
        (SELECT id_filiere FROM FILIERE    WHERE code_filiere = 'SMI'),
        (SELECT id_annee   FROM ANNEE_UNIV WHERE libelle      = '2025-2026'));

-- E003 (SMA)
INSERT INTO INSCRIPTION_ADM (date_inscription, statut, annee_etude,
                             cne, id_filiere, id_annee)
VALUES (DATE '2025-09-12', 'INSCRIT', 1,
        'E003',
        (SELECT id_filiere FROM FILIERE    WHERE code_filiere = 'SMA'),
        (SELECT id_annee   FROM ANNEE_UNIV WHERE libelle      = '2025-2026'));

-- E004 (SMI)
INSERT INTO INSCRIPTION_ADM (date_inscription, statut, annee_etude,
                             cne, id_filiere, id_annee)
VALUES (DATE '2025-09-13', 'INSCRIT', 1,
        'E004',
        (SELECT id_filiere FROM FILIERE    WHERE code_filiere = 'SMI'),
        (SELECT id_annee   FROM ANNEE_UNIV WHERE libelle      = '2025-2026'));

-- E005 (SMA)
INSERT INTO INSCRIPTION_ADM (date_inscription, statut, annee_etude,
                             cne, id_filiere, id_annee)
VALUES (DATE '2025-09-13', 'INSCRIT', 1,
        'E005',
        (SELECT id_filiere FROM FILIERE    WHERE code_filiere = 'SMA'),
        (SELECT id_annee   FROM ANNEE_UNIV WHERE libelle      = '2025-2026'));

-- E006 (SMI)
INSERT INTO INSCRIPTION_ADM (date_inscription, statut, annee_etude,
                             cne, id_filiere, id_annee)
VALUES (DATE '2025-09-14', 'INSCRIT', 1,
        'E006',
        (SELECT id_filiere FROM FILIERE    WHERE code_filiere = 'SMI'),
        (SELECT id_annee   FROM ANNEE_UNIV WHERE libelle      = '2025-2026'));

-- ============================================================
-- SECTION 9 : INSCRIPTIONS PEDAGOGIQUES
-- Chaque INSERT retrouve l'inscription admin par (cne, annee).
-- ============================================================

-- E001 2024-2025, S1 (Algo1, BD1, Anglais)
INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E001' AND a.libelle = '2024-2025'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMI1001'));

INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E001' AND a.libelle = '2024-2025'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMI1002'));

INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E001' AND a.libelle = '2024-2025'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMI1003'));

-- E001 2024-2025, S2 (Algo2, BD2)
INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E001' AND a.libelle = '2024-2025'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMI2001'));

INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E001' AND a.libelle = '2024-2025'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMI2002'));

-- E002 2025-2026, S1 SMI
INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E002' AND a.libelle = '2025-2026'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMI1001'));

INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E002' AND a.libelle = '2025-2026'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMI1002'));

INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E002' AND a.libelle = '2025-2026'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMI1003'));

-- E003 2025-2026, S1 SMA
INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E003' AND a.libelle = '2025-2026'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMA1001'));

INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E003' AND a.libelle = '2025-2026'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMA1002'));

-- E004 2025-2026, S1 SMI
INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E004' AND a.libelle = '2025-2026'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMI1001'));

INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E004' AND a.libelle = '2025-2026'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMI1002'));

INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E004' AND a.libelle = '2025-2026'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMI1003'));

-- E005 2025-2026, S1 SMA (inscrit mais aucune note)
INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E005' AND a.libelle = '2025-2026'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMA1001'));

INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E005' AND a.libelle = '2025-2026'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMA1002'));

-- E006 2025-2026, S1 SMI (2 modules seulement)
INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E006' AND a.libelle = '2025-2026'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMI1001'));

INSERT INTO INSCRIPTION_PED (statut, id_insc_adm, id_module)
VALUES ('ACTIF',
        (SELECT ia.id_insc_adm FROM INSCRIPTION_ADM ia
           JOIN ANNEE_UNIV a ON a.id_annee = ia.id_annee
         WHERE ia.cne = 'E006' AND a.libelle = '2025-2026'),
        (SELECT id_module FROM MODULE WHERE code_module = 'SMI1002'));

-- ============================================================
-- SECTION 10 : NOTES
-- Note finale = 0.6 * examen + 0.4 * cc.
-- On melange volontairement plusieurs cas : tout valide, partiel,
-- echec, et aucune note, pour pouvoir tester toutes les vues.
-- ============================================================

-- E001 2024-2025 S1 (3 notes validees)
INSERT INTO NOTE (note_examen, note_cc, note_finale, session_type, validee, id_insc_ped)
VALUES (14, 12, 13.2, 'NORMALE', 1,
        (SELECT ip.id_insc_ped
           FROM INSCRIPTION_PED ip
           JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
           JOIN ANNEE_UNIV a       ON a.id_annee    = ia.id_annee
           JOIN MODULE m           ON m.id_module   = ip.id_module
         WHERE ia.cne = 'E001' AND a.libelle = '2024-2025' AND m.code_module = 'SMI1001'));

INSERT INTO NOTE (note_examen, note_cc, note_finale, session_type, validee, id_insc_ped)
VALUES (15, 13, 14.2, 'NORMALE', 1,
        (SELECT ip.id_insc_ped
           FROM INSCRIPTION_PED ip
           JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
           JOIN ANNEE_UNIV a       ON a.id_annee    = ia.id_annee
           JOIN MODULE m           ON m.id_module   = ip.id_module
         WHERE ia.cne = 'E001' AND a.libelle = '2024-2025' AND m.code_module = 'SMI1002'));

INSERT INTO NOTE (note_examen, note_cc, note_finale, session_type, validee, id_insc_ped)
VALUES (16, 15, 15.6, 'NORMALE', 1,
        (SELECT ip.id_insc_ped
           FROM INSCRIPTION_PED ip
           JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
           JOIN ANNEE_UNIV a       ON a.id_annee    = ia.id_annee
           JOIN MODULE m           ON m.id_module   = ip.id_module
         WHERE ia.cne = 'E001' AND a.libelle = '2024-2025' AND m.code_module = 'SMI1003'));

-- E001 2024-2025 S2 (2 notes validees)
INSERT INTO NOTE (note_examen, note_cc, note_finale, session_type, validee, id_insc_ped)
VALUES (11, 10, 10.6, 'NORMALE', 1,
        (SELECT ip.id_insc_ped
           FROM INSCRIPTION_PED ip
           JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
           JOIN ANNEE_UNIV a       ON a.id_annee    = ia.id_annee
           JOIN MODULE m           ON m.id_module   = ip.id_module
         WHERE ia.cne = 'E001' AND a.libelle = '2024-2025' AND m.code_module = 'SMI2001'));

INSERT INTO NOTE (note_examen, note_cc, note_finale, session_type, validee, id_insc_ped)
VALUES (13, 11, 12.2, 'NORMALE', 1,
        (SELECT ip.id_insc_ped
           FROM INSCRIPTION_PED ip
           JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
           JOIN ANNEE_UNIV a       ON a.id_annee    = ia.id_annee
           JOIN MODULE m           ON m.id_module   = ip.id_module
         WHERE ia.cne = 'E001' AND a.libelle = '2024-2025' AND m.code_module = 'SMI2002'));

-- E002 2025-2026 S1 (1 echec, 1 validee, 1 sans note)
INSERT INTO NOTE (note_examen, note_cc, note_finale, session_type, validee, id_insc_ped)
VALUES (8, 6, 7.2, 'NORMALE', 1,
        (SELECT ip.id_insc_ped
           FROM INSCRIPTION_PED ip
           JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
           JOIN ANNEE_UNIV a       ON a.id_annee    = ia.id_annee
           JOIN MODULE m           ON m.id_module   = ip.id_module
         WHERE ia.cne = 'E002' AND a.libelle = '2025-2026' AND m.code_module = 'SMI1001'));

INSERT INTO NOTE (note_examen, note_cc, note_finale, session_type, validee, id_insc_ped)
VALUES (11, 10, 10.6, 'NORMALE', 1,
        (SELECT ip.id_insc_ped
           FROM INSCRIPTION_PED ip
           JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
           JOIN ANNEE_UNIV a       ON a.id_annee    = ia.id_annee
           JOIN MODULE m           ON m.id_module   = ip.id_module
         WHERE ia.cne = 'E002' AND a.libelle = '2025-2026' AND m.code_module = 'SMI1002'));

-- E003 2025-2026 (Analyse 1 validee, Algebre sans note)
INSERT INTO NOTE (note_examen, note_cc, note_finale, session_type, validee, id_insc_ped)
VALUES (12, 14, 12.8, 'NORMALE', 1,
        (SELECT ip.id_insc_ped
           FROM INSCRIPTION_PED ip
           JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
           JOIN ANNEE_UNIV a       ON a.id_annee    = ia.id_annee
           JOIN MODULE m           ON m.id_module   = ip.id_module
         WHERE ia.cne = 'E003' AND a.libelle = '2025-2026' AND m.code_module = 'SMA1001'));

-- E004 2025-2026 (Algo1 avec tres bonne note, reste sans note)
INSERT INTO NOTE (note_examen, note_cc, note_finale, session_type, validee, id_insc_ped)
VALUES (17, 16, 16.6, 'NORMALE', 1,
        (SELECT ip.id_insc_ped
           FROM INSCRIPTION_PED ip
           JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm = ip.id_insc_adm
           JOIN ANNEE_UNIV a       ON a.id_annee    = ia.id_annee
           JOIN MODULE m           ON m.id_module   = ip.id_module
         WHERE ia.cne = 'E004' AND a.libelle = '2025-2026' AND m.code_module = 'SMI1001'));

-- E005 et E006 : volontairement aucune note.

COMMIT;

-- ============================================================
-- SECTION 11 : VERIFICATIONS
-- Quelques SELECT pour controler que le chargement est coherent.
-- ============================================================

PROMPT ====================================================
PROMPT 1) Comptage des lignes par table
PROMPT ====================================================
SELECT 'ENSEIGNANT'       AS table_name, COUNT(*) AS nb FROM ENSEIGNANT
UNION ALL SELECT 'FILIERE',           COUNT(*) FROM FILIERE
UNION ALL SELECT 'ANNEE_UNIV',        COUNT(*) FROM ANNEE_UNIV
UNION ALL SELECT 'SEMESTRE',          COUNT(*) FROM SEMESTRE
UNION ALL SELECT 'MODULE',            COUNT(*) FROM MODULE
UNION ALL SELECT 'ETUDIANT',          COUNT(*) FROM ETUDIANT
UNION ALL SELECT 'INSCRIPTION_ADM',   COUNT(*) FROM INSCRIPTION_ADM
UNION ALL SELECT 'INSCRIPTION_PED',   COUNT(*) FROM INSCRIPTION_PED
UNION ALL SELECT 'NOTE',              COUNT(*) FROM NOTE;

PROMPT ====================================================
PROMPT 2) Liste des modules avec filiere, semestre et enseignant
PROMPT ====================================================
SELECT f.code_filiere    AS filiere,
       s.libelle         AS semestre,
       m.code_module     AS code,
       m.libelle         AS module_libelle,
       m.coefficient     AS coef,
       e.nom || ' ' || e.prenom AS enseignant
  FROM MODULE     m
  JOIN SEMESTRE   s ON s.id_semestre   = m.id_semestre
  JOIN FILIERE    f ON f.id_filiere    = s.id_filiere
  JOIN ENSEIGNANT e ON e.id_enseignant = m.id_enseignant
 ORDER BY f.code_filiere, s.numero, m.code_module;

PROMPT ====================================================
PROMPT 3) Etudiants et leurs inscriptions administratives
PROMPT ====================================================
SELECT et.cne, et.nom, et.prenom,
       f.code_filiere    AS filiere,
       a.libelle         AS annee,
       ia.annee_etude    AS annee_etude,
       ia.statut
  FROM INSCRIPTION_ADM ia
  JOIN ETUDIANT     et ON et.cne      = ia.cne
  JOIN FILIERE      f  ON f.id_filiere= ia.id_filiere
  JOIN ANNEE_UNIV   a  ON a.id_annee  = ia.id_annee
 ORDER BY a.libelle DESC, et.cne;

PROMPT ====================================================
PROMPT 4) Nombre d'inscriptions pedagogiques par etudiant
PROMPT ====================================================
SELECT et.cne,
       et.nom || ' ' || et.prenom AS etudiant,
       a.libelle                  AS annee,
       COUNT(ip.id_insc_ped)      AS nb_modules,
       COUNT(n.id_note)           AS nb_notes
  FROM INSCRIPTION_ADM ia
  JOIN ETUDIANT        et ON et.cne       = ia.cne
  JOIN ANNEE_UNIV      a  ON a.id_annee   = ia.id_annee
  LEFT JOIN INSCRIPTION_PED ip ON ip.id_insc_adm = ia.id_insc_adm
  LEFT JOIN NOTE            n  ON n.id_insc_ped  = ip.id_insc_ped
 GROUP BY et.cne, et.nom, et.prenom, a.libelle
 ORDER BY a.libelle DESC, et.cne;

PROMPT ====================================================
PROMPT 5) Moyenne ponderee par etudiant et par annee (notes disponibles)
PROMPT ====================================================
SELECT et.cne,
       et.nom || ' ' || et.prenom AS etudiant,
       a.libelle                  AS annee,
       ROUND(SUM(n.note_finale * m.coefficient)
             / NULLIF(SUM(m.coefficient), 0), 2) AS moyenne_ponderee,
       COUNT(n.id_note)           AS nb_notes
  FROM INSCRIPTION_ADM ia
  JOIN ETUDIANT        et ON et.cne          = ia.cne
  JOIN ANNEE_UNIV      a  ON a.id_annee      = ia.id_annee
  JOIN INSCRIPTION_PED ip ON ip.id_insc_adm  = ia.id_insc_adm
  JOIN MODULE          m  ON m.id_module     = ip.id_module
  LEFT JOIN NOTE       n  ON n.id_insc_ped   = ip.id_insc_ped
 GROUP BY et.cne, et.nom, et.prenom, a.libelle
 ORDER BY a.libelle DESC, moyenne_ponderee DESC NULLS LAST;

PROMPT ====================================================
PROMPT 6) Detail des notes de E001 (annee 2024-2025)
PROMPT ====================================================
SELECT m.code_module,
       m.libelle         AS module_libelle,
       m.coefficient     AS coef,
       n.note_examen,
       n.note_cc,
       n.note_finale,
       n.session_type,
       CASE WHEN n.note_finale >= 10 THEN 'VALIDE' ELSE 'NON VALIDE' END AS etat
  FROM INSCRIPTION_ADM ia
  JOIN ANNEE_UNIV      a  ON a.id_annee      = ia.id_annee
  JOIN INSCRIPTION_PED ip ON ip.id_insc_adm  = ia.id_insc_adm
  JOIN MODULE          m  ON m.id_module     = ip.id_module
  LEFT JOIN NOTE       n  ON n.id_insc_ped   = ip.id_insc_ped
 WHERE ia.cne     = 'E001'
   AND a.libelle  = '2024-2025'
 ORDER BY m.code_module;

PROMPT ====================================================
PROMPT Jeu de donnees de test charge avec succes.
PROMPT ====================================================

-- FIN DU SCRIPT 02 ------------------------------------------------------------

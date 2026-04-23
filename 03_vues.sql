-- Script 03 : vues SQL (presentation, analyse, statistiques).
-- Pre-requis : scripts 01 et 02 executes.
-- Rejouable : utilise CREATE OR REPLACE VIEW.

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET DEFINE OFF;

-- ============================================================
-- PARTIE A : VUES DE PRESENTATION
-- ============================================================

-- V_ETUDIANT_MODULE_NOTE : vue "fourre-tout" qui croise etudiant,
-- inscription, module, semestre, filiere, annee, enseignant et
-- note. Sert de base aux autres vues et aux requetes ad-hoc.

CREATE OR REPLACE VIEW V_ETUDIANT_MODULE_NOTE AS
SELECT
    et.cne                              AS cne,
    et.nom                              AS nom_etudiant,
    et.prenom                           AS prenom_etudiant,
    f.code_filiere                      AS code_filiere,
    f.libelle                           AS libelle_filiere,
    a.libelle                           AS annee_univ,
    s.numero                            AS numero_semestre,
    s.libelle                           AS libelle_semestre,
    m.code_module                       AS code_module,
    m.libelle                           AS libelle_module,
    m.coefficient                       AS coefficient,
    ens.nom || ' ' || ens.prenom        AS enseignant,
    ip.statut                           AS statut_inscription,
    n.note_examen                       AS note_examen,
    n.note_cc                           AS note_cc,
    n.note_finale                       AS note_finale,
    n.session_type                      AS session_type,
    n.validee                           AS note_validee,
    CASE
        WHEN n.id_note IS NULL          THEN 'PAS DE NOTE'
        WHEN n.note_finale >= 10        THEN 'VALIDE'
        ELSE                                'NON VALIDE'
    END                                 AS etat_module
FROM INSCRIPTION_ADM ia
JOIN ETUDIANT         et  ON et.cne          = ia.cne
JOIN FILIERE          f   ON f.id_filiere    = ia.id_filiere
JOIN ANNEE_UNIV       a   ON a.id_annee      = ia.id_annee
JOIN INSCRIPTION_PED  ip  ON ip.id_insc_adm  = ia.id_insc_adm
JOIN MODULE           m   ON m.id_module     = ip.id_module
JOIN SEMESTRE         s   ON s.id_semestre   = m.id_semestre
JOIN ENSEIGNANT       ens ON ens.id_enseignant = m.id_enseignant
LEFT JOIN NOTE        n   ON n.id_insc_ped   = ip.id_insc_ped;

-- V_RELEVE_NOTES : format "releve officiel", une ligne = un module.
-- Construite au-dessus de V_ETUDIANT_MODULE_NOTE pour reutilisation.

CREATE OR REPLACE VIEW V_RELEVE_NOTES AS
SELECT
    cne                                 AS cne,
    nom_etudiant || ' ' || prenom_etudiant  AS etudiant,
    code_filiere                        AS filiere,
    annee_univ                          AS annee,
    libelle_semestre                    AS semestre,
    code_module                         AS code,
    libelle_module                      AS matiere,
    coefficient                         AS coef,
    note_examen,
    note_cc,
    note_finale,
    session_type                        AS session_type,
    etat_module                         AS etat
FROM V_ETUDIANT_MODULE_NOTE;

-- ============================================================
-- PARTIE B : VUES D'ANALYSE (moyennes et validation)
-- ============================================================

-- V_MOYENNES_SEMESTRE : moyenne ponderee par etudiant/annee/semestre.
-- Etat : INCOMPLET si une note manque, sinon VALIDE / NON VALIDE
-- selon le seuil lu dans la table PARAMETRE.

CREATE OR REPLACE VIEW V_MOYENNES_SEMESTRE AS
SELECT
    ia.cne                                                         AS cne,
    et.nom                                                         AS nom_etudiant,
    et.prenom                                                      AS prenom_etudiant,
    f.code_filiere                                                 AS filiere,
    a.libelle                                                      AS annee,
    s.numero                                                       AS numero_semestre,
    s.libelle                                                      AS libelle_semestre,
    COUNT(ip.id_insc_ped)                                          AS nb_modules,
    COUNT(n.id_note)                                               AS nb_notes,
    ROUND(
        SUM(n.note_finale * m.coefficient)
        / NULLIF(SUM(CASE WHEN n.id_note IS NOT NULL THEN m.coefficient END), 0),
    2)                                                             AS moyenne_ponderee,
    CASE
        WHEN COUNT(n.id_note) < COUNT(ip.id_insc_ped)
             THEN 'INCOMPLET'
        WHEN SUM(n.note_finale * m.coefficient)
             / NULLIF(SUM(m.coefficient), 0)
             >= (SELECT TO_NUMBER(valeur) FROM PARAMETRE WHERE code_param = 'SEUIL_VALIDATION')
             THEN 'VALIDE'
        ELSE 'NON VALIDE'
    END                                                            AS etat_semestre
FROM INSCRIPTION_ADM   ia
JOIN ETUDIANT          et ON et.cne          = ia.cne
JOIN FILIERE           f  ON f.id_filiere    = ia.id_filiere
JOIN ANNEE_UNIV        a  ON a.id_annee      = ia.id_annee
JOIN INSCRIPTION_PED   ip ON ip.id_insc_adm  = ia.id_insc_adm
JOIN MODULE            m  ON m.id_module     = ip.id_module
JOIN SEMESTRE          s  ON s.id_semestre   = m.id_semestre
LEFT JOIN NOTE         n  ON n.id_insc_ped   = ip.id_insc_ped
GROUP BY ia.cne, et.nom, et.prenom, f.code_filiere,
         a.libelle, s.numero, s.libelle;

-- V_VALIDATION_ANNEE : synthese annuelle (S1 + S2 cote a cote).
-- L'annee est VALIDE uniquement si les deux semestres le sont.
-- Pivot realise avec MAX(CASE WHEN ...) sur V_MOYENNES_SEMESTRE.

CREATE OR REPLACE VIEW V_VALIDATION_ANNEE AS
SELECT
    cne                                              AS cne,
    nom_etudiant                                     AS nom_etudiant,
    prenom_etudiant                                  AS prenom_etudiant,
    filiere                                          AS filiere,
    annee                                            AS annee,
    MAX(CASE WHEN numero_semestre = 1 THEN moyenne_ponderee END) AS moyenne_s1,
    MAX(CASE WHEN numero_semestre = 2 THEN moyenne_ponderee END) AS moyenne_s2,
    MAX(CASE WHEN numero_semestre = 1 THEN etat_semestre    END) AS etat_s1,
    MAX(CASE WHEN numero_semestre = 2 THEN etat_semestre    END) AS etat_s2,
    ROUND(
        (NVL(MAX(CASE WHEN numero_semestre = 1 THEN moyenne_ponderee END), 0)
       + NVL(MAX(CASE WHEN numero_semestre = 2 THEN moyenne_ponderee END), 0)
        ) / 2, 2)                                    AS moyenne_annuelle,
    CASE
        WHEN MAX(CASE WHEN numero_semestre = 1 THEN etat_semestre END) = 'VALIDE'
         AND MAX(CASE WHEN numero_semestre = 2 THEN etat_semestre END) = 'VALIDE'
             THEN 'VALIDE'
        WHEN MAX(CASE WHEN numero_semestre = 1 THEN etat_semestre END) = 'INCOMPLET'
          OR MAX(CASE WHEN numero_semestre = 2 THEN etat_semestre END) = 'INCOMPLET'
          OR MAX(CASE WHEN numero_semestre = 1 THEN etat_semestre END) IS NULL
          OR MAX(CASE WHEN numero_semestre = 2 THEN etat_semestre END) IS NULL
             THEN 'INCOMPLET'
        ELSE 'NON VALIDE'
    END                                              AS etat_annee
FROM V_MOYENNES_SEMESTRE
GROUP BY cne, nom_etudiant, prenom_etudiant, filiere, annee;

-- ============================================================
-- PARTIE C : VUES STATISTIQUES (tableaux de bord)
-- ============================================================

-- V_STATS_FILIERE : stats par filiere et par annee (nb etudiants,
-- nb modules, moyenne, min, max, nb valides, taux de reussite).

CREATE OR REPLACE VIEW V_STATS_FILIERE AS
SELECT
    f.code_filiere                                         AS filiere,
    a.libelle                                              AS annee,
    COUNT(DISTINCT ia.cne)                                 AS nb_etudiants,
    COUNT(DISTINCT m.id_module)                            AS nb_modules,
    COUNT(n.id_note)                                       AS nb_notes_saisies,
    ROUND(AVG(n.note_finale), 2)                           AS moyenne_generale,
    ROUND(MIN(n.note_finale), 2)                           AS note_min,
    ROUND(MAX(n.note_finale), 2)                           AS note_max,
    SUM(CASE WHEN n.note_finale >= 10 THEN 1 ELSE 0 END)   AS nb_valides,
    SUM(CASE WHEN n.note_finale <  10 THEN 1 ELSE 0 END)   AS nb_non_valides,
    ROUND(
        SUM(CASE WHEN n.note_finale >= 10 THEN 1 ELSE 0 END) * 100
        / NULLIF(COUNT(n.id_note), 0),
    2)                                                     AS taux_reussite
FROM FILIERE              f
JOIN INSCRIPTION_ADM      ia ON ia.id_filiere   = f.id_filiere
JOIN ANNEE_UNIV           a  ON a.id_annee      = ia.id_annee
LEFT JOIN INSCRIPTION_PED ip ON ip.id_insc_adm  = ia.id_insc_adm
LEFT JOIN MODULE          m  ON m.id_module     = ip.id_module
LEFT JOIN NOTE            n  ON n.id_insc_ped   = ip.id_insc_ped
GROUP BY f.code_filiere, a.libelle;

-- V_STATS_MODULE : stats par module (enseignant, nb inscrits,
-- moyenne, min, max, taux de reussite). Les modules sans inscription
-- apparaissent avec nb_inscrits = 0.

CREATE OR REPLACE VIEW V_STATS_MODULE AS
SELECT
    m.code_module                                          AS code_module,
    m.libelle                                              AS libelle_module,
    f.code_filiere                                         AS filiere,
    s.libelle                                              AS semestre,
    a.libelle                                              AS annee,
    ens.nom || ' ' || ens.prenom                           AS enseignant,
    COUNT(DISTINCT ip.id_insc_ped)                         AS nb_inscrits,
    COUNT(n.id_note)                                       AS nb_notes,
    ROUND(AVG(n.note_finale), 2)                           AS moyenne,
    ROUND(MIN(n.note_finale), 2)                           AS note_min,
    ROUND(MAX(n.note_finale), 2)                           AS note_max,
    SUM(CASE WHEN n.note_finale >= 10 THEN 1 ELSE 0 END)   AS nb_valides,
    ROUND(
        SUM(CASE WHEN n.note_finale >= 10 THEN 1 ELSE 0 END) * 100
        / NULLIF(COUNT(n.id_note), 0),
    2)                                                     AS taux_reussite
FROM MODULE     m
JOIN SEMESTRE   s   ON s.id_semestre    = m.id_semestre
JOIN FILIERE    f   ON f.id_filiere     = s.id_filiere
JOIN ENSEIGNANT ens ON ens.id_enseignant = m.id_enseignant
LEFT JOIN INSCRIPTION_PED ip ON ip.id_module     = m.id_module
LEFT JOIN INSCRIPTION_ADM ia ON ia.id_insc_adm   = ip.id_insc_adm
LEFT JOIN ANNEE_UNIV      a  ON a.id_annee       = ia.id_annee
LEFT JOIN NOTE            n  ON n.id_insc_ped    = ip.id_insc_ped
GROUP BY m.code_module, m.libelle, f.code_filiere, s.libelle,
         a.libelle, ens.nom, ens.prenom;

-- ============================================================
-- PARTIE D : TESTS
-- Un SELECT par vue pour verifier qu'elles renvoient du coherent.
-- ============================================================

PROMPT ====================================================
PROMPT  TEST 1 : V_ETUDIANT_MODULE_NOTE
PROMPT  Tableau de bord complet (toutes inscriptions pedagogiques)
PROMPT ====================================================
SELECT cne, nom_etudiant, code_filiere, libelle_semestre,
       code_module, note_finale, etat_module
  FROM V_ETUDIANT_MODULE_NOTE
 ORDER BY annee_univ DESC, cne, numero_semestre, code_module;

PROMPT ====================================================
PROMPT  TEST 2 : V_RELEVE_NOTES (releve de E001 - annee 2024-2025)
PROMPT ====================================================
SELECT *
  FROM V_RELEVE_NOTES
 WHERE cne = 'E001' AND annee = '2024-2025'
 ORDER BY semestre, code;

PROMPT ====================================================
PROMPT  TEST 3 : V_MOYENNES_SEMESTRE (toutes les moyennes)
PROMPT ====================================================
SELECT cne, nom_etudiant, filiere, annee, libelle_semestre,
       nb_modules, nb_notes, moyenne_ponderee, etat_semestre
  FROM V_MOYENNES_SEMESTRE
 ORDER BY annee DESC, cne, numero_semestre;

PROMPT ====================================================
PROMPT  TEST 4 : V_VALIDATION_ANNEE (synthese annuelle)
PROMPT ====================================================
SELECT cne, nom_etudiant, filiere, annee,
       moyenne_s1, etat_s1,
       moyenne_s2, etat_s2,
       moyenne_annuelle, etat_annee
  FROM V_VALIDATION_ANNEE
 ORDER BY annee DESC, cne;

PROMPT ====================================================
PROMPT  TEST 5 : V_STATS_FILIERE
PROMPT ====================================================
SELECT filiere, annee, nb_etudiants, nb_modules, nb_notes_saisies,
       moyenne_generale, note_min, note_max,
       nb_valides, nb_non_valides, taux_reussite
  FROM V_STATS_FILIERE
 ORDER BY annee DESC, filiere;

PROMPT ====================================================
PROMPT  TEST 6 : V_STATS_MODULE (statistiques par module)
PROMPT ====================================================
SELECT code_module, libelle_module, filiere, semestre, annee,
       enseignant, nb_inscrits, nb_notes,
       moyenne, note_min, note_max, nb_valides, taux_reussite
  FROM V_STATS_MODULE
 ORDER BY filiere, semestre, code_module;

-- Verification finale
DECLARE
    v_nb_vues NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_nb_vues
      FROM user_views
     WHERE view_name IN (
         'V_ETUDIANT_MODULE_NOTE', 'V_RELEVE_NOTES',
         'V_MOYENNES_SEMESTRE',   'V_VALIDATION_ANNEE',
         'V_STATS_FILIERE',       'V_STATS_MODULE'
     );

    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  VUES CREEES AVEC SUCCES');
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('  Vues du projet : ' || v_nb_vues || ' / 6');
    DBMS_OUTPUT.PUT_LINE('====================================================');
END;
/

-- FIN DU SCRIPT 03 ------------------------------------------------------------

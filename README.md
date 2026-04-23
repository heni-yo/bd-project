# Projet SMI1002 — Gestion de Scolarité Universitaire

Projet de base de données relationnelle Oracle avec interface Java Swing.

## Objectif

Concevoir et réaliser une base de données relationnelle pour gérer la scolarité
d'une faculté : étudiants, filières, modules, inscriptions, notes, calcul de
moyennes et validation d'année.

## Structure du projet

```
bd project/
├── README.md                   ← ce fichier
├── install_all.sql             ← lance les 7 scripts dans l'ordre
├── 01_creation_schema.sql      ← tables, sequences, triggers PK, index
├── 02_donnees_test.sql         ← jeu de données cohérent
├── 03_vues.sql                 ← 6 vues (presentation, analyse, stats)
├── 04_procedures.sql           ← package PKG_SCOLARITE
├── 05_journalisation.sql       ← triggers d'audit vers JOURNAL
├── 06_transactions.sql         ← démos transactions + concurrence
├── 07_optimisation.sql         ← plans d'exécution + snapshots CTAS
└── interface/                  ← application Java Swing + JDBC
    ├── README.md               ← instructions spécifiques à l'interface
    ├── config.properties       ← URL, user, password Oracle
    ├── compile.bat / .sh       ← compilation
    ├── run.bat     / .sh       ← lancement
    ├── lib/ojdbc8.jar          ← driver JDBC Oracle (à télécharger)
    └── src/scolarite/          ← code source Java
```

## Installation de la base de données

### Pré-requis
- Oracle Database accessible (18c, 19c ou 21c testés)
- Oracle SQL Developer
- Un schéma Oracle (par exemple `scolarite`) avec les droits de création
  de tables, séquences, triggers, packages, vues

### Exécution
1. Ouvrir SQL Developer et se connecter au schéma.
2. Ouvrir le fichier `install_all.sql`.
3. Appuyer sur **F5** (Run Script).

Le script exécute les 7 scripts dans l'ordre. À la fin, la base contient :

| Objet | Nombre |
|---|---|
| Tables | 11 |
| Séquences | 9 |
| Triggers (PK + audit) | 13 |
| Index secondaires | 11 |
| Vues | 6 |
| Packages | 1 (`PKG_SCOLARITE`) |
| Procédures | 4 + fonctions |

### Vérification rapide
```sql
SELECT COUNT(*) FROM ETUDIANT;               -- doit retourner 6
SELECT COUNT(*) FROM NOTE;                   -- doit retourner 9
SELECT PKG_SCOLARITE.FUNC_VALIDER_ANNEE('E001', '2024-2025') FROM DUAL;
-- doit retourner VALIDE
```

## Lancement de l'interface Java

Voir `interface/README.md` pour les détails. Résumé rapide :

1. Placer `ojdbc8.jar` dans `interface/lib/`
2. Éditer `interface/config.properties` (URL, user, password)
3. Compiler : `interface/compile.bat`
4. Lancer : `interface/run.bat`

## Identifiants de test

### Étudiants présents dans le jeu de test
| CNE | Nom | Filière | Année | Cas |
|---|---|---|---|---|
| E001 | ALAMI Youssef | SMI | 2024-2025, 2025-2026 | année validée |
| E002 | BENNANI Sara | SMI | 2025-2026 | notes partielles |
| E003 | CHAKIR Ahmed | SMA | 2025-2026 | 1 note |
| E004 | DAOUDI Imane | SMI | 2025-2026 | 1 note |
| E005 | EL FASSI Omar | SMA | 2025-2026 | aucune note |
| E006 | FILALI Nora | SMI | 2025-2026 | aucune note |

### Modules utilisables
| Code | Filière | Semestre |
|---|---|---|
| SMI1001 | SMI | S1 (Algo 1) |
| SMI1002 | SMI | S1 (BD 1) |
| SMI1003 | SMI | S1 (Anglais) |
| SMI2001 | SMI | S2 (Algo 2) |
| SMI2002 | SMI | S2 (BD 2) |
| SMA1001 | SMA | S1 (Analyse 1) |
| SMA1002 | SMA | S1 (Algèbre 1) |

## Exigences du cours couvertes

| Exigence | Script / fichier |
|---|---|
| Conception complète | MCD/MLD dans le rapport |
| Modèle Entité-Relation | Rapport |
| Règles de gestion | Rapport |
| Implémentation Oracle (SQL Developer) | 01..07 |
| Tables, clés primaires, clés étrangères, contraintes | 01 |
| Procédures stockées | 04 (package PKG_SCOLARITE) |
| Vues | 03 (6 vues) |
| Packages | 04 (PKG_SCOLARITE) |
| Séquences | 01 (9 séquences) |
| Optimisation de requêtes | 07 (EXPLAIN PLAN + hints) |
| Gestion des transactions | 06 (COMMIT / ROLLBACK / SAVEPOINT) |
| Gestion de la concurrence | 06 (SELECT ... FOR UPDATE) |
| Journalisation des transactions | 05 (triggers d'audit) |
| Récupération des données | 07 (CTAS snapshots + rappel REDO/UNDO) |
| Petite interface simple | `interface/` (Java Swing) |
| Exécution sur machine universitaire | Oracle + JDK 8+ |

## Auteur

Projet réalisé dans le cadre du cours SMI1002.

-- Script maitre : lance les 7 scripts du projet dans l'ordre.
-- Ouvrir dans SQL Developer et appuyer sur F5.

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET FEEDBACK ON;
SET DEFINE OFF;

PROMPT ====================================================
PROMPT  [1/7] Creation du schema
PROMPT ====================================================
@@01_creation_schema.sql

PROMPT ====================================================
PROMPT  [2/7] Chargement des donnees de test
PROMPT ====================================================
@@02_donnees_test.sql

PROMPT ====================================================
PROMPT  [3/7] Creation des vues
PROMPT ====================================================
@@03_vues.sql

PROMPT ====================================================
PROMPT  [4/7] Creation du package PKG_SCOLARITE
PROMPT ====================================================
@@04_procedures.sql

PROMPT ====================================================
PROMPT  [5/7] Creation des triggers de journalisation
PROMPT ====================================================
@@05_journalisation.sql

PROMPT ====================================================
PROMPT  [6/7] Demos transactions + concurrence
PROMPT ====================================================
@@06_transactions.sql

PROMPT ====================================================
PROMPT  [7/7] Optimisation et snapshots CTAS
PROMPT ====================================================
@@07_optimisation.sql

PROMPT ====================================================
PROMPT  INSTALLATION COMPLETE
PROMPT ====================================================

BEGIN
    DBMS_OUTPUT.PUT_LINE('  Tous les scripts ont ete executes.');
    DBMS_OUTPUT.PUT_LINE('  Base prete pour la demo et l''interface Java.');
END;
/

@echo off
REM Compilation de l'application Java Swing
REM Sortie : dossier out/

if not exist out mkdir out

javac -d out -cp "lib\ojdbc8.jar" ^
    src\scolarite\Main.java ^
    src\scolarite\db\DatabaseConfig.java ^
    src\scolarite\db\DatabaseConnection.java ^
    src\scolarite\dao\ScolariteDAO.java ^
    src\scolarite\ui\MenuPrincipal.java ^
    src\scolarite\ui\FormInscrireAdm.java ^
    src\scolarite\ui\FormInscrirePed.java ^
    src\scolarite\ui\FormSaisirNote.java ^
    src\scolarite\ui\FormReleveNotes.java ^
    src\scolarite\ui\FormMoyennes.java

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Compilation reussie. Lancer avec : run.bat
) else (
    echo.
    echo Echec de la compilation. Voir les erreurs ci-dessus.
)

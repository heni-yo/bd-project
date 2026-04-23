#!/bin/bash
# Compilation de l'application Java Swing
# Sortie : dossier out/

mkdir -p out

javac -d out -cp "lib/ojdbc8.jar" \
    src/scolarite/Main.java \
    src/scolarite/db/DatabaseConfig.java \
    src/scolarite/db/DatabaseConnection.java \
    src/scolarite/dao/ScolariteDAO.java \
    src/scolarite/ui/MenuPrincipal.java \
    src/scolarite/ui/FormInscrireAdm.java \
    src/scolarite/ui/FormInscrirePed.java \
    src/scolarite/ui/FormSaisirNote.java \
    src/scolarite/ui/FormReleveNotes.java \
    src/scolarite/ui/FormMoyennes.java

if [ $? -eq 0 ]; then
    echo ""
    echo "Compilation reussie. Lancer avec : ./run.sh"
else
    echo ""
    echo "Echec de la compilation. Voir les erreurs ci-dessus."
fi

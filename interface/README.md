# Interface Java Swing - Gestion de Scolarité

Application Java Swing minimaliste pour démontrer l'utilisation des
procédures et vues du package `PKG_SCOLARITE` via JDBC.

## Pré-requis

- Java 8 ou supérieur (`java -version` pour vérifier)
- Oracle Database accessible (base où les scripts 01 à 07 ont été exécutés)
- Driver JDBC Oracle : `ojdbc8.jar` à placer dans le dossier `lib/`

### Télécharger ojdbc8.jar

1. Aller sur : https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html
2. Choisir "Oracle Database 19c" ou supérieur
3. Télécharger `ojdbc8.jar` (accepter la licence Oracle, gratuite)
4. Copier le fichier dans `interface/lib/ojdbc8.jar`

## Configuration

Éditer le fichier `config.properties` :

```
db.url=jdbc:oracle:thin:@localhost:1521:XE
db.user=scolarite
db.password=scolarite
```

Adapter `host:port:SID` selon votre installation Oracle.

## Compilation

### Windows

```
compile.bat
```

ou manuellement :

```
javac -d out -cp "lib/ojdbc8.jar" src/scolarite/Main.java src/scolarite/db/*.java src/scolarite/dao/*.java src/scolarite/ui/*.java
```

### Linux / macOS

```
./compile.sh
```

ou manuellement :

```
javac -d out -cp "lib/ojdbc8.jar" src/scolarite/Main.java src/scolarite/db/*.java src/scolarite/dao/*.java src/scolarite/ui/*.java
```

## Lancement

### Windows

```
run.bat
```

### Linux / macOS

```
./run.sh
```

## Fonctionnalités

Le menu principal propose 5 actions :

1. **Inscription administrative** -> `PKG_SCOLARITE.PROC_INSCRIRE_ETUDIANT`
2. **Inscription pédagogique** -> `PKG_SCOLARITE.PROC_INSCRIRE_PEDAGOGIQUE`
3. **Saisie de note** -> `PKG_SCOLARITE.PROC_SAISIR_NOTE`
4. **Relevé de notes** -> vue `V_RELEVE_NOTES`
5. **Consulter moyennes** -> `PKG_SCOLARITE.FUNC_MOYENNE_SEMESTRE`
   et `PKG_SCOLARITE.FUNC_VALIDER_ANNEE`

## Structure du projet

```
interface/
├── README.md
├── config.properties
├── compile.bat / compile.sh
├── run.bat     / run.sh
├── lib/
│   └── ojdbc8.jar
└── src/scolarite/
    ├── Main.java
    ├── db/
    │   ├── DatabaseConfig.java
    │   └── DatabaseConnection.java
    ├── dao/
    │   └── ScolariteDAO.java
    └── ui/
        ├── MenuPrincipal.java
        ├── FormInscrireAdm.java
        ├── FormInscrirePed.java
        ├── FormSaisirNote.java
        ├── FormReleveNotes.java
        └── FormMoyennes.java
```

## Dépannage

| Erreur | Cause probable | Solution |
|---|---|---|
| `ClassNotFoundException: oracle.jdbc.OracleDriver` | `ojdbc8.jar` manquant | Le placer dans `lib/` |
| `ORA-01017: invalid username/password` | Mauvais identifiants | Corriger `config.properties` |
| `IO Error: The Network Adapter could not establish the connection` | Oracle non démarré ou mauvais port | Vérifier que Oracle tourne, vérifier `db.url` |
| `ORA-00942: table or view does not exist` | Scripts SQL 01 à 07 non exécutés | Les exécuter d'abord dans SQL Developer |

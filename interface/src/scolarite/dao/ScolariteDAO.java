package scolarite.dao;

import scolarite.db.DatabaseConnection;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

/**
 * Point d'acces aux donnees : appels au package PKG_SCOLARITE
 * et aux vues utilisees par l'interface.
 */
public class ScolariteDAO {

    // ---------- Procedures (PKG_SCOLARITE) ----------

    public void inscrireEtudiant(String cne, String codeFiliere,
                                 String anneeLibelle, int anneeEtude)
            throws SQLException {
        String sql = "{ call PKG_SCOLARITE.PROC_INSCRIRE_ETUDIANT(?, ?, ?, ?) }";
        try (Connection c  = DatabaseConnection.getConnection();
             CallableStatement cs = c.prepareCall(sql)) {
            cs.setString(1, cne);
            cs.setString(2, codeFiliere);
            cs.setString(3, anneeLibelle);
            cs.setInt   (4, anneeEtude);
            cs.execute();
        }
    }

    public void inscrirePedagogique(String cne, String anneeLibelle,
                                    String codeModule) throws SQLException {
        String sql = "{ call PKG_SCOLARITE.PROC_INSCRIRE_PEDAGOGIQUE(?, ?, ?) }";
        try (Connection c  = DatabaseConnection.getConnection();
             CallableStatement cs = c.prepareCall(sql)) {
            cs.setString(1, cne);
            cs.setString(2, anneeLibelle);
            cs.setString(3, codeModule);
            cs.execute();
        }
    }

    public void saisirNote(String cne, String anneeLibelle, String codeModule,
                           double noteExamen, double noteCC,
                           String sessionType) throws SQLException {
        String sql = "{ call PKG_SCOLARITE.PROC_SAISIR_NOTE(?, ?, ?, ?, ?, ?, ?) }";
        try (Connection c  = DatabaseConnection.getConnection();
             CallableStatement cs = c.prepareCall(sql)) {
            cs.setString(1, cne);
            cs.setString(2, anneeLibelle);
            cs.setString(3, codeModule);
            cs.setDouble(4, noteExamen);
            cs.setDouble(5, noteCC);
            cs.setString(6, sessionType);
            cs.setInt   (7, 1); // p_valider = 1 par defaut
            cs.execute();
        }
    }

    // ---------- Fonctions (PKG_SCOLARITE) ----------

    /** Moyenne ponderee d'un semestre (null si aucune note). */
    public Double getMoyenneSemestre(String cne, String anneeLibelle,
                                     int numeroSem) throws SQLException {
        String sql = "{ ? = call PKG_SCOLARITE.FUNC_MOYENNE_SEMESTRE(?, ?, ?) }";
        try (Connection c  = DatabaseConnection.getConnection();
             CallableStatement cs = c.prepareCall(sql)) {
            cs.registerOutParameter(1, Types.NUMERIC);
            cs.setString(2, cne);
            cs.setString(3, anneeLibelle);
            cs.setInt   (4, numeroSem);
            cs.execute();
            double v = cs.getDouble(1);
            return cs.wasNull() ? null : v;
        }
    }

    /** Etat de l'annee : VALIDE / NON VALIDE / INCOMPLET. */
    public String getEtatAnnee(String cne, String anneeLibelle)
            throws SQLException {
        String sql = "{ ? = call PKG_SCOLARITE.FUNC_VALIDER_ANNEE(?, ?) }";
        try (Connection c  = DatabaseConnection.getConnection();
             CallableStatement cs = c.prepareCall(sql)) {
            cs.registerOutParameter(1, Types.VARCHAR);
            cs.setString(2, cne);
            cs.setString(3, anneeLibelle);
            cs.execute();
            return cs.getString(1);
        }
    }

    // ---------- Releve de notes (vue V_RELEVE_NOTES) ----------

    /** Une ligne du releve de notes (format d'echange avec la vue). */
    public static class LigneReleve {
        public String semestre;
        public String code;
        public String matiere;
        public Number coef;
        public Number noteExamen;
        public Number noteCC;
        public Number noteFinale;
        public String sessionType;
        public String etat;
    }

    /** Releve d'un etudiant pour une annee, trie par semestre puis module. */
    public List<LigneReleve> getReleveNotes(String cne, String anneeLibelle)
            throws SQLException {
        String sql =
              " SELECT semestre, code, matiere, coef, "
            + "        note_examen, note_cc, note_finale, session_type, etat "
            + "   FROM V_RELEVE_NOTES "
            + "  WHERE cne = ? AND annee = ? "
            + "  ORDER BY semestre, code ";
        List<LigneReleve> result = new ArrayList<>();
        try (Connection c  = DatabaseConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, cne);
            ps.setString(2, anneeLibelle);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LigneReleve l = new LigneReleve();
                    l.semestre    = rs.getString("semestre");
                    l.code        = rs.getString("code");
                    l.matiere     = rs.getString("matiere");
                    l.coef        = (Number) rs.getObject("coef");
                    l.noteExamen  = (Number) rs.getObject("note_examen");
                    l.noteCC      = (Number) rs.getObject("note_cc");
                    l.noteFinale  = (Number) rs.getObject("note_finale");
                    l.sessionType = rs.getString("session_type");
                    l.etat        = rs.getString("etat");
                    result.add(l);
                }
            }
        }
        return result;
    }

    // ---------- Listes pour les ComboBox ----------

    public List<String> getCodesFilieres() throws SQLException {
        return selectSingleColumn(
            "SELECT code_filiere FROM FILIERE ORDER BY code_filiere");
    }

    public List<String> getAnneesUniversitaires() throws SQLException {
        return selectSingleColumn(
            "SELECT libelle FROM ANNEE_UNIV ORDER BY libelle");
    }

    public List<String> getCodesModules() throws SQLException {
        return selectSingleColumn(
            "SELECT code_module FROM MODULE ORDER BY code_module");
    }

    /** Lit une seule colonne texte. */
    private List<String> selectSingleColumn(String sql) throws SQLException {
        List<String> list = new ArrayList<>();
        try (Connection c  = DatabaseConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(rs.getString(1));
            }
        }
        return list;
    }

    // ---------- Traduction des erreurs Oracle ----------

    /** Transforme un code ORA-20xxx en message lisible pour l'utilisateur. */
    public static String traduireErreur(SQLException e) {
        int code = e.getErrorCode();
        switch (code) {
            case 20001: return "Etudiant inconnu (CNE non trouve).";
            case 20002: return "Filiere inconnue.";
            case 20003: return "Annee universitaire inconnue.";
            case 20004: return "Module inconnu.";
            case 20010: return "Cet etudiant est deja inscrit administrativement "
                             + "pour cette annee.";
            case 20011: return "Cet etudiant est deja inscrit a ce module.";
            case 20020: return "Aucune inscription administrative trouvee "
                             + "pour cet etudiant et cette annee.";
            case 20021: return "Inscription administrative inactive.";
            case 20022: return "Aucune inscription pedagogique trouvee "
                             + "(l'etudiant n'est pas inscrit a ce module).";
            case 20030: return "Note invalide (0..20 attendu, ou session "
                             + "non reconnue).";
            case 20040: return "Parametre systeme introuvable.";
            default:
                // On garde seulement la 1re ligne du message Oracle.
                String msg = e.getMessage();
                if (msg != null && msg.contains("\n")) {
                    msg = msg.substring(0, msg.indexOf("\n"));
                }
                return msg != null ? msg : "Erreur Oracle inconnue.";
        }
    }
}

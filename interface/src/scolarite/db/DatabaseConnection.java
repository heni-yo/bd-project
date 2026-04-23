package scolarite.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Ouvre des connexions JDBC Oracle. Chaque appel renvoie une nouvelle
 * connexion, a fermer par l'appelant (try-with-resources).
 */
public class DatabaseConnection {

    static {
        // Chargement explicite du driver (necessaire avec JDK 8).
        try {
            Class.forName("oracle.jdbc.OracleDriver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(
                "Driver Oracle introuvable (ojdbc8.jar manquant ?) : "
                + e.getMessage(), e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(
            DatabaseConfig.getUrl(),
            DatabaseConfig.getUser(),
            DatabaseConfig.getPassword());
    }

    /** Vrai si la base repond avec la config actuelle. */
    public static boolean testConnection() {
        try (Connection c = getConnection()) {
            return c != null && !c.isClosed();
        } catch (SQLException e) {
            System.err.println("Connexion KO : " + e.getMessage());
            return false;
        }
    }
}

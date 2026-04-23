package scolarite.db;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/** Charge la config Oracle depuis config.properties (lecture lazy). */
public class DatabaseConfig {

    private static final String CONFIG_FILE = "config.properties";
    private static Properties properties;

    private static void loadProperties() {
        if (properties != null) {
            return;
        }
        properties = new Properties();
        try (InputStream in = new FileInputStream(CONFIG_FILE)) {
            properties.load(in);
        } catch (IOException e) {
            throw new RuntimeException(
                "Impossible de lire " + CONFIG_FILE + " : " + e.getMessage(), e);
        }
    }

    public static String getUrl() {
        loadProperties();
        return properties.getProperty("db.url");
    }

    public static String getUser() {
        loadProperties();
        return properties.getProperty("db.user");
    }

    public static String getPassword() {
        loadProperties();
        return properties.getProperty("db.password");
    }

    public static String getAnneeDefaut() {
        loadProperties();
        return properties.getProperty("app.annee.defaut", "");
    }
}

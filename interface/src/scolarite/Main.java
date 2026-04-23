package scolarite;

import scolarite.db.DatabaseConfig;
import scolarite.db.DatabaseConnection;
import scolarite.ui.MenuPrincipal;

import javax.swing.JOptionPane;
import javax.swing.SwingUtilities;
import javax.swing.UIManager;

/** Point d'entree : verifie la connexion puis ouvre le menu principal. */
public class Main {

    public static void main(String[] args) {
        // Look & feel systeme (plus joli que le Metal par defaut).
        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        } catch (Exception ignored) { /* on reste sur Metal */ }

        if (!DatabaseConnection.testConnection()) {
            JOptionPane.showMessageDialog(null,
                "Impossible de se connecter a Oracle.\n"
              + "Verifier config.properties :\n"
              + "  URL : " + DatabaseConfig.getUrl() + "\n"
              + "  USER : " + DatabaseConfig.getUser(),
                "Erreur de connexion",
                JOptionPane.ERROR_MESSAGE);
            System.exit(1);
        }

        // Ouverture sur l'Event Dispatch Thread (regle Swing).
        SwingUtilities.invokeLater(() -> new MenuPrincipal().setVisible(true));
    }
}

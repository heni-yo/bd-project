package scolarite.ui;

import scolarite.dao.ScolariteDAO;
import scolarite.db.DatabaseConfig;

import javax.swing.*;
import java.awt.*;

/** Menu principal : 5 boutons, un par action metier. */
public class MenuPrincipal extends JFrame {

    private final ScolariteDAO dao = new ScolariteDAO();

    public MenuPrincipal() {
        super("Gestion de Scolarite Universitaire - SMI1002");
        buildUI();

        setSize(520, 420);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
    }

    private void buildUI() {
        JPanel root = new JPanel(new BorderLayout(10, 10));
        root.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // Titre
        JLabel title = new JLabel("Gestion de Scolarite Universitaire",
                                  SwingConstants.CENTER);
        title.setFont(title.getFont().deriveFont(Font.BOLD, 18f));
        root.add(title, BorderLayout.NORTH);

        // Boutons
        JPanel btns = new JPanel(new GridLayout(5, 1, 0, 12));

        JButton b1 = new JButton("1. Inscription administrative");
        JButton b2 = new JButton("2. Inscription pedagogique");
        JButton b3 = new JButton("3. Saisie de note");
        JButton b4 = new JButton("4. Releve de notes");
        JButton b5 = new JButton("5. Consulter moyennes");

        Font f = b1.getFont().deriveFont(Font.PLAIN, 14f);
        for (JButton b : new JButton[]{b1, b2, b3, b4, b5}) {
            b.setFont(f);
        }

        btns.add(b1); btns.add(b2); btns.add(b3); btns.add(b4); btns.add(b5);
        root.add(btns, BorderLayout.CENTER);

        // Barre d'info + bouton Quitter
        JPanel south = new JPanel(new BorderLayout());
        JLabel info = new JLabel(
            " Connecte sur : " + DatabaseConfig.getUrl()
            + "  |  Utilisateur : " + DatabaseConfig.getUser()
            + "  |  Annee : " + DatabaseConfig.getAnneeDefaut());
        info.setFont(info.getFont().deriveFont(Font.ITALIC, 11f));
        south.add(info, BorderLayout.WEST);

        JButton btnQuit = new JButton("Quitter");
        btnQuit.addActionListener(e -> System.exit(0));
        south.add(btnQuit, BorderLayout.EAST);
        root.add(south, BorderLayout.SOUTH);

        setContentPane(root);

        // Liaison bouton -> formulaire
        b1.addActionListener(e -> new FormInscrireAdm(this, dao).setVisible(true));
        b2.addActionListener(e -> new FormInscrirePed(this, dao).setVisible(true));
        b3.addActionListener(e -> new FormSaisirNote (this, dao).setVisible(true));
        b4.addActionListener(e -> new FormReleveNotes(this, dao).setVisible(true));
        b5.addActionListener(e -> new FormMoyennes   (this, dao).setVisible(true));
    }
}

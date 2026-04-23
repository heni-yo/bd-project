package scolarite.ui;

import scolarite.dao.ScolariteDAO;
import scolarite.dao.ScolariteDAO.LigneReleve;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.SQLException;
import java.util.List;

/** Releve de notes d'un etudiant pour une annee (vue V_RELEVE_NOTES). */
public class FormReleveNotes extends JDialog {

    private final ScolariteDAO dao;

    private JTextField         tfCne;
    private JComboBox<String>  cbAnnee;
    private JLabel             lblMessage;
    private DefaultTableModel  tableModel;
    private JTable             table;

    public FormReleveNotes(Frame owner, ScolariteDAO dao) {
        super(owner, "Releve de notes", true);
        this.dao = dao;
        buildUI();
        chargerListes();
        setSize(780, 480);
        setLocationRelativeTo(owner);
    }

    private void buildUI() {
        JPanel root = new JPanel(new BorderLayout(10, 10));
        root.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));

        // Barre de recherche
        JPanel top = new JPanel(new FlowLayout(FlowLayout.LEFT));
        tfCne   = new JTextField(10);
        cbAnnee = new JComboBox<>();
        JButton btnAfficher = new JButton("Afficher");
        JButton btnFermer   = new JButton("Fermer");

        top.add(new JLabel("CNE :"));
        top.add(tfCne);
        top.add(new JLabel(" Annee :"));
        top.add(cbAnnee);
        top.add(btnAfficher);
        top.add(btnFermer);

        root.add(top, BorderLayout.NORTH);

        // Tableau des resultats
        String[] cols = { "Semestre", "Code", "Matiere", "Coef",
                          "Examen", "CC", "Finale", "Session", "Etat" };
        tableModel = new DefaultTableModel(cols, 0) {
            @Override public boolean isCellEditable(int r, int c) { return false; }
        };
        table = new JTable(tableModel);
        table.setFillsViewportHeight(true);
        root.add(new JScrollPane(table), BorderLayout.CENTER);

        // Zone de message
        lblMessage = new JLabel(" ");
        root.add(lblMessage, BorderLayout.SOUTH);

        setContentPane(root);

        btnAfficher.addActionListener(e -> doAfficher());
        btnFermer.addActionListener  (e -> dispose());
    }

    private void chargerListes() {
        try {
            List<String> annees = dao.getAnneesUniversitaires();
            for (String s : annees) cbAnnee.addItem(s);
        } catch (SQLException e) {
            afficherErreur("Chargement des annees : "
                + ScolariteDAO.traduireErreur(e));
        }
    }

    private void doAfficher() {
        String cne          = tfCne.getText().trim();
        String anneeLibelle = (String) cbAnnee.getSelectedItem();

        tableModel.setRowCount(0);

        if (cne.isEmpty() || anneeLibelle == null) {
            afficherErreur("CNE et annee sont obligatoires.");
            return;
        }

        try {
            List<LigneReleve> lignes = dao.getReleveNotes(cne, anneeLibelle);
            if (lignes.isEmpty()) {
                afficherErreur("Aucune inscription trouvee pour "
                    + cne + " en " + anneeLibelle);
                return;
            }
            for (LigneReleve l : lignes) {
                tableModel.addRow(new Object[] {
                    l.semestre, l.code, l.matiere,
                    format(l.coef),
                    format(l.noteExamen), format(l.noteCC), format(l.noteFinale),
                    l.sessionType, l.etat
                });
            }
            afficherSucces(lignes.size() + " ligne(s) affichee(s) pour "
                + cne + " / " + anneeLibelle);
        } catch (SQLException e) {
            afficherErreur(ScolariteDAO.traduireErreur(e));
        }
    }

    private static String format(Number n) {
        return n == null ? "-" : String.valueOf(n);
    }

    private void afficherSucces(String s) {
        lblMessage.setForeground(new Color(0, 100, 0));
        lblMessage.setText(s);
    }

    private void afficherErreur(String s) {
        lblMessage.setForeground(new Color(170, 0, 0));
        lblMessage.setText(s);
    }
}

package scolarite.ui;

import scolarite.dao.ScolariteDAO;

import javax.swing.*;
import java.awt.*;
import java.sql.SQLException;
import java.util.List;

/**
 * Moyennes et etat de validation d'un etudiant pour une annee.
 * S1 et S2 viennent de FUNC_MOYENNE_SEMESTRE, l'etat de FUNC_VALIDER_ANNEE,
 * la moyenne annuelle est calculee cote interface.
 */
public class FormMoyennes extends JDialog {

    private final ScolariteDAO dao;

    private JTextField        tfCne;
    private JComboBox<String> cbAnnee;
    private JLabel            lblS1, lblS2, lblAnnuelle, lblEtat;
    private JLabel            lblMessage;

    public FormMoyennes(Frame owner, ScolariteDAO dao) {
        super(owner, "Moyennes et validation", true);
        this.dao = dao;
        buildUI();
        chargerListes();
        pack();
        setLocationRelativeTo(owner);
    }

    private void buildUI() {
        JPanel p = new JPanel(new GridBagLayout());
        p.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));
        GridBagConstraints gc = new GridBagConstraints();
        gc.insets = new Insets(5, 5, 5, 5);
        gc.anchor = GridBagConstraints.WEST;

        tfCne       = new JTextField(15);
        cbAnnee     = new JComboBox<>();

        lblS1       = boldLabel("-");
        lblS2       = boldLabel("-");
        lblAnnuelle = boldLabel("-");
        lblEtat     = boldLabel("-");
        lblMessage  = new JLabel(" ");

        int row = 0;
        addRow(p, gc, row++, "CNE etudiant :",        tfCne);
        addRow(p, gc, row++, "Annee universitaire :", cbAnnee);

        gc.gridx = 0; gc.gridy = row++; gc.gridwidth = 2;
        gc.fill  = GridBagConstraints.HORIZONTAL;
        p.add(new JSeparator(), gc);

        addRow(p, gc, row++, "Moyenne S1 :",        lblS1);
        addRow(p, gc, row++, "Moyenne S2 :",        lblS2);
        addRow(p, gc, row++, "Moyenne annuelle :",  lblAnnuelle);
        addRow(p, gc, row++, "Etat de l'annee :",   lblEtat);

        JButton btnOk     = new JButton("Calculer");
        JButton btnCancel = new JButton("Fermer");
        JPanel btns = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        btns.add(btnOk); btns.add(btnCancel);

        gc.gridx = 0; gc.gridy = row++; gc.gridwidth = 2;
        gc.fill  = GridBagConstraints.HORIZONTAL;
        p.add(btns, gc);

        gc.gridy = row++;
        p.add(lblMessage, gc);

        setContentPane(p);

        btnOk.addActionListener(e -> doCalculer());
        btnCancel.addActionListener(e -> dispose());
    }

    private JLabel boldLabel(String txt) {
        JLabel l = new JLabel(txt);
        l.setFont(l.getFont().deriveFont(Font.BOLD, 13f));
        return l;
    }

    private void addRow(JPanel p, GridBagConstraints gc, int row,
                        String label, JComponent comp) {
        gc.gridx = 0; gc.gridy = row; gc.gridwidth = 1;
        gc.fill  = GridBagConstraints.NONE;
        p.add(new JLabel(label), gc);
        gc.gridx = 1;
        gc.fill  = GridBagConstraints.HORIZONTAL;
        p.add(comp, gc);
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

    private void doCalculer() {
        String cne          = tfCne.getText().trim();
        String anneeLibelle = (String) cbAnnee.getSelectedItem();

        if (cne.isEmpty() || anneeLibelle == null) {
            afficherErreur("CNE et annee sont obligatoires.");
            return;
        }

        try {
            Double m1 = dao.getMoyenneSemestre(cne, anneeLibelle, 1);
            Double m2 = dao.getMoyenneSemestre(cne, anneeLibelle, 2);
            String etat = dao.getEtatAnnee(cne, anneeLibelle);

            lblS1.setText(format(m1));
            lblS2.setText(format(m2));

            Double annuelle = null;
            if (m1 != null && m2 != null) {
                annuelle = Math.round(((m1 + m2) / 2.0) * 100.0) / 100.0;
            }
            lblAnnuelle.setText(format(annuelle));

            lblEtat.setText(etat != null ? etat : "INCOMPLET");
            colorerEtat(etat);

            afficherSucces("Calcul effectue pour " + cne + " / " + anneeLibelle);
        } catch (SQLException e) {
            afficherErreur(ScolariteDAO.traduireErreur(e));
        }
    }

    private void colorerEtat(String etat) {
        if (etat == null) {
            lblEtat.setForeground(Color.BLACK);
            return;
        }
        switch (etat) {
            case "VALIDE"     : lblEtat.setForeground(new Color(0, 130, 0)); break;
            case "NON VALIDE" : lblEtat.setForeground(new Color(170, 0, 0)); break;
            default           : lblEtat.setForeground(new Color(180, 90, 0)); // INCOMPLET
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

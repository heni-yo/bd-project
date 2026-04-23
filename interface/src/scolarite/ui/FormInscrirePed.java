package scolarite.ui;

import scolarite.dao.ScolariteDAO;

import javax.swing.*;
import java.awt.*;
import java.sql.SQLException;
import java.util.List;

/** Ecran d'inscription pedagogique (appelle PROC_INSCRIRE_PEDAGOGIQUE). */
public class FormInscrirePed extends JDialog {

    private final ScolariteDAO dao;

    private JTextField        tfCne;
    private JComboBox<String> cbAnnee;
    private JComboBox<String> cbModule;
    private JLabel            lblMessage;

    public FormInscrirePed(Frame owner, ScolariteDAO dao) {
        super(owner, "Inscription pedagogique", true);
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

        tfCne      = new JTextField(15);
        cbAnnee    = new JComboBox<>();
        cbModule   = new JComboBox<>();
        lblMessage = new JLabel(" ");

        int row = 0;
        addRow(p, gc, row++, "CNE etudiant :",        tfCne);
        addRow(p, gc, row++, "Annee universitaire :", cbAnnee);
        addRow(p, gc, row++, "Module :",              cbModule);

        JButton btnOk     = new JButton("Inscrire");
        JButton btnCancel = new JButton("Fermer");
        JPanel btns = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        btns.add(btnOk); btns.add(btnCancel);

        gc.gridx = 0; gc.gridy = row++; gc.gridwidth = 2;
        gc.fill  = GridBagConstraints.HORIZONTAL;
        p.add(btns, gc);

        gc.gridy = row++;
        p.add(lblMessage, gc);

        setContentPane(p);

        btnOk.addActionListener(e -> doInscrire());
        btnCancel.addActionListener(e -> dispose());
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

            List<String> modules = dao.getCodesModules();
            for (String s : modules) cbModule.addItem(s);
        } catch (SQLException e) {
            afficherErreur("Chargement des listes : "
                + ScolariteDAO.traduireErreur(e));
        }
    }

    private void doInscrire() {
        String cne          = tfCne.getText().trim();
        String anneeLibelle = (String) cbAnnee.getSelectedItem();
        String codeModule   = (String) cbModule.getSelectedItem();

        if (cne.isEmpty()) {
            afficherErreur("Le CNE est obligatoire.");
            return;
        }
        if (anneeLibelle == null || codeModule == null) {
            afficherErreur("Annee et module obligatoires.");
            return;
        }

        try {
            dao.inscrirePedagogique(cne, anneeLibelle, codeModule);
            afficherSucces("Inscription reussie : " + cne
                + " -> " + codeModule + " (" + anneeLibelle + ")");
        } catch (SQLException e) {
            afficherErreur(ScolariteDAO.traduireErreur(e));
        }
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

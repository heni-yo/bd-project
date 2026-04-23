package scolarite.ui;

import scolarite.dao.ScolariteDAO;

import javax.swing.*;
import java.awt.*;
import java.sql.SQLException;
import java.util.List;

/** Ecran d'inscription administrative (appelle PROC_INSCRIRE_ETUDIANT). */
public class FormInscrireAdm extends JDialog {

    private final ScolariteDAO dao;

    private JTextField           tfCne;
    private JComboBox<String>    cbFiliere;
    private JComboBox<String>    cbAnnee;
    private JSpinner             spAnneeEtude;
    private JLabel               lblMessage;

    public FormInscrireAdm(Frame owner, ScolariteDAO dao) {
        super(owner, "Inscription administrative", true);
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

        tfCne        = new JTextField(15);
        cbFiliere    = new JComboBox<>();
        cbAnnee      = new JComboBox<>();
        spAnneeEtude = new JSpinner(new SpinnerNumberModel(1, 1, 5, 1));
        lblMessage   = new JLabel(" ");
        lblMessage.setForeground(new Color(0, 100, 0));

        int row = 0;
        addRow(p, gc, row++, "CNE etudiant :",        tfCne);
        addRow(p, gc, row++, "Filiere :",             cbFiliere);
        addRow(p, gc, row++, "Annee universitaire :", cbAnnee);
        addRow(p, gc, row++, "Annee d'etude :",       spAnneeEtude);

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
            List<String> filieres = dao.getCodesFilieres();
            for (String s : filieres) cbFiliere.addItem(s);

            List<String> annees = dao.getAnneesUniversitaires();
            for (String s : annees) cbAnnee.addItem(s);
        } catch (SQLException e) {
            afficherErreur("Chargement des listes : "
                + ScolariteDAO.traduireErreur(e));
        }
    }

    private void doInscrire() {
        String cne          = tfCne.getText().trim();
        String codeFiliere  = (String) cbFiliere.getSelectedItem();
        String anneeLibelle = (String) cbAnnee.getSelectedItem();
        int    anneeEtude   = (Integer) spAnneeEtude.getValue();

        if (cne.isEmpty()) {
            afficherErreur("Le CNE est obligatoire.");
            return;
        }
        if (codeFiliere == null || anneeLibelle == null) {
            afficherErreur("Filiere et annee obligatoires.");
            return;
        }

        try {
            dao.inscrireEtudiant(cne, codeFiliere, anneeLibelle, anneeEtude);
            afficherSucces("Inscription reussie : " + cne
                + " -> " + codeFiliere + " / " + anneeLibelle);
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

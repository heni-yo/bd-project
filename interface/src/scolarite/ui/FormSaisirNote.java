package scolarite.ui;

import scolarite.dao.ScolariteDAO;

import javax.swing.*;
import java.awt.*;
import java.sql.SQLException;
import java.util.List;

/** Ecran de saisie de note (appelle PROC_SAISIR_NOTE). */
public class FormSaisirNote extends JDialog {

    private final ScolariteDAO dao;

    private JTextField        tfCne;
    private JComboBox<String> cbAnnee;
    private JComboBox<String> cbModule;
    private JTextField        tfExamen;
    private JTextField        tfCC;
    private JComboBox<String> cbSession;
    private JLabel            lblMessage;

    public FormSaisirNote(Frame owner, ScolariteDAO dao) {
        super(owner, "Saisie de note", true);
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
        tfExamen   = new JTextField(5);
        tfCC       = new JTextField(5);
        cbSession  = new JComboBox<>(new String[]{"NORMALE", "RATTRAPAGE"});
        lblMessage = new JLabel(" ");

        int row = 0;
        addRow(p, gc, row++, "CNE etudiant :",        tfCne);
        addRow(p, gc, row++, "Annee universitaire :", cbAnnee);
        addRow(p, gc, row++, "Module :",              cbModule);
        addRow(p, gc, row++, "Note examen (0..20) :", tfExamen);
        addRow(p, gc, row++, "Note CC (0..20) :",     tfCC);
        addRow(p, gc, row++, "Session :",             cbSession);

        JButton btnOk     = new JButton("Enregistrer");
        JButton btnCancel = new JButton("Fermer");
        JPanel btns = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        btns.add(btnOk); btns.add(btnCancel);

        gc.gridx = 0; gc.gridy = row++; gc.gridwidth = 2;
        gc.fill  = GridBagConstraints.HORIZONTAL;
        p.add(btns, gc);

        gc.gridy = row++;
        p.add(lblMessage, gc);

        setContentPane(p);

        btnOk.addActionListener(e -> doSaisir());
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

    private void doSaisir() {
        String cne          = tfCne.getText().trim();
        String anneeLibelle = (String) cbAnnee.getSelectedItem();
        String codeModule   = (String) cbModule.getSelectedItem();
        String sessionType  = (String) cbSession.getSelectedItem();

        if (cne.isEmpty() || anneeLibelle == null || codeModule == null) {
            afficherErreur("CNE, annee et module sont obligatoires.");
            return;
        }

        double examen, cc;
        try {
            examen = Double.parseDouble(tfExamen.getText().trim().replace(",", "."));
            cc     = Double.parseDouble(tfCC.getText().trim().replace(",", "."));
        } catch (NumberFormatException ex) {
            afficherErreur("Les notes doivent etre numeriques (ex: 13,5).");
            return;
        }

        if (examen < 0 || examen > 20 || cc < 0 || cc > 20) {
            afficherErreur("Les notes doivent etre comprises entre 0 et 20.");
            return;
        }

        try {
            dao.saisirNote(cne, anneeLibelle, codeModule, examen, cc, sessionType);
            afficherSucces("Note enregistree avec succes pour "
                + cne + " / " + codeModule);
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

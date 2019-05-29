import oracle.sql.ARRAY;

import javax.swing.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

public class CharacterSelectForm extends JFrame {

    private CharacterSelectController characterSelectController;
    private JPanel panel;
    private JTable jTable;
    private JScrollPane jScrollPanel;
    private JButton friendsButton;
    private JButton selectButton;
    private JButton deleteButton;
    private JButton restoreButton;

    public CharacterSelectForm(CharacterSelectController characterSelectController) {
        this.characterSelectController = characterSelectController;
        setTitle("Character Select");
        setSize(1600, 800);

        add(panel);

        deleteButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if (jTable.getSelectedRow() != -1) {
                    characterSelectController.deleteCharacter
                            (Integer.parseInt(jTable.getValueAt(jTable.getSelectedRow(), 0).toString()));
                }
            }
        });
        restoreButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if (jTable.getSelectedRow() != -1) {
                    characterSelectController.restoreCharacter
                            (Integer.parseInt(jTable.getValueAt(jTable.getSelectedRow(), 0).toString()));
                }
            }
        });
        selectButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if (jTable.getSelectedRow() != -1) {
                    characterSelectController.loadCharacerScene
                            (Integer.parseInt(jTable.getValueAt(jTable.getSelectedRow(), 0).toString()));
                }
            }
        });
        friendsButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                characterSelectController.loadFriendsScene();
            }
        });
    }

    public void reload_table() {
        String[] jTableColumnNames = {"ID", "NAME", "LEVEL", "Days until deleted"};
        ARRAY array = characterSelectController.loadCharacters();
        jTable = UtilsForms.loadJTable(jTable, array, jTableColumnNames, true);
    }

    private void createUIComponents() {
        String[] jTableColumnNames = {"ID", "NAME", "LEVEL", "Days until deleted"};
        ARRAY array = characterSelectController.loadCharacters();
        jTable = UtilsForms.loadJTable(jTable, array, jTableColumnNames, false);
    }
}

import oracle.sql.ARRAY;

import javax.swing.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

public class BattleForm extends JFrame {
    private JTextArea text;
    private JTable characterJTable;
    private JTable friendJTable;
    private JButton backButton;
    private JButton battleButton;
    private JPanel panel;
    private BattleController battleController;

    BattleForm(BattleController battleController){
        this.battleController = battleController;
        setTitle("Battle");
        setSize(1600,800);

        text.setEditable(false);
        add(panel);
        backButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                battleController.loadFriendsScene();
            }
        });
        battleButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if(characterJTable.getSelectedRow()!= -1 && friendJTable.getSelectedRow()!= -1) {
                    text.setText(battleController.battle
                            (Integer.parseInt(characterJTable.getValueAt(characterJTable.getSelectedRow(),0).toString()),
                             Integer.parseInt(friendJTable.getValueAt(friendJTable.getSelectedRow(),0).toString())));
                }
            }
        });
    }

    public void reload_table(){
        String[] jTableColumnNames = {"ID", "NAME", "LEVEL","Days until deleted"};
        ARRAY array = battleController.loadCharacters(false);
        characterJTable = UtilsForms.loadJTable(characterJTable, array, jTableColumnNames,true);
        array = battleController.loadCharacters(true);
        friendJTable = UtilsForms.loadJTable(friendJTable, array, jTableColumnNames,true);
        modify_table_aspect(characterJTable);
        modify_table_aspect(friendJTable);
    }

    private void createUIComponents() {
        String[] jTableColumnNames = {"ID", "NAME", "LEVEL","Days until deleted"};
        ARRAY array = battleController.loadCharacters(false);
        characterJTable = UtilsForms.loadJTable(characterJTable, array, jTableColumnNames,false);
        array = battleController.loadCharacters(true);
        friendJTable = UtilsForms.loadJTable(friendJTable, array, jTableColumnNames,false);
        modify_table_aspect(characterJTable);
        modify_table_aspect(friendJTable);
    }

    private void modify_table_aspect(JTable jTable){
        jTable.getColumnModel().getColumn(3).setPreferredWidth(0);
    }
}

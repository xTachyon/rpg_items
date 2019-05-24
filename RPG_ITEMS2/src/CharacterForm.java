import oracle.sql.ARRAY;

import javax.swing.*;
import javax.swing.table.TableCellRenderer;
import javax.swing.table.TableColumn;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

public class CharacterForm extends JFrame{
    private JTable itemsJTable;
    private JTable equipedItemsJTable;
    private JButton backButton;
    private JButton equipButton;
    private JButton buyButton;
    private JButton updateButton;
    private JButton sellButton;
    private JButton compareItemsButton;
    private JScrollPane inventoryScrollPanel;
    private JPanel statsPanel;
    private JScrollPane equipedItemsScrollPanel;
    private JPanel panel;
    private JTextField buyRarityTExtField;
    private JTextArea statsTextArea;
    private JScrollPane statsJScrollPanel;

    private CharacterController characterController;

    CharacterForm(CharacterController characterController){
        this.characterController = characterController;
        setTitle("Character");
        setSize(1600,800);

        add(panel);
        statsTextArea.setText(characterController.loadCharacterStats());

        backButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                characterController.loadCharacterSelectScene();
            }
        });
        equipButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if(itemsJTable.getSelectedRow()!= -1) {
                    characterController.equip
                            (Integer.parseInt(itemsJTable.getValueAt(itemsJTable.getSelectedRow(),0).toString()));
                }
            }
        });

        sellButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if(itemsJTable.getSelectedRow()!= -1) {
                    characterController.sell
                            (Integer.parseInt(itemsJTable.getValueAt(itemsJTable.getSelectedRow(),0).toString()));
                }
            }
        });

        updateButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if(itemsJTable.getSelectedRow()!= -1) {
                    characterController.update
                            (Integer.parseInt(itemsJTable.getValueAt(itemsJTable.getSelectedRow(),0).toString()));
                }
            }
        });

        buyButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if(buyRarityTExtField.getText() != null){
                    characterController.buy(buyRarityTExtField.getText());
                }
            }
        });

        compareItemsButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                characterController.compare();
            }
        });
    }


    public void reload_tables(){
        String[] jTableColumnNames = {"ID", "LEVEL", "DURABILITY","EXPIRATION DATE","NAME","RARITY","MAGIC","STATS"};
        ARRAY array = characterController.loadItems();
        itemsJTable = UtilsForms.loadJTable(itemsJTable, array, jTableColumnNames,true);
        modify_table_aspect(itemsJTable);
        array = characterController.loadEquipedItems();
        equipedItemsJTable = UtilsForms.loadJTable(equipedItemsJTable, array, jTableColumnNames,true);
        modify_table_aspect(equipedItemsJTable);
        statsTextArea.setText(characterController.loadCharacterStats());
    }

    private void createUIComponents() {
        String[] jTableColumnNames = {"ID", "LEVEL", "DURABILITY","EXPIRATION DATE","NAME","RARITY","MAGIC","STATS"};
        ARRAY array = characterController.loadItems();
        itemsJTable = UtilsForms.loadJTable(itemsJTable, array, jTableColumnNames,false);
        modify_table_aspect(itemsJTable);
        array = characterController.loadEquipedItems();
        equipedItemsJTable = UtilsForms.loadJTable(equipedItemsJTable, array, jTableColumnNames,false);
        modify_table_aspect(equipedItemsJTable);
        statsTextArea = new JTextArea(30,30);
        statsTextArea.setEditable(false);
    }

    private void modify_table_aspect(JTable jTable){
        for (int column = 0; column < jTable.getColumnCount(); column++)
        {
            TableColumn tableColumn = jTable.getColumnModel().getColumn(column);
            int preferredWidth = tableColumn.getMinWidth();
            int maxWidth = tableColumn.getMaxWidth();

            for (int row = 0; row < jTable.getRowCount(); row++)
            {
                TableCellRenderer cellRenderer = jTable.getCellRenderer(row, column);
                Component c = jTable.prepareRenderer(cellRenderer, row, column);
                int width = c.getPreferredSize().width + jTable.getIntercellSpacing().width;
                preferredWidth = Math.max(preferredWidth, width);
                if (preferredWidth >= maxWidth)
                {
                    preferredWidth = maxWidth;
                    break;
                }
            }

            tableColumn.setPreferredWidth( preferredWidth );
        }
    }
}

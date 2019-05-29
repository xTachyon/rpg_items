import oracle.sql.ARRAY;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.sql.SQLException;
import java.sql.Struct;

public class UtilsForms {
    public static JTable loadJTable(JTable myJTable, ARRAY array, String[] jTableColumnNames, boolean reload) {
        String[][] jTableData;
        try {
            Object[] list = (Object[]) array.getArray();
            if (list.length == 0) {
                jTableData = new String[1][jTableColumnNames.length];
                jTableData[0] = jTableColumnNames;
            } else {
                jTableData = new String[list.length][((Struct) list[0]).getAttributes().length];
                for (int i = 0; i < list.length; ++i) {
                    Struct row = (Struct) list[i];
                    Object[] cols = row.getAttributes();
                    for (int j = 0; j < cols.length; ++j) {
                        if (cols[j] != null) {
                            jTableData[i][j] = cols[j].toString();
                        } else {
                            jTableData[i][j] = "";
                        }
                    }
                }
            }

            if (reload) {
                myJTable.setModel(new DefaultTableModel(jTableData, jTableColumnNames) {
                    @Override
                    public boolean isCellEditable(int row, int column) {
                        return false;
                    }
                });
            } else {
                myJTable = new JTable(new DefaultTableModel(jTableData, jTableColumnNames) {
                    @Override
                    public boolean isCellEditable(int row, int column) {
                        return false;
                    }
                });
            }
        } catch (SQLException e) {
            System.err.println(e);
        }
        return myJTable;
    }
}

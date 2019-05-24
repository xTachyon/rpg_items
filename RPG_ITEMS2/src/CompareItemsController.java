import oracle.jdbc.OracleCallableStatement;

import javax.swing.*;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

public class CompareItemsController extends Controller{
    private int characterId;

    CompareItemsController(int characterId){
        this.characterId = characterId;
    }

    public String compareItems(int item_id1, int item_id2) {
        String output="";
        try{
            CallableStatement cstmt = connection.prepareCall("{? = call rpg_character.compare_items(?,?,?)}");
            cstmt.registerOutParameter(1, Types.VARCHAR);
            cstmt.setInt(2,item_id1);
            cstmt.setInt(3,item_id2);
            cstmt.setInt(4,characterId);
            cstmt.execute();
            output = cstmt.getString(1);
        }
        catch (SQLException e){
            if(e.getErrorCode() > 20000){
                JOptionPane.showMessageDialog(null,e.getMessage());
            }
            else{
                System.err.println(e);
            }
        }
        return output;
    }
}

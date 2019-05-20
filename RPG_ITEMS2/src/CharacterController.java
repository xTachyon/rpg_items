import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import oracle.sql.ARRAY;

import javax.swing.*;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class CharacterController extends Controller {
    private int userId;
    private int characterId;

    CharacterController(int userId, int characterId){
        this.userId = userId;
        this.characterId = characterId;
    }

    public void loadCharacterSelectScene() {
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                CharacterSelectController characterSelect = new CharacterSelectController(userId);
                CharacterSelectForm characterSelectForm = new CharacterSelectForm(characterSelect);
                characterSelect.setForm(characterSelectForm);
                characterSelectForm.setVisible(true);
                characterSelectForm.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            }
        });
        getForm().dispose();
    }

    public ARRAY loadItems(){
        try{
            OracleCallableStatement ocstmt = (OracleCallableStatement) connection.prepareCall("{ call get_items(?,?,?) }");
            ocstmt.setInt(1, characterId);
            ocstmt.registerOutParameter(2, OracleTypes.ARRAY,"ITEM_LIST");
            ocstmt.setInt(3,0);
            ocstmt.execute();
            ARRAY array = (ARRAY) ocstmt.getArray(2);
            return array;
        }
        catch (SQLException e){
            if(e.getErrorCode() > 20000){
                JOptionPane.showMessageDialog(null,e.getMessage());
            }
            else{
                System.err.println(e);
            }
        }
        return null;
    }

    public ARRAY loadEquipedItems(){
        try{
            OracleCallableStatement ocstmt = (OracleCallableStatement) connection.prepareCall("{ call get_items(?,?,?) }");
            ocstmt.setInt(1, characterId);
            ocstmt.registerOutParameter(2,OracleTypes.ARRAY,"ITEM_LIST");
            ocstmt.setInt(3,1);
            ocstmt.execute();
            ARRAY array = (ARRAY) ocstmt.getArray(2);
            return array;
        }
        catch (SQLException e){
            if(e.getErrorCode() > 20000){
                JOptionPane.showMessageDialog(null,e.getMessage());
            }
            else{
                System.err.println(e);
            }
        }
        return null;
    }

    public void equip(int itemId) {
        try{
            PreparedStatement pstmt = connection.prepareCall("begin equip_item(?,?); end;");
            pstmt.setInt(1,characterId);
            pstmt.setInt(2,itemId);
            pstmt.execute();
            connection.commit();
        }
        catch (SQLException e){
            if(e.getErrorCode() > 20000){
                JOptionPane.showMessageDialog(null,e.getMessage());
            }
            else{
                System.err.println(e);
            }
        }
        ((CharacterForm)getForm()).reload_tables();
    }

    public void sell(int itemId) {
        try{
            PreparedStatement pstmt = connection.prepareCall("begin sell_item(?); end;");
            pstmt.setInt(1,itemId);
            pstmt.execute();
            connection.commit();
        }
        catch (SQLException e){
            if(e.getErrorCode() > 20000){
                JOptionPane.showMessageDialog(null,e.getMessage());
            }
            else{
                System.err.println(e);
            }
        }
        ((CharacterForm)getForm()).reload_tables();
    }

    public void update(int itemId) {
        try{
            PreparedStatement pstmt = connection.prepareCall("begin update_item(?); end;");
            pstmt.setInt(1,itemId);
            pstmt.execute();
            connection.commit();
        }
        catch (SQLException e){
            if(e.getErrorCode() > 20000){
                JOptionPane.showMessageDialog(null,e.getMessage());
            }
            else{
                System.err.println(e);
            }
        }
        ((CharacterForm)getForm()).reload_tables();
    }

    public void buy(String rarity) {
        try{
            PreparedStatement pstmt = connection.prepareCall("begin buy_item(?,?); end;");
            pstmt.setInt(1,characterId);
            pstmt.setString(2,rarity);
            pstmt.execute();
            connection.commit();
        }
        catch (SQLException e){
            if(e.getErrorCode() > 20000){
                JOptionPane.showMessageDialog(null,e.getMessage());
            }
            else{
                System.err.println(e);
            }
        }
        ((CharacterForm)getForm()).reload_tables();
    }

    public void compare(int itemId) {

    }
}

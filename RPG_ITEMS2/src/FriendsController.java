import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import oracle.sql.ARRAY;

import javax.swing.*;
import java.sql.CallableStatement;
import java.sql.SQLException;

public class FriendsController extends Controller {
    private int userId;

    FriendsController(int userId){
        this.userId = userId;
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

    public ARRAY loadFriends() {
        try{
            OracleCallableStatement ocstmt = (OracleCallableStatement) connection.prepareCall("{ call rpg_friends_pk.get_friends(?,?) }");
            ocstmt.setInt(1, userId);
            ocstmt.registerOutParameter(2, OracleTypes.ARRAY,"FRIENDS_LIST");
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

    public void delete(int friendId) {
        try{
            CallableStatement cstmt = connection.prepareCall("{ call rpg_friends_pk.delete_friend(?,?) }");
            cstmt.setInt(1, friendId);
            cstmt.setInt(2, userId);
            cstmt.execute();
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
        ((FriendsForm)getForm()).reload_tables();
    }

    public void addFriend(String friendName) {
        try{
            CallableStatement cstmt = connection.prepareCall("{ call rpg_friends_pk.add_friend(?,?) }");
            cstmt.setInt(1, userId);
            cstmt.setString(2, friendName);
            cstmt.execute();
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
        ((FriendsForm)getForm()).reload_tables();
    }

    public void loadBattle(int friendId) {
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                BattleController battleController = new BattleController(userId, friendId);
                BattleForm battleForm = new BattleForm(battleController);
                battleController.setForm(battleForm);
                battleForm.setVisible(true);
                battleForm.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            }
        });
        getForm().dispose();
    }
}

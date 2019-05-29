import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import oracle.sql.ARRAY;

import javax.swing.*;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

public class BattleController extends Controller {
    private int userId;
    private int friendId;

    BattleController(int userId, int friendId) {
        this.userId = userId;
        this.friendId = friendId;
    }

    public ARRAY loadCharacters(boolean friend) {
        try {
            OracleCallableStatement ocstmt = (OracleCallableStatement) connection.prepareCall("{ call rpg_character_select.get_characters(?,?) }");
            if (friend) {
                ocstmt.setInt(1, friendId);
            } else {
                ocstmt.setInt(1, userId);
            }
            ocstmt.registerOutParameter(2, OracleTypes.ARRAY, "CHARACTER_LIST");
            ocstmt.execute();
            ARRAY array = (ARRAY) ocstmt.getArray(2);
            return array;
        } catch (SQLException e) {
            if (e.getErrorCode() > 20000) {
                JOptionPane.showMessageDialog(null, e.getMessage());
            } else {
                System.err.println(e);
            }
        }
        return null;
    }

    public void loadFriendsScene() {
        SwingUtilities.invokeLater(() -> {
            FriendsController friendsController = new FriendsController(userId);
            FriendsForm friendsForm = new FriendsForm(friendsController);
            friendsController.setForm(friendsForm);
            friendsForm.setVisible(true);
            friendsForm.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        });
        getForm().dispose();
    }

    public String battle(int mycharacterId, int friendCharacterId) {
        String output = "";
        try {
            CallableStatement cstmt = connection.prepareCall("{ ? = call rpg_friends_pk.battle_characters(?,?) }");
            cstmt.registerOutParameter(1, Types.VARCHAR);
            cstmt.setInt(2, mycharacterId);
            cstmt.setInt(3, friendCharacterId);
            cstmt.execute();
            output = cstmt.getString(1);
        } catch (SQLException e) {
            if (e.getErrorCode() > 20000) {
                JOptionPane.showMessageDialog(null, e.getMessage());
            } else {
                System.err.println(e);
            }
        }
        return output;
    }
}

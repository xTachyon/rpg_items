import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import oracle.sql.ARRAY;

import javax.swing.*;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class CharacterSelectController extends Controller {
    private int userId;

    CharacterSelectController(int userId) {
        this.userId = userId;
    }

    public ARRAY loadCharacters() {
        try {
            OracleCallableStatement ocstmt = (OracleCallableStatement) connection.prepareCall("{ call rpg_character_select.get_characters(?,?) }");
            ocstmt.setInt(1, userId);
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

    public void deleteCharacter(int characterId) {
        try {
            PreparedStatement pstmt = connection.prepareCall("begin rpg_character_select.delete_character(?); end;");
            pstmt.setInt(1, characterId);
            pstmt.execute();
            connection.commit();
        } catch (SQLException e) {
            if (e.getErrorCode() > 20000) {
                JOptionPane.showMessageDialog(null, e.getMessage());
            } else {
                System.err.println(e);
            }
        }
        ((CharacterSelectForm) getForm()).reload_table();
    }

    public void restoreCharacter(int characterId) {
        try {
            PreparedStatement pstmt = connection.prepareCall("begin rpg_character_select.restore_character(?); end;");
            pstmt.setInt(1, characterId);
            pstmt.execute();
            connection.commit();
        } catch (SQLException e) {
            if (e.getErrorCode() > 20000) {
                JOptionPane.showMessageDialog(null, e.getMessage());
            } else {
                System.err.println(e);
            }
        }
        ((CharacterSelectForm) getForm()).reload_table();
    }

    public void loadCharacerScene(int characterId) {
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                CharacterController characterController = new CharacterController(userId, characterId);
                CharacterForm characterForm = new CharacterForm(characterController);
                characterController.setForm(characterForm);
                characterForm.setVisible(true);
                characterForm.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            }
        });
        getForm().dispose();
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
}

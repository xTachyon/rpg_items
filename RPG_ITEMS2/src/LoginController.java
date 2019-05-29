import javax.swing.*;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

public class LoginController extends Controller {

    public void login(String username, String password) {
        try {
            CallableStatement cstmt = connection.prepareCall("{? = call rpg_login.user_login(?,'" + password + "')}");
            cstmt.registerOutParameter(1, Types.VARCHAR);
            cstmt.setString(2, username);
            cstmt.execute();
            int userId = cstmt.getInt(1);
            loadCharacterSelect(userId);
        } catch (SQLException e) {
            if (e.getErrorCode() > 20000) {
                JOptionPane.showMessageDialog(null, e.getMessage());
            } else {
                System.err.println(e.getMessage());
            }
        }
    }

    private void loadCharacterSelect(int userId) {
        SwingUtilities.invokeLater(() -> {
            CharacterSelectController characterSelect = new CharacterSelectController(userId);
            CharacterSelectForm characterSelectForm = new CharacterSelectForm(characterSelect);
            characterSelect.setForm(characterSelectForm);
            characterSelectForm.setVisible(true);
            characterSelectForm.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        });
        getForm().dispose();
    }
}

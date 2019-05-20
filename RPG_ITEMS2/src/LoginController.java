import javax.swing.*;
import java.awt.event.WindowEvent;
import java.sql.*;

public class LoginController extends Controller{

    public void login(String username,String password){
        try{
            CallableStatement cstmt = connection.prepareCall("{? = call user_login(?,?)}");
            cstmt.registerOutParameter(1, Types.VARCHAR);
            cstmt.setString(2, username);
            cstmt.setString(3, password);
            cstmt.execute();
            int userId = cstmt.getInt(1);
            loadCharacterSelect(userId);
        }
        catch (SQLException e){
            if(e.getErrorCode() > 20000){
                JOptionPane.showMessageDialog(null,e.getMessage());
            }
        }
    }

    private void loadCharacterSelect(int userId){
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
}

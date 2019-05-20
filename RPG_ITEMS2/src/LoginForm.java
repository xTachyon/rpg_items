import javax.swing.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

public class LoginForm extends JFrame{
    private JButton loginButton;
    private JPanel panel;
    private JTextField usernameField;
    private JPasswordField passwordField;

    private LoginController loginController;

    public LoginForm(LoginController loginController){
        this.loginController = loginController;

        setTitle("Login");
        setSize(300,200);
        add(panel);

        loginButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                loginController.login(usernameField.getText(),String.valueOf(passwordField.getPassword()));
            }
        });
    }
}

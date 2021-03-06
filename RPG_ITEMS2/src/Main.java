import javax.swing.*;

public class Main {
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            LoginController loginController = new LoginController();
            LoginForm loginForm = new LoginForm(loginController);
            loginController.setForm(loginForm);
            loginForm.setVisible(true);
            loginForm.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        });
    }
}

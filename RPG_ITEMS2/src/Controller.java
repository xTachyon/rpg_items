import javax.swing.*;
import java.sql.Connection;

abstract class Controller {
    protected Connection connection = Database.getConnection();
    private JFrame form;

    public JFrame getForm() {
        return form;
    }

    public void setForm(JFrame frame) {
        this.form = frame;
    }
}

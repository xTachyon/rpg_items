import javax.swing.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

public class CompareItemsForm extends JFrame{
    private JButton compareButton;
    private JSpinner itemId1Spinner;
    private JSpinner itemId2Spinner;
    private JPanel panel;
    private JTextArea comparationResultTextArea;

    private CompareItemsController compareItemsController;

    public CompareItemsForm(CompareItemsController compareItemsController) {
        this.compareItemsController = compareItemsController;
        setTitle("Character");
        setSize(400,200);

        add(panel);

        compareButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                comparationResultTextArea.setText(compareItemsController.compareItems(
                        (Integer) itemId1Spinner.getValue(),
                        (Integer) itemId2Spinner.getValue()));
            }
        });
    }

    private void createUIComponents() {
        comparationResultTextArea = new JTextArea(30,30);
        comparationResultTextArea.setEditable(false);
    }
}

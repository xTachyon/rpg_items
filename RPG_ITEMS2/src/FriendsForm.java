import oracle.sql.ARRAY;

import javax.swing.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

public class FriendsForm extends JFrame{
    private JTable friendsJTable;
    private JButton backButton;
    private JButton addFriendButton;
    private JButton removeFriendButton;
    private JButton battleButton;
    private JPanel panel;
    private JTextField friendTextField;

    private FriendsController friendsController;

    FriendsForm(FriendsController friendsController){
        this.friendsController = friendsController;
        setTitle("Character Select");
        setSize(1600,800);

        add(panel);

        backButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                    friendsController.loadCharacterSelectScene();
            }
        });
        addFriendButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if(friendTextField.getText() != null){
                    friendsController.addFriend(friendTextField.getText());
                }
            }
        });
        removeFriendButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if(friendsJTable.getSelectedRow()!= -1) {
                    friendsController.delete
                            (Integer.parseInt(friendsJTable.getValueAt(friendsJTable.getSelectedRow(),0).toString()));
                }
            }
        });
        battleButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if(friendsJTable.getSelectedRow()!= -1) {
                    friendsController.loadBattle
                            (Integer.parseInt(friendsJTable.getValueAt(friendsJTable.getSelectedRow(),0).toString()));
                }
            }
        });
    }

    public void reload_tables(){
        String[] jTableColumnNames = {"ID", "Name"};
        ARRAY array = friendsController.loadFriends();
        friendsJTable = UtilsForms.loadJTable(friendsJTable, array, jTableColumnNames,true);
    }

    private void createUIComponents() {
        String[] jTableColumnNames = {"ID", "Name"};
        ARRAY array = friendsController.loadFriends();
        friendsJTable = UtilsForms.loadJTable(friendsJTable, array, jTableColumnNames,false);
    }
}

/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Labs.Components 0.1
import MeeGo.App.Notes 0.1

ApplicationPage {
    id: topRect;
    property string notebookID: qsTr("Everyday Notes (default)")
    property string noteName: qsTr("Note name...")
    property bool listNumbers: false;
    property bool listBullets: false;
    property int listNumbersCount: 0
    property string strNumberCount: ""
    property alias caption: nameLabel.text

    signal modifyNote(string notebook, string note, string text)
    signal deleteNote(string notebook, string note)
    signal closeWindow();

    //page specific context menu
    menuContent: ActionMenu {
        id: actions
        model: [qsTr("Save"), qsTr("Delete"),/* qsTr("Share")*/ ]
        onTriggered: {
            if(index == 0) {
                dataHandler.modifyNote(notebookID, nameLabel.text, editor.text);
            } else if(index == 1) {
                deleteConfirmationDialog.opacity = 1;
            } else {
                shareDialog.opacity = 1;
            }

            topRect.closeMenu();
        }//ontriggered
    }//action menu

    TextEditHandler {
        id: textEditHandler
    }

    Item {
        id: content
        anchors.fill: topRect.content

        Rectangle {
            id: textRect;
            height: 50;
            color: "#CACACA"

            anchors { left: parent.left;
                right: parent.right;
                top: parent.top;
            }

            Text {
                id: nameLabel

                text: qsTr("Test Notebook Name");
                font.pointSize: 16;
                smooth: true

                anchors { left: parent.left;
                    right: parent.right;
                    top: parent.top;
                    topMargin: 10
                    leftMargin: 30
                }
            }
        }

        EditPane {
            id: editor
            property int topMargins: 20
            anchors.top: textRect.bottom;
            anchors.topMargin: topMargins
            anchors.left: parent.left
            anchors.leftMargin: 30
            anchors.right: parent.right
            anchors.rightMargin: 30
            width: parent.width;
            height: parent.height -  textRect.height - topMargins;
            contentWidth: editor.paintedWidth
            contentHeight: editor.paintedHeight
            smooth:true;
            text: dataHandler.loadNoteData(notebookID, noteName);
            defaultText: qsTr("Start typing a new note.")
        }



        ModalDialog {
            id: deleteConfirmationDialog

            opacity: 0

            leftButtonText: qsTr("Yes");
            rightButtonText: qsTr("No");
            dialogTitle: qsTr("Delete?");

            Component {
                id: textComp

                Text {
                    text: qsTr("Do you want to Delete\nthis notebook?");
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
            }

            contentLoader.sourceComponent: textComp

            onDialogClicked: {
                if (button == 1) {
                    // Yes
                    dataHandler.deleteNote(notebookID, noteName);
                    opacity = 0;
                    topRect.closeWindow();
                }
                else if (button == 2) {
                    // No
                    opacity = 0;
                }
            }
        }

        ShareNote {
            id: shareDialog
            opacity: 0;
            anchors.centerIn: parent
            //focus: true;

            onButtonSendClicked:
            {
                console.log("shareDialog::onButtonSendClicked");
                shareDialog.opacity = 0;
            }

            onButtonCancelClicked:
            {
                console.log("ShareNote::onButtonCancelClicked");
                shareDialog.opacity = 0;
            }
        }

    }
}


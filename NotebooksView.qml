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
    id: notebookListPage

    property string selectedNotebook: qsTr("Everyday Notes (default)")
    property string defaultNotebook: qsTr("Everyday Notes (default)")
    property string selectedTitle
    property bool showCheckBox: dataHandler.getCheckBox()
    property variant selectedItems: [];

    signal notebookClicked(string name, string title)
    signal updateView();


    menuContent: Column {
        ActionMenu {
            id: firstActionMenu
            model: {
                if((listView.count == 1) || (showCheckBox) ) {
                    return [qsTr("New Notebook")];
                } else {
                    return [qsTr("New Notebook"), qsTr("Select Multiple")];
                }
            }
            onTriggered: {
                if(index == 0) {
                    addDialogLoader.sourceComponent = addDialogComponent;
                    addDialogLoader.item.parent = notebookListPage;
                } else if(index == 1) {
                    showCheckBox = true;
                    multiSelectRow.opacity = 1;
                }
                notebookListPage.closeMenu();
            }//ontriggered
        }//action menu
    }

    Component {
        id: notebookDelegate

        NoteButton {
            id: notebook
            x: 40
            width: listView.width - 80;
            height:theme_listBackgroundPixelHeightTwo
            title: name
            comment: {
                if(notesCount == 1){
                    qsTr("%1 Note").arg(notesCount);
                } else {
                    qsTr("%1 Notes").arg(notesCount);
                }
            }
            isNote : false
            checkBoxVisible: false;

            MouseArea {
                anchors.fill: parent

                onClicked: notebookClicked(name, title)

                onPressAndHold:{
                    selectedNotebook = name;
                    selectedTitle = title;
                    contextMenu.menuX = notebook.x + mouseX;
                    contextMenu.menuY = notebook.y + 50/*header*/ + mouseY;
                    contextMenu.visible = true;
                }
            }
        }
    }

    Component {
        id: notebookDelegate2

        NoteButton {
            id: notebook2
            x: 40
            width: listView.width - 80;
            height: theme_listBackgroundPixelHeightTwo
            title: name
            comment: {
                if(dataHandler.getChildNotes(name) == 1) {
                    qsTr("%1 Note").arg(dataHandler.getChildNotes(name));
                } else {
                    qsTr("%1 Notes").arg(dataHandler.getChildNotes(name));
                }
            }
            isNote : false
            checkBoxVisible: index != 0

            onNoteSelected: {
                var tmpList = selectedItems;
                tmpList.push(noteName);
                selectedItems = tmpList;
            }

            onNoteDeselected: {
                var tmpList = selectedItems;
                tmpList = dataHandler.removeFromString(tmpList, noteName);
                selectedItems = tmpList;
            }

            MouseArea {
                anchors.left:parent.left
                anchors.leftMargin: parent.checkBoxWidth;
                anchors.right:parent.right
                anchors.top:parent.top
                anchors.bottom:parent.bottom

                onClicked: notebookClicked(name, title)

                onPressAndHold:{
                    selectedNotebook = name;
                    selectedTitle = title;
                    contextMenu.menuX = notebook2.x + mouseX;
                    contextMenu.menuY = notebook2.y + 50/*header*/ + mouseY;
                    contextMenu.visible = true;
                }
            }
        }
    }

    Item {
        id: mainContainer
        anchors.fill: notebookListPage.content

        ListView {
            id: listView
            width: parent.width;
            height: parent.height
            model: notebooksModel
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right


            delegate: showCheckBox ? notebookDelegate2 : notebookDelegate;
            //focus: true
            clip: true
            spacing: 1
            cacheBuffer: 600
            interactive: contentHeight > listView.height

            header:
                Item {
                width:listView.width
                height: 50
            }
            footer:
                Item {
                width:listView.width
                height: 50
            }
        }

        Row {
            id: multiSelectRow
            anchors.bottom: listView.bottom
            height: 100
            spacing: 10
            opacity: 0
            anchors.horizontalCenter: listView.horizontalCenter
            Button {
                id: deleteButton
                title: qsTr("Delete")
                width: 200
                height: 100
                active: selectedItems.length > 0
                bgSourceUp: "image://theme/btn_red_up"
                bgSourceDn: "image://theme/btn_red_dn"
                onClicked: {
                    deleteConfirmationDialog.opacity = 1;
                    showCheckBox = false;
                    multiSelectRow.opacity = 0;
                }
            }

            Button {
                id: cancelButton
                title: qsTr("Cancel")
                anchors.bottom: listView.bottom
                width: 200
                height: 100
                onClicked: {
                    multiSelectRow.opacity = 0;
                    showCheckBox = false;
                }
            }
        }
    }

    // context menu system
    ContextMenu {
        id: contextMenu

        visible: false

        menuX: 0
        menuY: 0
        width: 150
        height: 300

        property string openChoice: qsTr("Open");
        property string emailChoice: qsTr("Email");
        property string deleteChoice: qsTr("Delete");

        property variant choices: [ openChoice, emailChoice, deleteChoice ]
        property variant defaultListChoices: [ openChoice, emailChoice ]


        model:  {
            if(selectedNotebook == defaultNotebook) {
                return defaultListChoices;
            } else {
                return choices;
            }
        }

        onTriggered: {
            console.log("triggered: " + index);
            if (model[index] == openChoice)
            {
                notebookClicked(selectedNotebook, selectedTitle)
            }
            else if (model[index] == emailChoice)
            {
                shareDialog.opacity = 1;
            }
            else if (model[index] == deleteChoice)
            {
                if (selectedItems.length > 1)
                {
                    if (selectedItems[0] != defaultNotebook)
                    {

                        deleteConfirmationDialog.opacity = 1;
                    }
                }
                else if (selectedItems.length == 1)
                {
                    if (selectedItems[0] != defaultNotebook)
                    {
                        deleteConfirmationDialog.opacity = 1;
                    }
                }
                else
                {
                    deleteConfirmationDialog.opacity = 1;
                }
            }
        }
    }

    // dialogs
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

    Loader {
        id: addDialogLoader
        anchors.fill: parent
    }

    Component {
        id: addDialogComponent

        TwoButtonsModalDialog {
            id: addDialog
            menuHeight: 125
            minWidth: 260
            dialogTitle: qsTr("Create a new Notebook");
            buttonText: qsTr("Create");
            button2Text: qsTr("Cancel");
            defaultText: qsTr("Notebook name");
            onButton1Clicked: {
                //workaround (max length of the folder name - 256)
                if (text.length > 256)
                    text = text.slice(0, 255);

                updateView();
                //            opacity = 0;
                addDialogLoader.sourceComponent = undefined;

                if (dataHandler.noteBookExists(text)) {
                    informationDialog.info = qsTr("A NoteBook <b>'" + text + "'</b> already exists.");
                    informationDialog.visible = true;
                    return;
                }

                dataHandler.createNoteBook(text);
                //                updateView();
                //                //            opacity = 0;
                //                addDialogLoader.sourceComponent = undefined;
            }

            onButton2Clicked: {
                updateView();
                //            opacity = 0;
                addDialogLoader.sourceComponent = undefined;
            }

        }
    }

    ModalDialog {
        id: deleteConfirmationDialog
        opacity: 0
        leftButtonText: qsTr("Delete");
        rightButtonText: qsTr("Cancel");
        dialogTitle: qsTr("Delete?");
        property string componentText: (selectedItems.length > 0) ? selectedItems[0] : selectedNotebook;
        bgSourceUpLeft: "image://theme/btn_red_up"
        bgSourceDnLeft: "image://theme/btn_red_dn"

        Component {
            id: textComp

            Text {
                text: qsTr("Are you sure you want to\ndelete \"%1\"?").arg(componentText);
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                wrapMode: Text.Wrap
            }
        }

        Component {
            id: textComp2

            Text {
                text: qsTr("Are you sure you want to\ndelete these %1 notebooks?").arg(selectedItems.length);
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }

        contentLoader.sourceComponent: (selectedItems.length > 1) ? textComp2: textComp

        onDialogClicked:
        {
            if (button == 1) // Yes
            {
                if (selectedItems.length > 0)
                {
                    dataHandler.deleteNoteBooks(selectedItems);
                    selectedItems = [];
                }
                else
                {
                    dataHandler.deleteNoteBook(selectedNotebook);
                }

                opacity = 0;
                deleteReportWindow.opacity = 1;
            }
            else if (button == 2) // No
            {
                opacity = 0;
                selectedItems = [];
            }
        }
    }


    DeleteMoveNotificationDialog {
        id: deleteReportWindow
        opacity: 0;
        minWidth: 270
        buttonText: qsTr("OK");
        dialogTitle: (selectedItems.length > 1) ? qsTr("Notebooks deleted") : qsTr("Notebook deleted")
        text:  {
            if(selectedItems.length > 1) {
                return qsTr("\"%1\" notebooks have been deleted").arg(selectedItems.length);
            } else if(selectedItems.length == 1) {
                return qsTr("\"%1\" has been deleted").arg(selectedItems[0]);
            } else  {
                return qsTr("\"%1\" has been deleted").arg(selectedNotebook);
            }
        }

        onDialogClicked:
        {
            selectedItems = [];
            opacity = 0;
            updateView();
        }
    }

    InformationDialog {
        id: informationDialog
        visible: false

        onOkClicked: informationDialog.visible = false;
    }
}


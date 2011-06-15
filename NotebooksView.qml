/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Components 0.1
import MeeGo.App.Notes 0.1

AppPage {
    id: page

    property alias model: listView.model

    signal noteBookClicked(variant noteBook)

    Theme {
        id: theme
    }

    enableCustomActionMenu: true

    onActionMenuIconClicked: {
        if (window.pageStack.currentPage == page) {
            firstActionMenu.model = internal.menuModel();
            customMenu.setPosition(mouseX, mouseY);
            customMenu.show();
        }
    }

    BlankStateScreen {
        id: blankStateScreen
        anchors.fill: parent
        parent: page

        mainTitleText: qsTr("Use the default notebook, or make a new one")
        buttonText: qsTr("Create a new notebook")
        firstHelpTitle: qsTr("What's a notebook?")
        secondHelpTitle: qsTr("How do I create notes?")
        firstHelpText: qsTr("A notebook is a collection of notes. Use the default notebook we have created for you, or make a new one.")
        secondHelpText: qsTr("Tap the 'Create the first note' button. You can also tap the icon in the top right corner of the screen, then select 'New note'.")

        onButtonClicked: addDialog.show()

        visible: (saveRestore.value("FirstTimeUseNotebooks") == undefined) && listView.model.count == 1
    }

    ContextMenu {
        id: customMenu
        content: Column {
            ActionMenu {
                id: firstActionMenu
                model: internal.menuModel()
                onTriggered: {
                    if(index == 0) {
                        addDialog.show();
                    } else if(index == 1) {
                        internal.selectMultiply = true;
                        multiSelectRow.show();
                    }
                    customMenu.hide();
                }//ontriggered
            }//action menu
            Text {
                id: viewByText
                anchors.left: parent.left
                anchors.leftMargin: 5
                text: qsTr("View by:")
                font.pixelSize: theme.fontPixelSizeLarge
                color: theme.fontColorNormal
            }
            ActionMenu {
                id: secondActionMenu
                model: [qsTr("All"), qsTr("Alphabetical order")]
                onTriggered: {
                    if(index == 0) {
                        page.model.sorting = false;
                    } else if(index == 1) {
                        page.model.sorting = true;
                        page.model.sort(NoteBooksModel.ASC);    //TODO: make possibility to sort in both directions
                    }
                    customMenu.hide();
                }//ontriggered
            }

        }
    }

    Component {
        id: notebookDelegate

        NoteButton {
            width: listView.width
            title: noteBook.title
            comment: internal.notesCountText(noteBook)
            itemData: noteBook
            checkBoxVisible: false
            showGrip: false

            onItemTapped: noteBookClicked(itemData)

            onItemTappedAndHeld: {
                internal.selectedNoteBook = itemData;
                var map = mapToItem(null, gesture.position.x, gesture.position.y);
                contextMenu.setPosition(map.x, map.y);
                contextMenu.show();
            }
        }
    }

    Component {
        id: notebookDelegate2

        NoteButton {
            width: listView.width
            title: noteBook.title
            comment: internal.notesCountText(noteBook)
            itemData: noteBook
            checkBoxVisible: index != 0
            showGrip: false

            onItemSelected: internal.addItem(itemData)
            onItemDeselected: internal.removeItem(itemData)
            onItemTapped: noteBookClicked(itemData)

            onItemTappedAndHeld: {
                internal.selectedNoteBook = itemData;
                var map = mapToItem(null, gesture.position.x, gesture.position.y);
                contextMenu.setPosition(map.x, map.y);
                contextMenu.show();
            }
        }
    }

    ListView {
        id: listView
        anchors.fill: parent

        delegate: internal.selectMultiply ? notebookDelegate2 : notebookDelegate

        clip: true
        spacing: 1
        cacheBuffer: 600
        interactive: contentHeight > listView.height
    }

    BottomToolBar {
        id: multiSelectRow
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        content: BottomToolBarRow {
            centerContent: Row {
                spacing: 10
                Button {
                    id: deleteButton
                    text: qsTr("Delete (%1)").arg(internal.selectedNoteBooks.length)
                    enabled: internal.selectedNoteBooks.length > 0
                    bgSourceUp: "image://themedimage/images/btn_red_up"
                    bgSourceDn: "image://themedimage/images/btn_red_dn"
                    onClicked: deleteConfirmationDialog.show()
                }
                Button {
                    id: cancelButton
                    text: qsTr("Cancel")
                    onClicked: {
                        multiSelectRow.hide();
                        internal.selectMultiply = false;
                        internal.selectedNoteBooks = [];
                    }
                }
            }
        }
    }

    // context menu system
    ContextMenu {
        id: contextMenu

        property string openChoice: qsTr("Open")
        property string deleteChoice: qsTr("Delete")
        property string renameChoice: qsTr("Rename")

        property variant choices: [ openChoice,  deleteChoice, renameChoice ]
        property variant defaultListChoices: [ openChoice ]


        content: ActionMenu {
            model:  {
                if(internal.selectedNoteBook.id == page.model.defaultNoteBookId) {
                    return contextMenu.defaultListChoices;
                } else {
                    return contextMenu.choices;
                }
            }

            onTriggered: {
                if (model[index] == contextMenu.openChoice) {
                    noteBookClicked(internal.selectedNoteBook);
                } else if (model[index] == contextMenu.deleteChoice) {
                    if (internal.selectedNoteBook)
                        deleteConfirmationDialog.show();
                } else if (model[index] == contextMenu.renameChoice) {
                    renameWindow.oldName = internal.selectedNoteBook.title;
                    renameWindow.show();
                }
                contextMenu.hide();
            }
        }
    }

    ModalDialog {
        id: addDialog
        title: qsTr("Create a new notebook")
        acceptButtonText: qsTr("Create")
        cancelButtonText: qsTr("Cancel")
        showAcceptButton: newName.text.length > 0
        content: Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: anchors.leftMargin
            TextEntry {
                id: newName
                defaultText: qsTr("Notebook name")
                onTextChanged: newName.text = newName.text.slice(0, window.maxCharactersCount)
                anchors.left: parent.left
                anchors.right: parent.right
            }
            Text {
                id: charsIndicator
                anchors.right: parent.right
                font.italic: true
                font.pixelSize: 10
                //: %1 is current title length, %2 is max title length
                text: qsTr("%1/%2", "CharLeft").arg(newName.text.length).arg(window.maxCharactersCount)
            }
        }

        onAccepted: {
            //first time use feature
            if (saveRestore.value("FirstTimeUseNotebooks") == undefined) {
                saveRestore.setValue("FirstTimeUseNotebooks", false);
                saveRestore.sync();
            }

            var name = newName.text;
            newName.text = ""; //reset it for next time
            if (page.model.noteBookExists(name)) {  //TODO: do we need this checking now?
                informationDialog.info = qsTr("A NoteBook '%1' already exists.").arg(name);
                informationDialog.show();
                return;
            }

            page.model.createNoteBook(name);
        }
    }

    ModalDialog {
        id: deleteConfirmationDialog
        acceptButtonText: qsTr("Delete")
        title: (internal.selectedNoteBooks.length > 1) ? qsTr("Delete notebooks?") : qsTr("Delete notebook?")
        content: Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: anchors.leftMargin

            text: (internal.selectedNoteBooks.length > 1)
                  ? qsTr("Are you sure you want to delete these %1 notebooks?").arg(internal.selectedNoteBooks.length)
                  //: %1 is notebook title
                  : qsTr("Are you sure you want to delete \"%1\"?").arg(componentText)

            property string componentText: internal.selectedNoteBook ? internal.selectedNoteBook.title
                                                                     : (internal.selectedNoteBooks.length == 1 ? internal.selectedNoteBooks[0].title : "")
        }

        acceptButtonImage: "image://themedimage/images/btn_red_up"
        acceptButtonImagePressed:"image://themedimage/images/btn_red_dn"

        onAccepted: {   //TODO: check it
            if (internal.selectedNoteBooks.length > 0) {
                for (var i = 0; i < internal.selectedNoteBooks.length; ++i)
                    page.model.removeNoteBook(internal.selectedNoteBooks[i].id);
            } else {
                page.model.removeNoteBook(internal.selectedNoteBook.id);
            }
            deleteReportWindow.show();
            internal.selectMultiply = false;
            multiSelectRow.hide();
        }

        onRejected: internal.selectedNoteBooks = []
    }

    ModalDialog {
        id: deleteReportWindow
        showCancelButton: false
        showAcceptButton: true
        acceptButtonText: qsTr("OK")
        title: (internal.selectedNoteBooks.length > 1) ? qsTr("Notebooks deleted") : qsTr("Notebook deleted")
        content: Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: anchors.leftMargin
            text: {
                if(internal.selectedNoteBooks.length > 1) {
                    return qsTr("%1 notebooks have been deleted").arg(internal.selectedNoteBooks.length);
                } else if(internal.selectedNoteBooks.length == 1) {
                    //: %1 is notebook title
                    return qsTr("\"%1\" has been deleted").arg(internal.selectedNoteBooks[0]);
                } else {
                    return qsTr("\"%1\" has been deleted").arg(internal.selectedNoteBook);
                }
            }
        }
        onAccepted: internal.selectedNoteBooks = []
    }

    ModalDialog {
        id: informationDialog
        title: qsTr("Information")
        property alias info: textInfo.text
        showCancelButton: false
        showAcceptButton: true
        acceptButtonText: qsTr("OK")
        content: Text {
            id: textInfo
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: anchors.leftMargin
        }
    }

    ModalDialog {
        id: renameWindow
        acceptButtonText: qsTr("OK")
        cancelButtonText: qsTr("Cancel")
        showAcceptButton: renameTextEntry.text.length > 0
        title: qsTr("Rename noteBook")

        property string oldName

        content: Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: anchors.leftMargin
            TextEntry {
                id: renameTextEntry
                onTextChanged: renameTextEntry.text = renameTextEntry.text.slice(0, window.maxCharactersCount)
                anchors.left: parent.left
                anchors.right: parent.right
            }
            Text {
                id: renameCharsIndicator
                anchors.right: parent.right
                font.italic: true
                font.pixelSize: 10
                text: qsTr("%1/%2", "CharLeft").arg(renameTextEntry.text.length).arg(window.maxCharactersCount)
            }
        }

        onOldNameChanged: renameTextEntry.text = oldName

        onAccepted: {
            var newName = renameTextEntry.text;
            if (page.model.noteBookExists(newName)) {   //TODO: do we need this checking now?
                //: %1 is notebook title
                informationDialog.info = qsTr("A noteBook '%1' already exists.").arg(newName);
                informationDialog.show();
                return;
            }
            page.model.renameNoteBook(internal.selectedNoteBook.id, newName);
        }
    }

    QtObject {
        id: internal

        property variant selectedNoteBook: page.model.noteBook(0)   //NOTE: default note books is always on 0 position
        property variant selectedNoteBooks: []
        property bool selectMultiply: false

        function addItem(item)
        {
            var list = selectedNoteBooks;
            list.push(item);
            selectedNoteBooks = list;
        }

        function removeItem(item)
        {
            var list = selectedNoteBooks;
            for (var i = 0; i < list.length; ++i) {
                if (list[i].id == item.id) {
                    list.splice(i, 1);
                    break;
                }
            }
            selectedNoteBooks = list;
        }

        function notesCountText(noteBook)
        {
            var notesCount = noteBook ? noteBook.notesCount : 0;
            return notesCount == 1 ? qsTr("%1 note").arg(notesCount) : qsTr("%1 notes").arg(notesCount);
        }

        function menuModel()
        {
            var res = [];
            res.push(qsTr("New notebook"));
            if(listView.model.count > 1)
                res.push(qsTr("Select multiple"));
            return res;
        }
    }
}

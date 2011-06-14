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
import MeeGo.Sharing 0.1
import MeeGo.Sharing.UI 0.1

AppPage {
    id: page

    property alias model: listView.model

    signal noteClicked(variant note)

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

        y: theme.listBackgroundPixelHeightTwo + 10

        mainTitleText: qsTr("This notebook is empty")
        buttonText: qsTr("Create the first note")
        firstHelpTitle: qsTr("How do I create notes?")
        secondHelpTitle: qsTr("Share your notes by email")
        firstHelpText: qsTr("Tap the 'Create the first note' button. You can also tap the icon in the top right corner of the screen, then select 'New note'.")
        secondHelpText: qsTr("To send a note by email, tap and hold the note you want to send, then select 'Email'.")
        helpContentVisible: (saveRestore.value("FirstTimeUseNotes") == undefined) && (listView.count == 0)

        onButtonClicked: addDialog.show()
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
            id: button

            width: listView.width
            title: note.title
            comment: note.html
            itemData: note
            checkBoxVisible: false
            showGrip: !page.model.sorting

            onItemTapped: noteClicked(itemData)

            onItemTappedAndHeld: {
                internal.selectedNote = itemData;
                var map = mapToItem(null, gesture.position.x, gesture.position.y);
                internal.selectedNotePoint = map;
                contextMenu.setPosition(map.x, map.y);
                contextMenu.show();
            }

            onGripTappedAndHeld: {
                internal.dndStarted = true;
                internal.dndStartPoint = mapToItem(listView, gesture.position.x, gesture.position.y);
                internal.dndOlButtonY = button.y;
                button.z = 10;
                button.opacity = 0.5;
                button.color = "lightgray";
                listView.interactive = false;
            }

            onGripPanUpdated: {
                if (!internal.dndStarted)
                    return;

                var currentPoint = internal.dndStartPoint;
                currentPoint.y += gesture.offset.y;
                internal.dndCurrentPoint = currentPoint;

                button.y = currentPoint.y;
            }

            onGripPanFinished: {
                button.y = internal.dndOlButtonY;
                button.z = 0;
                button.opacity = 1.0;
                button.color = "white";

                var index = listView.indexAt(internal.dndCurrentPoint.x, internal.dndCurrentPoint.y);
                page.model.swapNotes(itemData.id, page.model.note(index).id);

                internal.dndStarted = false;
                internal.dndStartPoint = null;
                internal.dndCurrentPoint = null;
                listView.interactive = true;
            }
        }
    }

    Component {
        id: notebookDelegate2

        NoteButton {
            id: button2

            width: listView.width
            title: note.title
            comment: note.html
            itemData: note
            checkBoxVisible: true
            showGrip: !page.model.sorting

            onItemSelected: internal.addItem(itemData)
            onItemDeselected: internal.removeItem(itemData)
            onItemTapped: noteBookClicked(itemData)

            onItemTappedAndHeld: {
                internal.selectedNote = itemData;
                var map = mapToItem(null, gesture.position.x, gesture.position.y);
                internal.selectedNotePoint = map;
                contextMenu.setPosition(map.x, map.y);
                contextMenu.show();
            }

            onGripTappedAndHeld: {
                internal.dndStarted = true;
                internal.dndStartPoint = mapToItem(listView, gesture.position.x, gesture.position.y);
                internal.dndOlButtonY = button2.y;
                button2.z = 10;
                button2.opacity = 0.5;
                button2.color = "lightgray";
                listView.interactive = false;
            }

            onGripPanUpdated: {
                if (!internal.dndStarted)
                    return;

                var currentPoint = internal.dndStartPoint;
                currentPoint.y += gesture.offset.y;
                internal.dndCurrentPoint = currentPoint;

                button2.y = currentPoint.y;
            }

            onGripPanFinished: {
                button2.y = internal.dndOlButtonY;
                button2.z = 0;
                button2.opacity = 1.0;
                button2.color = "white";

                var index = listView.indexAt(internal.dndCurrentPoint.x, internal.dndCurrentPoint.y);
                page.model.swapNotes(itemData.id, page.model.note(index).id);

                internal.dndStarted = false;
                internal.dndStartPoint = null;
                internal.dndCurrentPoint = null;
                listView.interactive = true;
            }
        }
    }

    NoteButton {
        id: noteBookNameLabel

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        color: "lightgray"

        title: page.model.noteBook ? page.model.noteBook.title : ""
        comment: ""
        itemData: page.model.noteBook
        checkBoxVisible: false
        showGrip: false
    }

    ListView {
        id: listView
        anchors.top: noteBookNameLabel.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

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
                    text: qsTr("Delete (%1)").arg(internal.selectedNotes.length)
                    enabled: internal.selectedNotes.length > 0
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
                        internal.selectedNotes = [];
                    }
                }
            }
        }
    }

    // context menu system
    ContextMenu {
        id: contextMenu

        property string openChoice: qsTr("Open")
        property string emailChoice: qsTr("Email")
        property string moveChoice: qsTr("Move")
        property string deleteChoice: qsTr("Delete")
        property string renameChoice: qsTr("Rename")

        ShareObj {
            id: shareObj
            shareType: MeeGoUXSharingClientQmlObj.ShareTypeText
        }

        property variant choices: [ openChoice, emailChoice, moveChoice, deleteChoice, renameChoice ]

        content: ActionMenu {
            model: contextMenu.choices
            onTriggered: {
                if (model[index] == contextMenu.openChoice) {
                    noteClicked(internal.selectedNote);
                } else if (model[index] == contextMenu.emailChoice) {
                    var uri = page.model.dumpNote(internal.selectedNote.id);
                    shareObj.clearItems();
                    shareObj.addItem(uri);
                    shareObj.setParam(uri, "subject", noteListPage.selectedTitle);
                    shareObj.showContext(qsTr("Email"), noteListPage.width / 2, noteListPage.height / 2);
                } else if (model[index] == contextMenu.moveChoice) {
                    notebookSelectorMenu.filterNoteBooksList();
                    notebookSelector.setPosition(internal.selectedNotePoint.x, internal.selectedNotePoint.y);
                    notebookSelector.show();
                } else if (model[index] == contextMenu.deleteChoice) {
                    if (internal.selectedNote)
                        deleteConfirmationDialog.show();
                } else if(model[index] == contextMenu.renameChoice) {
                    renameWindow.oldName = internal.selectedNote.title;
                    renameWindow.show();
                }

                contextMenu.hide();
            }
        }
    }

    ContextMenu {
        id: notebookSelector

        content: ActionMenu {
            id: notebookSelectorMenu
            //Removes current notebook's name from a list of notebooks.
            //Fixes moving a note to current notebook and prevent vanishing of the note.
            function filterNoteBooksList()
            {
                var m = [];
                var p = [];
                for (var i = 0; i < noteBooksModel.count; ++i) {
                    var noteBook = noteBooksModel.noteBook(i);
                    if (noteBook.id == page.model.noteBook.id)
                        continue;
                    m.push(noteBook.title);
                    p.push(noteBook);
                }
                notebookSelectorMenu.model = m;
                notebookSelectorMenu.payload = p;
            }

            onTriggered: {
                var newNotebook = model[index];

                if (internal.selectedNotes.length > 1) {
                    moveReportWindow.text = qsTr("%1 notes have successfully been moved to \"%2\"").arg(internal.selectedNotes.length).arg(newNotebook);
                } else {
                    moveReportWindow.text = qsTr("\"%1\" has successfully been moved to \"%2\"").arg(internal.selectedNote.title).arg(newNotebook);
                }

                if (internal.selectedNotes.length > 0) {
                    for (var i = 0; i < internal.selectedNotes.length; ++i)
                        page.model.moveNote(internal.selectedNotes[i].id, payload[index].id);
                    internal.selectedNotes = [];
                } else {
                    page.model.moveNote(internal.selectedNote.id, payload[index].id);
                }

                notebookSelector.hide();
                moveReportWindow.show();
            }

        }
    }

    ModalDialog {
        id: addDialog
        title: qsTr("Create a new note")
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
                defaultText: qsTr("Note name")
                onTextChanged: newName.text = newName.text.slice(0, window.maxCharactersCount)
                anchors.left: parent.left
                anchors.right: parent.right
            }
            Text {
                id: charsIndicator
                anchors.right: parent.right
                font.italic: true
                font.pixelSize: 10
                text: qsTr("%1/%2").arg(newName.text.length).arg(window.maxCharactersCount)
            }
        }

        onAccepted: {
            //first time use feature
            if (saveRestore.value("FirstTimeUseNotes") == undefined) {
                saveRestore.setValue("FirstTimeUseNotes", false);
                saveRestore.sync();
            }

            var name = newName.text;
            newName.text = ""; //reset it for next time

            if (page.model.noteExists(name)) {  //TODO: do we need this checking now?
                informationDialog.info = qsTr("A Note '%1' already exists.").arg(name);
                informationDialog.show();
                return;
            }

            noteClicked(page.model.createNote(name));
        }
    }

    ModalDialog {
        id: deleteConfirmationDialog
        acceptButtonText: qsTr("Delete")
        title: (internal.selectedNotes.length > 1) ? qsTr("Delete notes?") : qsTr("Delete note?")
        content: Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: anchors.leftMargin

            text: (internal.selectedNotes.length > 1)
                  ? qsTr("Are you sure you want to delete these %1 notes?").arg(internal.selectedNotes.length)
                  : qsTr("Are you sure you want to delete \"%1\"?").arg(componentText)

            property string componentText: internal.selectedNote ? internal.selectedNote.title
                                                                 : (internal.selectedNotes.length == 1 ? internal.selectedNotes[0].title : "")
        }

        acceptButtonImage: "image://themedimage/images/btn_red_up"
        acceptButtonImagePressed:"image://themedimage/images/btn_red_dn"

        onAccepted: {   //TODO: check it
            if (internal.selectedNotes.length > 0) {
                for (var i = 0; i < internal.selectedNotes.length; ++i)
                    page.model.removeNote(internal.selectedNotes[i].id);
            } else {
                page.model.removeNote(internal.selectedNote.id);
            }
            deleteReportWindow.show();
            internal.selectMultiply = false;
            multiSelectRow.hide();
        }

        onRejected: internal.selectedNotes = []
    }

    ModalDialog {
        id: deleteReportWindow
        showCancelButton: false
        showAcceptButton: true
        acceptButtonText: qsTr("OK")
        title: (internal.selectedNotes.length > 1) ? qsTr("Notes deleted") : qsTr("Note deleted")
        content: Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: anchors.leftMargin
            text: {
                if (internal.selectedNotes.length > 1) {
                    return qsTr("%1 notes have been deleted").arg(internal.selectedNotes.length);
                } else if (internal.selectedNotes.length == 1) {
                    return qsTr("\"%1\" has been deleted").arg(internal.selectedNotes[0]);
                } else {
                    return qsTr("\"%1\" has been deleted").arg(internal.selectedNote);
                }
            }
        }
        onAccepted: internal.selectedNotes = []
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
        title: qsTr("Rename note")

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
                text: qsTr("%1/%2").arg(renameTextEntry.text.length).arg(window.maxCharactersCount)
            }
        }

        onOldNameChanged: renameTextEntry.text = oldName

        onAccepted: {
            var newName = renameTextEntry.text;
            if (page.model.noteExists(newName)) {   //TODO: do we need this checking now?
                informationDialog.info = qsTr("A note '%1' already exists.").arg(newName);
                informationDialog.show();
                return;
            }
            page.model.renameNote(internal.selectedNote.id, newName);
        }
    }

    ModalDialog {
        id: moveReportWindow

        acceptButtonText: qsTr("OK")
        title: qsTr("Note moved")

        property alias text: label.text

        content: Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: anchors.leftMargin
        }
    }

    QtObject {
        id: internal

        property variant selectedNote: null
        property variant selectedNotes: []
        property bool selectMultiply: false
        property variant selectedNotePoint: null

        property bool dndStarted: false
        property variant dndStartPoint: null
        property variant dndCurrentPoint: null
        property int dndOlButtonY: 0

        function addItem(item)
        {
            var list = selectedNotes;
            list.push(item);
            selectedNotes = list;
        }

        function removeItem(item)
        {
            var list = selectedNotes;
            for (var i = 0; i < list.length; ++i) {
                if (list[i].id == item.id) {
                    list.splice(i, 1);
                    break;
                }
            }
            selectedNotes = list;
        }

        function menuModel()
        {
            var res = [];
            res.push(qsTr("New note"));
            if(page.model.count >= 1)
                res.push(qsTr("Select multiple"));
            return res;
        }
    }
}

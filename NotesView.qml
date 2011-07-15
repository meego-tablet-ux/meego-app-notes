/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Ux.Components.Common 0.1
import MeeGo.Ux.Kernel 0.1
import MeeGo.App.Notes 0.1
import MeeGo.Sharing 0.1
import MeeGo.Sharing.UI 0.1
import MeeGo.Components 0.1

AppPage {
    id: page

    property alias model: listView.model

    signal noteClicked(variant note)

    TopItem {id: topItem}

    Theme {
        id: theme
    }

    SaveRestoreState {
        id: saveRestoreNotes

        onSaveRequired: {
            //for contextMenu
            setValue("contextMenuNotes.baseX", contextMenu.baseX);
            setValue("contextMenuNotes.baseY", contextMenu.baseY);
            setValue("contextMenuNotes.visible", contextMenu.visible);
            setValue("internal.selectedNoteId", internal.selectedNote != null ? 
internal.selectedNote.id : "");

            //for custom menu
            setValue("customMenuNotes.visible", customMenu.visible);

            //for add dialog
            setValue("addDialogNotes.visible", addDialog.visible);
            setValue("newNameNotes.text", newName.text);

            //for rename dialog
            setValue("renameWindowNotes.visible", renameWindow.visible);
            setValue("renameTextEntryNotes.text", renameTextEntry.text);

            //for information dialog
            setValue("informationDialogNotes.visible", informationDialog.visible);
            setValue("informationDialogNotes.info", informationDialog.info);

            //for deleteReportWindow
            setValue("deleteReportWindowNotes.visible", deleteReportWindow.visible);

            //for delete dialog
            setValue("deleteConfirmationDialogNotes.visible", deleteConfirmationDialog.visible);

            //for listView
            setValue("listViewNotes.contentY", listView.contentY);

            //selected notes
            var noteIds = new Array();
            for(var i=0; i<internal.selectedNotes.length; ++i) {
                noteIds[i] = internal.selectedNotes[i].id;
            }
            setValue("internal.selectedNotes", noteIds.join(","));

            //internal.selectMultiply
            setValue("internal.selectMultiplyNotes", internal.selectMultiply);

            //multiSelectRow
            setValue("multiSelectRowNotes.visible", multiSelectRow.visible);

            //custom menu position
            setValue("internal.customMenuNotesX", internal.customMenuX);
            setValue("internal.customMenuNotesY", internal.customMenuY);

            //context menu position
            setValue("internal.contextMenuNotesX", internal.contextMenuX);
            setValue("internal.contextMenuNotesY", internal.contextMenuY);

            //move menu
            setValue("notebookSelector.visible", notebookSelector.visible);
            setValue("internal.moveMenuX", internal.moveMenuX);
            setValue("internal.moveMenuY", internal.moveMenuY);

            sync();
        }
    }

    Component.onCompleted: {
        console.log("restoreRequired: " + saveRestoreNotes.restoreRequired);
        if (saveRestoreNotes.restoreRequired) {
            var contentY = saveRestoreNotes.value("listViewNotes.contentY");
            listView.contentY = contentY;

            internal.selectedNote = notesModel.noteById(saveRestoreNotes.value("internal.selectedNoteId"));

            if (saveRestoreNotes.value("contextMenuNotes.visible") == "true") {
                var mouseX = saveRestoreNotes.value("internal.contextMenuNotesX");
                var mouseY = saveRestoreNotes.value("internal.contextMenuNotesY");
                console.debug("context menu 0")
                contextMenu.setPosition(mouseX, mouseY);
                contextMenu.show();
            }

            if (saveRestoreNotes.value("customMenuNotes.visible") == "true") {
                var mouseX = saveRestoreNotes.value("internal.customMenuNotesX");
                var mouseY = saveRestoreNotes.value("internal.customMenuNotesY");
                customMenu.setPosition(mouseX, mouseY);
                customMenu.show();
            }

            //add dialog
            if (saveRestoreNotes.value("addDialogNotes.visible") == "true") {
                newName.text = saveRestoreNotes.value("newNameNotes.text");
                addDialog.show();
            }

            //rename dialog
            if (saveRestoreNotes.value("renameWindowNotes.visible") == "true") {
                renameTextEntry.text = saveRestoreNotes.value("renameTextEntryNotes.text");
                renameWindow.show();
            }

            //information dialog
            if (saveRestoreNotes.value("informationDialogNotes.visible") == "true") {
                informationDialog.info = saveRestoreNotes.value("informationDialogNotes.info");
                informationDialog.show();
            }

            //deleteReportWindow
            if (saveRestoreNotes.value("deleteReportWindowNotes.visible") == "true") {
                deleteReportWindow.show();
            }

            //delete dialog
            if (saveRestoreNotes.value("deleteConfirmationDialogNotes.visible") == "true") {
                deleteConfirmationDialog.show();
            }

            //selected notes
            var noteIds = new Array();
            noteIds = saveRestoreNotes.value("internal.selectedNotes").split(",");
            for(var i=0; i<noteIds.length; ++i) {
                internal.selectedNotes[i] = notesModel.noteById(noteIds[i]);
            }

            //internal.selectMultiply
            if (saveRestoreNotes.value("internal.selectMultiplyNotes") == "true")
		internal.selectMultiply = true;

            //multiSelectRow
            if (saveRestoreNotes.value("multiSelectRowNotes.visible") == "true")
                multiSelectRow.show();

            //move menu
            if (saveRestoreNotes.value("notebookSelector.visible") == "true") {
                notebookSelectorMenu.filterNoteBooksList();
                var mouseX = saveRestoreNotes.value("internal.moveMenuX", internal.moveMenuX);
                var mouseY = saveRestoreNotes.value("internal.moveMenuY", internal.moveMenuY);
                notebookSelector.setPosition(mouseX, mouseY);
                notebookSelector.show();
            }
        }
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
        helpContentVisible: (saveRestoreNotes.value("FirstTimeUseNotes") == undefined) && (listView.count == 0)
        visible: listView.count == 0

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
                var map = mapToItem(topItem.topItem, gesture.position.x, gesture.position.y);
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
                var shift = button2.height // it need for right position when check box visible
                var map = mapToItem(topItem.topItem, gesture.position.x + shift, gesture.position.y);
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
                    bgSourceUp: "image://themedimage/widgets/common/button/button-negative"
                    bgSourceDn: "image://themedimage/widgets/common/button/button-negative-pressed"
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
                    shareObj.setParam(uri, "subject", internal.selectedNote.title);
                    shareObj.showContext(qsTr("Email"), page.width / 2, page.height / 2);
                } else if (model[index] == contextMenu.moveChoice) {
                    notebookSelectorMenu.filterNoteBooksList();
                    notebookSelector.setPosition(internal.selectedNotePoint.x, internal.selectedNotePoint.y);
                    internal.moveMenuX = internal.selectedNotePoint.x;
                    internal.moveMenuY = internal.selectedNotePoint.y;
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
                    moveReportWindow.text = qsTr("%n note(s) have successfully been moved to \"%2\"", "", internal.selectedNotes.length).arg(newNotebook);
                } else {
                    //: %1 is moved note title
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
                //: %1 is current title length, %2 is max title length
                text: qsTr("%1/%2", "CharLeft").arg(newName.text.length).arg(window.maxCharactersCount)
            }
        }

        onAccepted: {
            //first time use feature
            if (saveRestoreNotes.value("FirstTimeUseNotes") == undefined) {
                saveRestoreNotes.setValue("FirstTimeUseNotes", false);
                saveRestoreNotes.sync();
            }

            var name = newName.text;
            newName.text = ""; //reset it for next time

            if (page.model.noteExists(name)) {  //TODO: do we need this checking now?
                //: %1 is note title
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
                  ? qsTr("Are you sure you want to delete these %n note(s)?", "", internal.selectedNotes.length)
                  //: %1 is note title
                  : qsTr("Are you sure you want to delete \"%1\"?").arg(componentText)

            property string componentText: internal.selectedNote ? internal.selectedNote.title
                                                                 : (internal.selectedNotes.length == 1 ? internal.selectedNotes[0].title : "")
        }

        acceptButtonImage: "image://themedimage/widgets/common/button/button-negative"
        acceptButtonImagePressed:"image://themedimage/widgets/common/button/button-negative-pressed"

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
                    return qsTr("%n note(s) have been deleted", "", internal.selectedNotes.length);
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
                text: qsTr("%1/%2", "CharLeft").arg(renameTextEntry.text.length).arg(window.maxCharactersCount)
            }
        }

        onVisibleChanged: if (visible) renameTextEntry.text = oldName

        onAccepted: {
            var newName = renameTextEntry.text;
            if (page.model.noteExists(newName)) {   //TODO: do we need this checking now?
                //: %1 is note name
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
        showCancelButton: false

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

        property int customMenuX: 0
        property int customMenuY: 0
        property int contextMenuX: 0
        property int contextMenuY: 0
        property int moveMenuX: 0
        property int moveMenuY: 0

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

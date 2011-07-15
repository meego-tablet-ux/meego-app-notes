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
import MeeGo.Components 0.1

AppPage {
    id: page

    property alias model: listView.model

    signal noteBookClicked(variant noteBook)

    TopItem {id: topItem}

    Theme {
        id: theme
    }

    SaveRestoreState {
        id: saveRestoreNotebooks

        onSaveRequired: {
            //for contextMenu
            setValue("contextMenu.baseX", contextMenu.baseX);
            setValue("contextMenu.baseY", contextMenu.baseY);
            setValue("contextMenu.visible", contextMenu.visible);
            setValue("internal.selectedNoteBookId", internal.selectedNoteBook.id);

            //for custom menu
            setValue("customMenu.visible", customMenu.visible);

            //for add dialog
            setValue("addDialog.visible", addDialog.visible);
            setValue("newName.text", newName.text);

            //for rename dialog
            setValue("renameWindow.visible", renameWindow.visible);
            setValue("renameTextEntry.text", renameTextEntry.text);

            //for information dialog
            setValue("informationDialog.visible", informationDialog.visible);
            setValue("informationDialog.info", informationDialog.info);

            //for deleteReportWindow
            setValue("deleteReportWindow.visible", deleteReportWindow.visible);

            //for delete dialog
            setValue("deleteConfirmationDialog.visible", deleteConfirmationDialog.visible);

            //for listView
            setValue("listView.contentY", listView.contentY);

            //selected notebooks
            var notebookIds = new Array();
            for(var i=0; i<internal.selectedNoteBooks.length; ++i) {
                notebookIds[i] = internal.selectedNoteBooks[i].id;
            }
            setValue("internal.selectedNoteBooks", notebookIds.join(","));

            //internal.selectMultiply
            setValue("internal.selectMultiply", internal.selectMultiply);

            //multiSelectRow
            setValue("multiSelectRow.visible", multiSelectRow.visible);

            //custom menu position
            setValue("internal.customMenuX", internal.customMenuX);
            setValue("internal.customMenuY", internal.customMenuY);

            //context menu position
            setValue("internal.contextMenuX", internal.contextMenuX);
            setValue("internal.contextMenuY", internal.contextMenuY);

            sync();
        }
    }

    Component.onCompleted: {
        console.log("restoreRequired: " + saveRestoreNotebooks.restoreRequired);
        if (saveRestoreNotebooks.restoreRequired) {
            listView.contentY = saveRestoreNotebooks.value("listView.contentY");

            internal.selectedNoteBook = noteBooksModel.noteBookById(saveRestoreNotebooks.value("internal.selectedNoteBookId"));

            if (saveRestoreNotebooks.value("contextMenu.visible") == "true") {
                var mouseX = saveRestoreNotebooks.value("internal.contextMenuX");
                var mouseY = saveRestoreNotebooks.value("internal.contextMenuY");
                contextMenu.setPosition(mouseX, mouseY);
                contextMenu.show();
            }

            if (saveRestoreNotebooks.value("customMenu.visible") == "true") {
                var mouseX = saveRestoreNotebooks.value("internal.customMenuX");
                var mouseY = saveRestoreNotebooks.value("internal.customMenuY");
                customMenu.setPosition(mouseX, mouseY);
                customMenu.show();
            }

            //add dialog
            if (saveRestoreNotebooks.value("addDialog.visible") == "true") {
		console.log("addDialog.show!");
                newName.text = saveRestoreNotebooks.value("newName.text");
                addDialog.show();
            }

            //rename dialog
            if (saveRestoreNotebooks.value("renameWindow.visible") == "true") {
                renameTextEntry.text = saveRestoreNotebooks.value("renameTextEntry.text");
                renameWindow.show();
            }

            //information diaxlog
            if (saveRestoreNotebooks.value("informationDialog.visible") == "true") {
                informationDialog.info = saveRestoreNotebooks.value("informationDialog.info");
                informationDialog.show();
            }

            //deleteReportWindow
            if (saveRestoreNotebooks.value("deleteReportWindow.visible") == "true") {
                deleteReportWindow.show();
            }

            //delete dialog
            if (saveRestoreNotebooks.value("deleteConfirmationDialog.visible") == "true") {
                deleteConfirmationDialog.show();
            }

            //selected notebooks
            var notebookIds = new Array();
            notebookIds = saveRestoreNotebooks.value("internal.selectedNoteBooks").split(",");
            for(var i=0; i<notebookIds.length; ++i) {
                internal.selectedNoteBooks[i] = noteBooksModel.noteBookById(notebookIds[i]);
            }

            //internal.selectMultiply
            if (saveRestoreNotebooks.value("internal.selectMultiply" == "true"))
		internal.selectMultiply = true;

            //multiSelectRow
            if (saveRestoreNotebooks.value("multiSelectRow.visible") == true)
                multiSelectRow.show();
        }
    }

    enableCustomActionMenu: true

    onActionMenuIconClicked: {
        if (window.pageStack.currentPage == page) {
            firstActionMenu.model = internal.menuModel();
            customMenu.setPosition(mouseX, mouseY);
            internal.customMenuX = mouseX;
            internal.customMenuY = mouseY;
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

        visible: (saveRestoreNotebooks.value("FirstTimeUseNotebooks") == undefined) && listView.model.count == 1
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
                var map = mapToItem(topItem.topItem, gesture.position.x, gesture.position.y);
                contextMenu.setPosition(map.x, map.y);
                internal.contextMenuX = map.x;
                internal.contextMenuY = map.y;
                contextMenu.show();
            }
        }
    }

    Component {
        id: notebookDelegate2

        NoteButton {
            id: noteButton
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
                var shift = noteButton.height // for correct position when check box visible
                var map = mapToItem(topItem.topItem, gesture.position.x + shift, gesture.position.y);
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
            if (saveRestoreNotebooks.value("FirstTimeUseNotebooks") == undefined) {
                saveRestoreNotebooks.setValue("FirstTimeUseNotebooks", false);
                saveRestoreNotebooks.sync();
            }

            var name = newName.text;
            newName.text = ""; //reset it for next time
            if (page.model.noteBookExists(name)) {  //TODO: do we need this checking now?
                informationDialog.info = qsTr("A Notebook '%1' already exists.").arg(name);
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
                  ? qsTr("Are you sure you want to delete these %n notebook(s)?", "", internal.selectedNoteBooks.length)
                    //: %1 is notebook title
                  : qsTr("Are you sure you want to delete \"%1\"?").arg(componentText)

	    wrapMode: Text.Wrap

            property string componentText: internal.selectedNoteBook ? internal.selectedNoteBook.title
                                                                     : (internal.selectedNoteBooks.length == 1 ? internal.selectedNoteBooks[0].title : "")
        }

        acceptButtonImage: "image://themedimage/widgets/common/button/button-negative"
        acceptButtonImagePressed:"image://themedimage/widgets/common/button/button-negative-pressed"

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
                    return qsTr("%n notebook(s) have been deleted", "", internal.selectedNoteBooks.length);
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
        title: qsTr("Rename notebook")

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
	    if (newName == oldName) return;
            if (page.model.noteBookExists(newName)) {   //TODO: do we need this checking now?
                //: %1 is notebook title
                informationDialog.info = qsTr("A notebook '%1' already exists.").arg(newName);
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
        property int customMenuX: 0
        property int customMenuY: 0
        property int contextMenuX: 0
        property int contextMenuY: 0

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
            return qsTr("%n note(s)", "", notesCount);
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

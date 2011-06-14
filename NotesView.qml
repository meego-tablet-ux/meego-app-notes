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
        helpContentVisible: dataHandler.isFirstTimeUse(false)

        onButtonClicked: addDialog.show()

        visible: dataHandler.isFirstTimeUse() && listView.model.count == 1
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
                model: [qsTr("All"), qsTr("A-Z")]
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

            //TODO: dnd
            onItemPanUpdated: {

            }

            //TODO: dnd
            onItemPanFinished: {

            }
        }
    }

    Component {
        id: notebookDelegate2

        NoteButton {
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

            //TODO: dnd
            onItemPanUpdated: {

            }

            //TODO: dnd
            onItemPanFinished: {

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
        title: qsTr("Create a new Note")
        acceptButtonText: qsTr("Create")
        cancelButtonText: qsTr("Cancel")
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
            if (dataHandler.isFirstTimeUse(false)) {
                dataHandler.unsetFirstTimeUse(false);
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
        title: (internal.selectedNotes.length > 1) ? qsTr("Delete Notes?") : qsTr("Delete Note?")
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
                    page.model.removeNoteById(internal.selectedNotes[i].id);
            } else {
                page.model.removeNoteById(internal.selectedNote.id);
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
        acceptButtonText: qsTr("OK");
        cancelButtonText: qsTr("Cancel");
        title: qsTr("Rename Note")
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
                informationDialog.info = qsTr("A Note '%1' already exists.").arg(newName);
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
            res.push(qsTr("New Note"));
            if(listView.model.count > 1)
                res.push(qsTr("Select Multiple"));
            return res;
        }
    }

//        Component {
//            id: noteDelegate

//            NoteButton {
//                id: note
//                //                x: 40;
//                width: listView.width
//                height: theme_listBackgroundPixelHeightTwo
//                z: 0
//                title: name
//                comment: prepareText(dataHandler.loadNoteData(notebook, name));
//                property string notePos: position
//                checkBoxVisible: false;
//                property int startY
//                showGrip: !dataHandler.isSorted()

//                function prepareText(text)
//                {
//                    var plainText = textEditHandler.toPlainText(text);
//                    var array = plainText.split('\n');
//                    var firstStr = array[0];
//                    var result = textEditHandler.setFontSize(firstStr, 0, firstStr.length, 11);
//                    return result;
//                }

//                MouseArea {
//                    anchors.fill: parent

//                    hoverEnabled: true

//                    onClicked: {
//                        selectedNote = name;
//                        selectedTitle = title;
//                        selectedIndex = index;
//                        listView.drag = false;
//                        noteClicked(name);
//                    }

//                    onPressAndHold:{
//                        selectedNote = name;
//                        selectedTitle = title;
//                        selectedIndex = index;
//                        var map = mapToItem(listView, mouseX, mouseY);
//                        //                        itemX = note.x + mouseX;
//                        //                        itemY = note.y + nameLabel.height + 50/*header*/ + mouseY;

//                        itemX = map.x;
//                        itemY = map.y + 50;

//                        menu.setPosition(map.x, map.y + 50);
//                        menu.show();
//                    }
//                }

//                MouseArea {
//                    anchors.right: parent.right
//                    width: parent.height * 2 //big thumbs + little screen = sad panda; so we be a little lenient
//                    height: parent.height
//                    enabled: !dataHandler.isSorted()

//                    drag.target: parent
//                    drag.axis: Drag.YAxis
//                    hoverEnabled: true

//                    onPressed: {
//                        parent.z = 100;
//                        listView.isDragging = true;
//                        parent.startY = parent.y;
//                    }


//                    onReleased: {
//                        parent.z = 1;
//                        listView.isDragging = false;
//                        listView.draggingItem = parent.title;
//                        var diff = parent.y - startY;
//                        diff = parseInt( diff /  parent.height);
//                        listView.newIndex = parseInt(parent.notePos) + diff;

//                        //console.debug("Going to move: " + listView.count + " from " + parent.notePos + " to " +  listView.newIndex);
//                        if ((parent.notePos != listView.newIndex) && (parseInt(listView.newIndex) > 0)) {
//                            if (parseInt(listView.newIndex) > listView.count)
//                                listView.newIndex = listView.count;

//                            listView.changePosition();
//                        } else {
//                            //just stupid workaround
//                            var prev = listView.model.noteName;
//                            listView.model.noteName = "something else"; //this is a hack to force the model to update (no need for translation)
//                            listView.model.noteName = prev;
//                        }
//                    }
//                }
//            }
//        }

//        Component {
//            id: noteDelegate2

//            NoteButton {
//                id: note2
//                //                x: 40;
//                width: listView.width
//                height: theme_listBackgroundPixelHeightTwo
//                z: 0
//                title: name
//                comment: prepareText(dataHandler.loadNoteData(notebook, name));
//                property string notePos: position
//                checkBoxVisible: true;
//                showGrip: !dataHandler.isSorted()

//                function prepareText(text)
//                {
//                    var plainText = textEditHandler.toPlainText(text);
//                    var array = plainText.split('\n');
//                    var firstStr = array[0];
//                    var result = textEditHandler.setFontSize(firstStr, 0, firstStr.length, 11);
//                    return result;
//                }

////                onNoteSelected: {
////                    var tmpList = selectedItems;
////                    tmpList.push(noteName);
////                    selectedItems = tmpList;
////                }

////                onNoteDeselected: {
////                    var tmpList = selectedItems;
////                    tmpList = dataHandler.removeFromString(tmpList, noteName);
////                    selectedItems = tmpList;
////                }


//                MouseArea {
//                    anchors.left:parent.left
//                    anchors.leftMargin: parent.checkBoxWidth;
//                    anchors.right:parent.right
//                    anchors.top:parent.top
//                    anchors.bottom:parent.bottom

//                    hoverEnabled: true

//                    onClicked: {
//                        selectedNote = name;
//                        selectedTitle = title;
//                        selectedIndex = index;
//                        listView.drag = false;
//                        noteClicked(name);
//                    }

//                    onPressAndHold:{
//                        selectedNote = name;
//                        selectedTitle = title;
//                        selectedIndex = index;
//                        itemX = note.x + mouseX;
//                        itemY = note.y + nameLabel.height + 50/*header*/ + mouseY;
//                        menu.setPosition(itemX, itemY);
//                        menu.show();
//                    }
//                }

//                MouseArea {
//                    anchors.right: parent.right
//                    width: (parent.height * 2) //Because we want to be lenient with peopel who have big thumbs
//                    height: parent.height
//                    enabled: !dataHandler.isSorted()

//                    drag.target: parent
//                    drag.axis: Drag.YAxis
//                    hoverEnabled: true

//                    onPressed: {
//                        parent.z = 100;
//                        listView.isDragging = true;
//                        parent.startY = parent.y;
//                    }


//                    onReleased: {
//                        parent.z = 1;
//                        listView.isDragging = false;
//                        listView.draggingItem = parent.title;
//                        var diff = parent.y - startY;
//                        diff = parseInt( diff /  parent.height);
//                        listView.newIndex = parent.notePos + diff;

//                        //console.debug("Going to move: " + listView.draggingItem + " from " + parent.notePos + " to " +  listView.newIndex);
//                        listView.changePosition();
//                    }
//                }
//            }
//        }
}

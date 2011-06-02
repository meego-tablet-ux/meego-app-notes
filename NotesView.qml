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
    id: noteListPage

    property string notebook  
    property string newNotebook
    property alias caption: nameLabel.text
    property string selectedNote
    property string selectedTitle
    property string selectedIndex
    property alias model: listView.model
    property int itemX;
    property int itemY;
    property bool showCheckBox: dataHandler.getCheckBox()
    property variant selectedItems: [];

    signal noteClicked(string name)
    signal noteLongPressed(string name)
    signal closeWindow();
    signal updateView();

    enableCustomActionMenu: true

    onActionMenuIconClicked: {
        if (window.pageStack.currentPage == noteListPage) {
            notesCustomMenu.setPosition(mouseX, mouseY);
            notesCustomMenu.show();
        }
    }

    Loader {
        id: blankStateScreenLoader

        sourceComponent: listView.count == 0? blankStateScreenComponent : undefined
    }

    Component {
        id: blankStateScreenComponent

        BlankStateScreen {
            id: blankStateScreen
            width: listView.width
            height: listView.height
            parent: listView
            y: 65

            mainTitleText: qsTr("This notebook is empty")
            buttonText: qsTr("Create the first note")
            firstHelpTitle: qsTr("How do I create notes?")
            secondHelpTitle: qsTr("Share your notes by email")
            firstHelpText: qsTr("Tap the 'Create the first note' button. You can also tap the icon in the top right corner of the screen, then select 'New note'.")
            secondHelpText: qsTr("To send a note by email, tap and hold the note you want to send, then select 'Email'.")
            helpContentVisible: dataHandler.isFirstTimeUse(false)

            onButtonClicked: {
                addDialog.show();
            }
        }
    }

    ContextMenu {
        id: notesCustomMenu
        content: Column {
            ActionMenu {
                id: firstActionMenu
                model: {
                    if((listView.count < 2) || (showCheckBox) ) {
                        return [qsTr("New Note")];
                    } else {
                        return [qsTr("New Note"), qsTr("Select Multiple")];
                    }
                }
                onTriggered: {
                    if(index == 0) {
                        addDialog.show();
                    } else if(index ==1) {
                        showCheckBox = true;
                        multiSelectRow.show();
                    }
                    notesCustomMenu.hide();
                }//ontriggered
            }//action menu
            Text {
                id: viewByText
                anchors.left: parent.left
                anchors.leftMargin: 5
                text: qsTr("View by:")
                font.pixelSize: theme_fontPixelSizeLarge
                color: theme_fontColorNormal
            }
            ActionMenu {
                id: secondActionMenu

                function forceUpdate()
                {
                    var prev = listView.model.notebookName;
                    listView.model.notebookName = "something else"; //this is a hack to force the model to update (no need for translation)
                    listView.model.notebookName = prev;
                }

                model: [qsTr("All"), qsTr("A-Z")]
                onTriggered: {
                    if(index == 0) {
                        dataHandler.setSort(false);
                        forceUpdate();
                    } else if(index == 1) {
                        dataHandler.setSort(true);
                        notebooksModel.sort();
                        forceUpdate();
                    }
                    notesCustomMenu.hide();
                }//ontriggered
            }

        }
    }

    TextEditHandler {
        id: textEditHandler
    }

    onNotebookChanged: {
        console.log("noteListPage::onNotebookChanged");
        console.log(notebook);
    }

    onNoteLongPressed: {
        menu.visible = true;
    }

    Item {
        id: content
        anchors.fill: noteListPage

        Text {
            id: nameLabel

            text: qsTr("Test Notebook Name");
            font.pointSize: 16;
            smooth: true

            anchors { left: parent.left;
                right: parent.right;
                top: parent.top;
                leftMargin: 20
            }
        }

        Component {
            id: noteDelegate

            NoteButton {
                id: note
                //                x: 40;
                width: listView.width
                height: theme_listBackgroundPixelHeightTwo
                z: 0
                title: name
                comment: prepareText(dataHandler.loadNoteData(notebook, name));
                property string notePos: position
                checkBoxVisible: false;
                property int startY
                showGrip: !dataHandler.isSorted()

                function prepareText(text)
                {
                    var plainText = textEditHandler.toPlainText(text);
                    var array = plainText.split('\n');
                    var firstStr = array[0];
                    var result = textEditHandler.setFontSize(firstStr, 0, firstStr.length, 11);
                    return result;
                }

                MouseArea {
                    anchors.fill: parent

                    hoverEnabled: true

                    onClicked: {
                        selectedNote = name;
                        selectedTitle = title;
                        selectedIndex = index;
                        listView.drag = false;
                        noteClicked(name);
                    }

                    onPressAndHold:{
                        selectedNote = name;
                        selectedTitle = title;
                        selectedIndex = index;
                        var map = mapToItem(listView, mouseX, mouseY);
                        //                        itemX = note.x + mouseX;
                        //                        itemY = note.y + nameLabel.height + 50/*header*/ + mouseY;

                        itemX = map.x;
                        itemY = map.y + 50;

                        menu.setPosition(map.x, map.y + 50);
                        menu.show();
                    }
                }

                MouseArea {
                    anchors.right: parent.right
                    width: parent.height * 2 //big thumbs + little screen = sad panda; so we be a little lenient
                    height: parent.height
                    enabled: !dataHandler.isSorted()

                    drag.target: parent
                    drag.axis: Drag.YAxis
                    hoverEnabled: true

                    onPressed: {
                        parent.z = 100;
                        listView.isDragging = true;
                        parent.startY = parent.y;
                    }


                    onReleased: {
                        parent.z = 1;
                        listView.isDragging = false;
                        listView.draggingItem = parent.title;
                        var diff = parent.y - startY;
                        diff = parseInt( diff /  parent.height);
                        listView.newIndex = parseInt(parent.notePos) + diff;

                        //console.debug("Going to move: " + listView.count + " from " + parent.notePos + " to " +  listView.newIndex);
                        if ((parent.notePos != listView.newIndex) && (parseInt(listView.newIndex) > 0)) {
                            if (parseInt(listView.newIndex) > listView.count)
                                listView.newIndex = listView.count;

                            listView.changePosition();
                        } else {
                            //just stupid workaround
                            var prev = listView.model.notebookName;
                            listView.model.notebookName = "something else"; //this is a hack to force the model to update (no need for translation)
                            listView.model.notebookName = prev;
                        }
                    }
                }
            }
        }

        Component {
            id: noteDelegate2

            NoteButton {
                id: note2
                //                x: 40;
                width: listView.width
                height: theme_listBackgroundPixelHeightTwo
                z: 0
                title: name
                comment: prepareText(dataHandler.loadNoteData(notebook, name));
                property string notePos: position
                checkBoxVisible: true;
                showGrip: !dataHandler.isSorted()

                function prepareText(text)
                {
                    var plainText = textEditHandler.toPlainText(text);
                    var array = plainText.split('\n');
                    var firstStr = array[0];
                    var result = textEditHandler.setFontSize(firstStr, 0, firstStr.length, 11);
                    return result;
                }

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

                    hoverEnabled: true

                    onClicked: {
                        selectedNote = name;
                        selectedTitle = title;
                        selectedIndex = index;
                        listView.drag = false;
                        noteClicked(name);
                    }

                    onPressAndHold:{
                        selectedNote = name;
                        selectedTitle = title;
                        selectedIndex = index;
                        itemX = note.x + mouseX;
                        itemY = note.y + nameLabel.height + 50/*header*/ + mouseY;
                        menu.setPosition(itemX, itemY);
                        menu.show();
                    }
                }

                MouseArea {
                    anchors.right: parent.right
                    width: (parent.height * 2) //Because we want to be lenient with peopel who have big thumbs
                    height: parent.height
                    enabled: !dataHandler.isSorted()

                    drag.target: parent
                    drag.axis: Drag.YAxis
                    hoverEnabled: true

                    onPressed: {
                        parent.z = 100;
                        listView.isDragging = true;
                        parent.startY = parent.y;
                    }


                    onReleased: {
                        parent.z = 1;
                        listView.isDragging = false;
                        listView.draggingItem = parent.title;
                        var diff = parent.y - startY;
                        diff = parseInt( diff /  parent.height);
                        listView.newIndex = parent.notePos + diff;

                        //console.debug("Going to move: " + listView.draggingItem + " from " + parent.notePos + " to " +  listView.newIndex);
                        listView.changePosition();
                    }
                }
            }
        }

        ListView {
            id: listView

            anchors { left: parent.left;
                right: parent.right;
                top: nameLabel.bottom;
            }

            height: parent.height - nameLabel.height;
            delegate: showCheckBox ? noteDelegate2 : noteDelegate;
            model: noteModel
            interactive: contentHeight > listView.height
            header:
                Item {
                width:listView.width
                height: 50

                Image {
                    id: separator
                    width: parent.width
                    anchors.bottom: parent.bottom
                    source: "image://theme/tasks/ln_grey_l"
                }
            }
            footer:
                Item {
                width:listView.width
                height: 50
            }

            clip: true
            spacing: 1
            property bool drag: false
            property string draggingItem: ""
            property string newIndex: ""
            property bool isDragging: false

            function changePosition()
            {
                dataHandler.changeNotePosition(noteListPage.caption, draggingItem, newIndex);
                var prev = model.notebookName;
                model.notebookName = "something else"; //this is a hack to force the model to update (no need for translation)
                model.notebookName = prev;
            }
        }

        BottomToolBar {
            id: multiSelectRow
            anchors.bottom: listView.bottom
            width: listView.width

            content: BottomToolBarRow {
                centerContent: Row {
                    spacing: 10
                    Button {
                        id: deleteButton
                        text: qsTr("Delete")
                        enabled: selectedItems.length > 0
                        bgSourceUp: "image://themedimage/images/btn_red_up"
                        bgSourceDn: "image://themedimage/images/btn_red_dn"
                        onClicked: {
                            deleteConfirmationDialog.show();
                            showCheckBox = false;
                            multiSelectRow.hide();
                        }
                    }
                    Button {
                        id: cancelButton
                        text: qsTr("Cancel")
                        onClicked: {
                            multiSelectRow.hide();
                            showCheckBox = false;
                            selectedItems = [];
                        }
                    }
                }
            }
        }

    }


    ContextMenu {
        id: menu

        property string openChoice: qsTr("Open");
        property string emailChoice: qsTr("Email");
        property string moveChoice: qsTr("Move");
        property string deleteChoice: qsTr("Delete");
        property string renameChoice: qsTr("Rename");

        ShareObj {
            id: shareObj
            shareType: MeeGoUXSharingClientQmlObj.ShareTypeText
        }

        property variant choices: [ openChoice, emailChoice, moveChoice, deleteChoice, renameChoice ]
        content: ActionMenu {
            model:  menu.choices
            onTriggered: {
                if (model[index] == menu.openChoice)
                {
                    noteClicked(selectedNote);
                }
                else if (model[index] == menu.emailChoice)
                {
                    var uri = noteListPage.model.dumpNote(noteListPage.selectedIndex);
                    shareObj.clearItems();
                    shareObj.addItem(uri);
                    shareObj.setParam(uri, "subject", noteListPage.selectedTitle);
                    shareObj.showContext(qsTr("Email"), noteListPage.width / 2, noteListPage.height / 2);
                }
                else if (model[index] == menu.moveChoice)
                {
                    notebookSelector.setPosition(itemX, itemY);
                    notebookSelector.show();
                }
                else if (model[index] == menu.deleteChoice)
                {
                    if (selectedItems.length > 1)
                    {
                        deleteReportWindow.text = qsTr("%1 notes have been deleted").arg(selectedItems.length);
                    }
                    else if (selectedItems.length == 1)
                    {
                        deleteReportWindow.text = qsTr("\"%1\" has been deleted").arg(selectedItems[0]);
                    }
                    else
                    {
                        deleteReportWindow.text = qsTr("\"%1\" has been deleted").arg(selectedNote);
                    }

                    deleteConfirmationDialog.show();
                }
                else if(model[index] == menu.renameChoice) {
                    renameWindow.oldName =  selectedNote;
                    renameWindow.opacity = 1;
                }

                menu.hide();
            }
        }
    }

    ContextMenu {
        id: notebookSelector

        //Removes current notebook's name from a list of notebooks.
        //Fixes moving a note to current notebook and prevent vanishing of the note.
        function filterNoteBooksList()
        {
            var res = [];
            var list = dataHandler.getNoteBooks();
            for (var i = 0; i < list.length; ++i) {
                if (list[i] == model.notebookName)
                    continue;
                res.push(list[i]);
            }
            return res;
        }

        property variant choices: filterNoteBooksList()//dataHandler.getNoteBooks();
        content: ActionMenu {
            model: notebookSelector.choices
            onTriggered: {
                newNotebook = model[index];

                if (selectedItems.length > 1)
                {
                    moveReportWindow.text = qsTr("%1 notes have successfully been moved to \"%2\"").arg(selectedItems.length).arg(newNotebook);
                }
                else
                {
                    moveReportWindow.text = qsTr("\"%1\" has successfully been moved to \"%2\"").arg(selectedNote).arg(newNotebook);
                }

                if (selectedItems.length > 0)
                {
                    dataHandler.moveNotes(noteListPage.caption, selectedItems, newNotebook);
                    selectedItems = [];
                }
                else
                {
                    dataHandler.moveNote(noteListPage.caption, selectedNote, newNotebook);
                }

                notebookSelector.hide();
                moveReportWindow.opacity = 1;
            }

        }
    }


    Loader {
        id: addDialogLoader
        anchors.fill: parent
    }

    ModalDialog {
        id: addDialog
        title: qsTr("Create a new Note");
        acceptButtonText: qsTr("Create");
        cancelButtonText: qsTr("Cancel");
        content: TextEntry {
            id: newName
            defaultText: qsTr("Note name");
            anchors.fill: parent
        }
        onAccepted: {
            //workaround (max length of the file name - 256)
            if (newName.text.length > 256)
                newName.text = text.slice(0, 255);

            //first time use feature
            if (dataHandler.isFirstTimeUse(false)) {
                dataHandler.unsetFirstTimeUse(false);
                //blankStateScreen.helpContentVisible = false;
            }

            if (!dataHandler.noteExists(model.notebookName, newName.text)) {
                dataHandler.createNote(noteListPage.caption, newName.text, "");
                noteClicked(newName.text);
                addDialogLoader.sourceComponent = undefined;
            } else {
                informationDialog.info = qsTr("A Note <b>'%1'</b> already exists.").arg(newName.text);
                informationDialog.show();
            }
            newName.text= "";
        }
    }

    ModalDialog {
        id: informationDialog
        property alias info: textInfo.text
        showCancelButton: false
        showAcceptButton: true
        acceptButtonText: qsTr("OK");
        content: Text {
            id: textInfo
            anchors.fill: parent
        }
    }

    ModalDialog {
        id: deleteConfirmationDialog

        acceptButtonText: qsTr("Delete");

        title: (selectedItems.length > 1) ?
                   qsTr("Are you sure you want to delete these %1 notes?").arg(selectedItems.length)
                 : qsTr("Are you sure you want to delete \"%1\"?").arg(componentText)
        property string componentText: (selectedItems.length > 0) ? selectedItems[0] : selectedNote;

        acceptButtonImage: "image://themedimage/images/btn_red_up"
        acceptButtonImagePressed:"image://themedimage/images/btn_red_dn"

        onAccepted: {
            if (selectedItems.length > 0)
            {
                dataHandler.deleteNotes(noteListPage.caption, selectedItems);
            }
            else
            {
                dataHandler.deleteNote(noteListPage.caption, selectedNote);
            }
            hide();
            deleteReportWindow.show();
        }
        onRejected: {
            selectedItems = [];
        }
    }

    ModalDialog {
        id: deleteReportWindow
        acceptButtonText: qsTr("OK");
        title: (selectedItems.length > 1) ? qsTr("Notes deleted") : qsTr("Note deleted")
        content: Text  {
            text: {
                if(selectedItems.length > 1) {
                    return qsTr("%1 notes have been deleted").arg(selectedItems.length);
                } else if(selectedItems.length == 1) {
                    return qsTr("%1 has been deleted").arg(selectedItems[0]);
                } else  {
                    return qsTr("%1 has been deleted").arg(selectedNote);
                }
            }
        }

        onAccepted:
        {
            selectedItems = [];
            updateView();
        }
    }

    ModalDialog {
        id: renameWindow
        acceptButtonText: qsTr("OK");
        cancelButtonText:  qsTr("Cancel");
        title: qsTr("Rename Note")
        property string oldName

        content: TextEntry {
            id: newNameTextEntry
            defaultText: renameWindow.oldName
        }

        onAccepted: {
            var newName = newNameTextEntry.text;
            var noteNames = dataHandler.getNoteNames(model.notebookName);
            for(var i=0;i<noteNames.length;i++) {
                if(noteNames[i] == newName) {
                    newName = qsTr("%1 (Renamed Note)").arg(newName);
                }
            }
            var noteData = dataHandler.loadNoteData(model.notebookName,oldName);
            dataHandler.deleteNote(model.notebookName,oldName);
            dataHandler.createNote(model.notebookName,newName,noteData);
            dataHandler.changeNotePosition(model.notebookName, newName, selectedIndex);

            //stupid workaround for updating the model
            var prev = model.notebookName;
            model.notebookName = "something else"; //this is a hack to force the model to update (no need for translation)
            model.notebookName = prev;

            updateView();
        }
    }

    ModalDialog {
        id: moveReportWindow

        acceptButtonText: qsTr("OK");
        title: qsTr("Note moved");

        onAccepted: {
            updateView();
        }
    }
}

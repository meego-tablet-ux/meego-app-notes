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

    menuContent: Column {
        ActionMenu {
                id: actionsAddNote
                model:{
                    if((listView.count == 1) || (showCheckBox) ) {
                        return [qsTr("New Note")];
                    } else {
                        return [qsTr("New Note"), qsTr("Select Multiple")];
                    }
                }
                onTriggered: {
                    if(index == 0) {
                        addDialogLoader.sourceComponent = addDialogComponent;
                        addDialogLoader.item.parent = noteListPage;
                    } else if(index ==1) {
                        showCheckBox = true;
                        multiSelectRow.opacity = 1;
                    }
                    noteListPage.closeMenu();
                }//ontriggered
            }//action menu

            Text {
                id: viewByText
                x: actionsAddNote.textMargin
                font.pixelSize: theme_contextMenuFontPixelSize
                text: qsTr("View by:")
            }
            ActionMenu {
                id: actions
                property string allChoice: qsTr("All");
                property string atozChoice: qsTr("Alphabetical order");

                model: [allChoice, atozChoice]
                onTriggered: {
                    if(index == 0) {
                        console.log(allChoice); //XXX
                        dataHandler.setSort(false);
                        updateView();
                    } else if(index == 1) {
                        console.log(atozChoice); //XXX
                        dataHandler.setSort(true);
                        noteModel.sort();
                    }
                    noteListPage.closeMenu();
                }//ontriggered
            }//action menu
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
        anchors.fill: noteListPage.content

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
                x: 40;
                width: listView.width - 80;
                height: theme_listBackgroundPixelHeightTwo
                z: 0
                title: name
                comment: prepareText(dataHandler.loadNoteData(notebook, name));
                property string notePos: position
                checkBoxVisible: false;
                property int startY

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
                        itemX = note.x + mouseX;
                        itemY = note.y + nameLabel.height + 50/*header*/ + mouseY;
                        menu.menuX = note.x + mouseX;
                        menu.menuY = note.y + nameLabel.height + 50/*header*/ + mouseY;
                        menu.visible = true;
                    }
                }

                MouseArea {
                    anchors.right: parent.right
                    width: parent.height
                    height: parent.height

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
                        if ((parent.notePos != listView.newIndex) && (parseInt(listView.newIndex) > 0)
                                && (parseInt(listView.newIndex) <= listView.count)) {
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
                x: 40;
                width: listView.width - 80;
                height: theme_listBackgroundPixelHeightTwo
                z: 0
                title: name
                comment: prepareText(dataHandler.loadNoteData(notebook, name));
                property string notePos: position
                checkBoxVisible: true;

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
                        menu.menuX = note.x + mouseX;
                        menu.menuY = note.y + nameLabel.height + 50/*header*/ + mouseY;
                        menu.visible = true;
                    }
                }

                MouseArea {
                    anchors.right: parent.right
                    width: parent.height
                    height: parent.height

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
                    selectedItems = [];
                }
            }
        }
    }

    ContextMenu {
        id: menu
        visible: false
        menuX: 0
        menuY: 0
        width: 150
        height: 300

        property string openChoice: qsTr("Open");
        property string emailChoice: qsTr("Email");
        property string moveChoice: qsTr("Move");
        property string deleteChoice: qsTr("Delete");
        property string renameChoice: qsTr("Rename");

        property variant choices: [ openChoice, emailChoice, moveChoice, deleteChoice, renameChoice ]
        model: choices

        onTriggered: {
            console.log("triggered: " + index);
            if (model[index] == openChoice)
            {
                noteClicked(selectedNote);
            }
            else if (model[index] == emailChoice)
            {
                shareDialog.opacity = 1;
            }
            else if (model[index] == moveChoice)
            {
                notebookSelector.menuX = itemX;
                notebookSelector.menuY = itemY;
                notebookSelector.visible = true;
            }
            else if (model[index] == deleteChoice)
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

                deleteConfirmationDialog.opacity = 1;
            }
            else if(model[index] == renameChoice) {
                renameWindow.oldName =  selectedNote;
                renameWindow.opacity = 1;
            }
        }
    }

    ContextMenu {
        id: notebookSelector

        visible: false

        property variant choices: dataHandler.getNoteBooks();
        model: choices

        onTriggered: {
            newNotebook = model[index];

            if (selectedItems.length > 1)
            {
                moveReportWindow.text = qsTr("%1 notes have successfully\nbeen moved to \"%2\"").arg(selectedItems.length).arg(newNotebook);
            }
            else
            {
                moveReportWindow.text = qsTr("\"%1\" has successfully\nbeen moved to \"%2\"").arg(selectedNote).arg(newNotebook);
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

            visible = false;
            moveReportWindow.opacity = 1;
        }
    }

    ShareNote {
        id: shareDialog
        opacity: 0;
        anchors.centerIn: parent
        //focus: true;
        dialogTitle: qsTr("Email note \"%1\"").arg(selectedNote);

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
            menuWidth: 260
            dialogTitle: qsTr("Create a new Note");
            buttonText: qsTr("Create");
            button2Text: qsTr("Cancel");
            defaultText: qsTr("Note name");
            onButton1Clicked: {
                dataHandler.createNote(noteListPage.caption, text, "");
                noteClicked(text);
                addDialogLoader.sourceComponent = undefined;
            }

            onButton2Clicked: {
                addDialogLoader.sourceComponent = undefined;
            }
        }
    }

    ConfirmDeleteDialog {
        id: deleteConfirmationDialog

        opacity: 0

        leftButtonText: qsTr("Delete");
        rightButtonText: qsTr("Cancel");
        dialogTitle: qsTr("Delete?");
        property string componentText: (selectedItems.length > 0) ? selectedItems[0] : selectedNote;

        Component {
            id: textComp

            Text {
                text: qsTr("Are you sure you want to\ndelete \"%1\"?").arg(componentText);
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }

        Component {
            id: textComp2

            Text {  
                text: qsTr("Are you sure you want to\ndelete these %1 notes?").arg(selectedItems.length);
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }

        //contentLoader.sourceComponent: textComp
        contentLoader.sourceComponent: (selectedItems.length > 1) ? textComp2 : textComp

        onDialogClicked: {
            if (button == 1) {
                if (selectedItems.length > 0)
                {
                    dataHandler.deleteNotes(noteListPage.caption, selectedItems);
                }
                else
                {
                    dataHandler.deleteNote(noteListPage.caption, selectedNote);
                }
                opacity = 0;
                deleteReportWindow.opacity = 1;
            }
            else if (button == 2) {
                // No
                opacity = 0;
                selectedItems = [];
            }
        }
    }

    DeleteMoveNotificationDialog {
        id: deleteReportWindow
        menuHeight: 125
        menuWidth: 250
        opacity: 0;
        buttonText: qsTr("OK");
        dialogTitle: (selectedItems.length > 1) ? qsTr("Notes deleted") : qsTr("Note deleted")
        text:  {
            if(selectedItems.length > 1) {
                return qsTr("%1 notes have been deleted").arg(selectedItems.length);
            } else if(selectedItems.length == 1) {
                return qsTr("%1 has been deleted").arg(selectedItems[0]);
            } else  {
                return qsTr("%1 has been deleted").arg(selectedNote);
            }
        }

        onDialogClicked:
        {
            selectedItems = [];
            opacity = 0;
            updateView();
        }
    }

    TwoButtonsModalDialog {
        id: renameWindow
        opacity: 0;
        buttonText:qsTr("OK");
        button2Text:  qsTr("Cancel");
        dialogTitle: qsTr("Rename Note")
        property string oldName
        text: oldName
        menuHeight: 150
        menuWidth: 360
        onButton1Clicked: {
            var newName = renameWindow.text;
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

            opacity = 0;
            updateView();
        }
        onButton2Clicked: {
            opacity = 0;
        }
    }

    DeleteMoveNotificationDialog {
        id: moveReportWindow
        menuHeight: 145
        menuWidth: 270
        opacity: 0;

        buttonText: qsTr("OK");
        dialogTitle: qsTr("Note moved");
        text:qsTr("\"%1\" has successfully\nbeen moved to \"%2\"").arg(selectedNote).arg(newNotebook);

        onDialogClicked:
        {
            opacity = 0;
            updateView();
        }
    }
}

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

    property variant note: null
    property variant model: null

    signal windowClosed()

    SaveRestoreState {
        id: saveRestoreNoteDetail

        onSaveRequired: {
            setValue("deleteConfirmationDialogDetail.visible", deleteConfirmationDialog.visible);
            sync();
        }
    }

    Component.onCompleted: {
        if (saveRestoreNoteDetail.restoreRequired) {
            if (saveRestoreNoteDetail.value("deleteConfirmationDialogDetail.visible"))
                deleteConfirmationDialog.show();
        }
    }

    actionMenuModel: [qsTr("Save"), qsTr("Delete")]

    actionMenuPayload: [0, 1]

    onActionMenuTriggered: {
        if(selectedItem == 0) {
            manualSaveTimer.running = true;
            page.model.setNoteText(page.note.id, editor.text);
        } else if(selectedItem == 1) {
            deleteConfirmationDialog.show();
        }
    }

    NoteButton {
        id: noteBookNameLabel

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        color: "lightgray"

        title: page.note ? page.note.title : ""
        comment: ""
        itemData: page.note
        checkBoxVisible: false
        showGrip: false
    }

    TextField {
        id: editor

        anchors.top: noteBookNameLabel.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20

        smooth:true;
        text: page.note ? page.note.html : ""
        defaultText: qsTr("Start typing a new note.")
    }

    Timer {
        id: saveTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if(!manualSaveTimer.running && !deleteConfirmationDialog.visible)
                page.model.setNoteText(page.note.id, editor.text);
        }
    }

    Timer {
        id: manualSaveTimer
        interval: 5000
    }

    ModalDialog {
        id: deleteConfirmationDialog
        acceptButtonText: qsTr("Yes")
        cancelButtonText: qsTr("No")
        title: qsTr("Delete?")

        content: Text {
            text: qsTr("Do you want to delete this note?")
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
        }

        onAccepted: {
            page.model.removeNote(page.note.id);
            hide();
            page.windowClosed();
        }

        onRejected: hide()
    }
}


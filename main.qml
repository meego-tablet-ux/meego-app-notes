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

Window {
    id: scene
    title: qsTr("Notes")

    property string notebookName
    property string noteName
    property string noteData

    applicationPage: notebookList

    onNotebookNameChanged: {
        noteModel.notebookName = notebookName;
    }

    DataHandler {
        id: dataHandler
    }

    NotebooksModel {
        id: notebooksModel
        dataHandler: dataHandler
    }

    NoteModel {
        id: noteModel
        dataHandler: dataHandler
    }

    Component {
        id: notebookList

        NotebooksView {
            id: notebooksView
	    anchors.fill: parent
            title: qsTr("Notes");

            onNotebookClicked: {
                scene.addApplicationPage(noteList);
                console.log(scene.applicationPage);
                notebookName = name;
            }

        }
    }

    Component {
        id: noteList

        NotesView {
	    id: notesView
	    anchors.fill: parent
            title: qsTr("Notes");
            caption: notebookName
            model: noteModel

            onNoteClicked:
            {
                scene.addApplicationPage(noteDetailPage);
                console.log(scene.applicationPage);
                noteName = name;
            }

            onCloseWindow:
            {
                scene.applicationPage = notebookList;
            }

        }
    }

    Component {
        id: noteDetailPage

        NoteDetail {
            id: noteDetail
            anchors.fill: parent
            notebookID: scene.notebookName
            noteName: scene.noteName
            caption: noteName

            onCloseWindow:
            {
                scene.applicationPage = notebookList;
                scene.addApplicationPage(noteList);
            }
        }
    }
}

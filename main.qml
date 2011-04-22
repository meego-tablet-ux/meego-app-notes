/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Labs.Components 0.1
import MeeGo.Components 0.1 as UX
import MeeGo.App.Notes 0.1

Window {
    id: window
    title: qsTr("Notes")          //labs
    filterModel: filterModelList  //labs

    property string notebookName
    property string noteName
    property string noteData
    property variant filterModelList: [qsTr("All"), qsTr("Alphabetical order")]

    applicationPage: notebookList //labs

    onNotebookNameChanged: {
        noteModel.notebookName = notebookName;
    }

    onFilterTriggered: {  //labs
        if(index == 0) {
            dataHandler.setSort(false);
            console.log("DisableSort");
        } else if(index == 1) {
            dataHandler.setSort(true);
            console.log("EnableSort");
            if (applicationPage == notebookList) {
                notebooksModel.sort();
                console.log("notebooksModel");
            } else if(applicationPage == noteList) {
                noteModel.sort();
                console.log("noteModel");
            }
        }
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
            title: qsTr("Notes")

            onNotebookClicked: {
                window.addApplicationPage(noteList);
                notebookName = name;
            }

        }
    }

    Component {
        id: noteList

        NotesView {
            id: notesView
            anchors.fill: parent
            title: qsTr("Notes")
            caption: notebookName
            model: noteModel

            onNoteClicked: {
                window.addApplicationPage(noteDetailPage);
                noteName = name;
                filterModel = [];
            }

            onCloseWindow: {
                window.applicationPage = notebookList;
            }

        }
    }

    Component {
        id: noteDetailPage

        NoteDetail {
            id: noteDetail
            anchors.fill: parent
            notebookID: window.notebookName
            noteName: window.noteName
            caption: noteName

            onCloseWindow:
            {
                window.applicationPage = notebookList;
                window.addApplicationPage(noteList);
                filterModel = filterModelList;
            }
        }
    }
}

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

Window {
    id: window
    toolBarTitle: qsTr("Notes")

    property int maxCharactersCount: 50

    Component.onCompleted: switchBook(notebookList)

    DataHandler {   //TODO: deprecated
        id: dataHandler
    }

    SQLiteStorage {
        id: sqliteStorage

        onError: console.debug(error)
    }

    NoteBooksModel {
        id: noteBooksModel
        storage: sqliteStorage
    }

    NotesModel {
        id: notesModel
        storage: sqliteStorage
        noteBook: internal.selectedNoteBook
    }

    Component {
        id: notebookList

        NotebooksView {
            id: notebooksView
            anchors.fill: parent
            pageTitle: qsTr("Notes")
            model: noteBooksModel

            onNoteBookClicked: {
                window.addPage(noteList);
                internal.selectedNoteBook = noteBook;
            }
        }
    }

    Component {
        id: noteList

        NotesView {
            id: notesView
            anchors.fill: parent
            pageTitle: qsTr("Notes")
            model: notesModel

            onNoteClicked: {
                window.addPage(noteDetailPage);
                internal.selectedNote = note;
                //filterModel = [];
            }
        }
    }

    Component {
        id: noteDetailPage

        NoteDetail {
            id: noteDetail
            anchors.fill: parent
            note: internal.selectedNote
            model: notesModel

            onWindowClosed:
            {
                window.switchBook(notebookList);
                window.addPage(noteList);
//                filterModel = filterModelList;
            }
        }
    }

    QtObject {
        id: internal

        property variant selectedNoteBook: null
        property variant selectedNote: null
    }
}

/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Components 0.1
import MeeGo.Ux.Components.Common 0.1
import MeeGo.Ux.Kernel 0.1
import MeeGo.App.Notes 0.1

Window {
    id: window
    toolBarTitle: qsTr("Notes")

    property int maxCharactersCount: 50

    SaveRestoreState {
        id: saveRestoreMain

        onSaveRequired: {
            //currentPage
            setValue("currentPageName", pageStack.currentPage.pageName);

            //internal
            setValue("internalMain.selectedNoteBook", internal.selectedNoteBook != null ? internal.selectedNoteBook.id : "");
            setValue("internalMain.selectedNote", internal.selectedNote != null ? internal.selectedNote.id : "");

            sync();
        }
    }

    function restorePageStack()
    {
        switch (saveRestoreMain.value("currentPageName")){
        case "NotebooksPage":
            switchBook(notebookList);
            break;
        case "NotesPage":
            switchBook(notebookList);
            fastPageSwitch = true;
            addPage(noteList);
            fastPageSwitch = false;
            break;
        case "NoteDetailPage":
            switchBook(notebookList);
            fastPageSwitch = true;
            addPage(noteList);
            addPage(noteDetailPage);
            fastPageSwitch = false;
            break;
        }
    }

    Component.onCompleted: {
        if (saveRestoreMain.restoreRequired) {
            internal.selectedNoteBook = noteBooksModel.noteBookById(saveRestoreMain.value("internalMain.selectedNoteBook"));
            internal.selectedNote = notesModel.noteById(saveRestoreMain.value("internalMain.selectedNote"));

            //restore page stack
            restorePageStack();
        } else {
            switchBook(notebookList);
        }
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

    SaveRestoreState {
        id: saveRestore
    }

    Component {
        id: notebookList

        NotebooksView {
            id: notebooksView
            anchors.fill: parent
            pageTitle: qsTr("Notes")
            model: noteBooksModel
            property string pageName: "NotebooksPage"

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
            property string pageName: "NotesPage"

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
            property string pageName: "NoteDetailPage"

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

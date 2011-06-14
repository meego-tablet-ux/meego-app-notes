/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#include <QtDeclarative>

#include "notesplugin.h"

#include "models.h"
#include "sqldatastorage.h"

void NotesPlugin::registerTypes(const char *uri)
{
    qmlRegisterUncreatableType<AbstractDataStorage>(uri, 0, 1, "AbstractDataStorage", "Base class");
    qmlRegisterType<SQLiteStorage>(uri, 0, 1, "SQLiteStorage");
    qmlRegisterType<NoteBook>(uri, 0, 1, "NoteBook");
    qmlRegisterType<NoteBooksModel>(uri, 0, 1, "NoteBooksModel");
    qmlRegisterType<Note>(uri, 0, 1, "Note");
    qmlRegisterType<NotesModel>(uri, 0, 1, "NotesModel");
}

Q_EXPORT_PLUGIN(NotesPlugin);

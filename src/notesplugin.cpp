/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#include "notesplugin.h"
#include "DataHandler.h"
#include "ModelManager.h"
#include "NotebooksModel.h"
#include "NoteModel.h"
#include "TextEditHandler.h"

#include <qdeclarative.h>

void NotesPlugin::registerTypes(const char *uri)
{
    qmlRegisterType<CDataHandler>(uri, 0, 1, "DataHandler");
    qmlRegisterType<NotebooksModel>(uri, 0, 1, "NotebooksModel");
    qmlRegisterType<NoteModel>(uri, 0, 1, "NoteModel");
    qmlRegisterType<ModelManager>(uri, 0, 1, "ModelManager");
    qmlRegisterType<CTextEditHandler>(uri, 0, 1, "TextEditHandler");
}

//Q_EXPORT_PLUGIN2(notesplugin, NotesPlugin);
Q_EXPORT_PLUGIN(NotesPlugin);

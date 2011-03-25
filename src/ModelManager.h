/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#ifndef MODELMANAGER_H
#define MODELMANAGER_H

#include "DataHandler.h"
#include "NotebooksModel.h"
#include "NoteModel.h"

#include <QMap>

/********************************************************************
 * ModelManager class declaration
 *
 * This class implements model manager.
 *
 *
 *******************************************************************/
class ModelManager : public QObject
{
Q_OBJECT

public:
		ModelManager(CDataHandler *dataHander, NotebooksModel* notebooksModel);
    ModelManager();
    virtual ~ModelManager();

    Q_INVOKABLE QObject *modelFromName(const QString &name);
		Q_INVOKABLE void update();
    Q_INVOKABLE QObject * notebooksModel() { return m_notebooksModel; }
    Q_INVOKABLE QObject * dataHandler() { return m_dataHandler; }

    typedef QMap<QString, QObject *> ModelMap;
		inline const ModelMap &modelMap() { return m_modelMap; }
    void clearModelMap();

private:
		CDataHandler* m_dataHandler;
		NotebooksModel* m_notebooksModel;

    ModelMap m_modelMap;
    bool m_bGenerated;
};


#endif // MODELMANAGER_H

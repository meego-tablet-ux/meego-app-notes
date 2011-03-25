/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#include "ModelManager.h"
#include <QStringList>

#include <QDebug>

/********************************************************************
 * ModelManager class implementation
 *
 * This class implements model manager.
 *
 *
 *******************************************************************/

/********************************************************************
 * ModelManager - constructor of the class
 *
 *
 *******************************************************************/
ModelManager::ModelManager(CDataHandler *dataHander, NotebooksModel* notebooksModel) :
    QObject(), m_dataHandler(dataHander), m_notebooksModel(notebooksModel), m_bGenerated(false)
{
	update();
}


/********************************************************************
 * ModelManager - constructor of the class
 *
 *
 *******************************************************************/
ModelManager::ModelManager() :
    QObject(), m_dataHandler(new CDataHandler), m_notebooksModel(new NotebooksModel),
    m_bGenerated(true)
{
  update();
}


/********************************************************************
 * ~ModelManager - destructor of the class
 *
 *
 *******************************************************************/
ModelManager::~ModelManager()
{
  if (m_bGenerated)
  {
    delete m_dataHandler;
    delete m_notebooksModel;
  }
}

/********************************************************************
 * modelFromName function returns a model for a given name
 *
 *
 *******************************************************************/
QObject *ModelManager::modelFromName(const QString &name)
{
	QString lookup = name;
  if (lookup == tr("Everyday Notes (default)"))
	{
		lookup = "everydayNotes";
	}
	lookup.replace(" ", "");

	ModelManager::ModelMap::iterator iter = m_modelMap.find(lookup);
	if (iter != m_modelMap.end())
		return *iter;
	else
		return 0;
}


/********************************************************************
 * update function updates m_modelMap and m_notebooksModel
 *
 *
 *******************************************************************/
void ModelManager::update()
{
  clearModelMap();
  //m_modelMap.clear();
	m_notebooksModel->clear();

	QStringList noteBooksNames, noteBooksTitles;
	bool bSorted = m_dataHandler->isSorted();

	m_dataHandler->getNoteBooks(NoteModel::NameRole, noteBooksNames, bSorted);
	m_dataHandler->getNoteBooks(NoteModel::TitleRole, noteBooksTitles, bSorted);

	for (int i=0; i< noteBooksNames.count(); i++)
	{
		NoteModel *notesModel = new NoteModel();

		QStringList notesNames, notesTitles;
    m_notebooksModel->addNotebook(new Notebook(noteBooksNames[i], noteBooksTitles[i]));
		m_dataHandler->getNotes(noteBooksNames[i], NoteModel::NameRole, notesNames, bSorted);
		m_dataHandler->getNotes(noteBooksNames[i], NoteModel::TitleRole, notesTitles, bSorted);
		for (int j=0; j< notesNames.count(); j++)
		{
				QString st, strPos;
				m_dataHandler->load(noteBooksNames[i], notesNames[j], st);
				m_dataHandler->getNotePosition(noteBooksNames[i], notesNames[j], strPos);
        notesModel->addNote(new Note(notesNames[j], notesTitles[j],
																 noteBooksNames[i], st, strPos));
		}

		QString strModelName = noteBooksNames[i].simplified();
    if (strModelName == tr("Everyday Notes (default)"))
		{
			strModelName = "everydayNotes";
		}
		strModelName.replace(" ", "");

		qDebug() << "inserting " << strModelName;

		m_modelMap.insert(strModelName, notesModel);
	}
}

/********************************************************************
 * clearModelMap function removed all items from the modelMap
 *
 *
 *******************************************************************/
void ModelManager::clearModelMap()
{
  if (!m_modelMap.isEmpty())
  {
    ModelManager::ModelMap::iterator i = m_modelMap.begin();
    while (i != m_modelMap.end())
    {
      NoteModel *notesModel = (NoteModel*)i.value();
      if (NULL != notesModel)
      {
        delete notesModel;
      }
      ++i;
    }

    m_modelMap.clear();
  }
}



/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */


#include "NotebooksModel.h"


/********************************************************************
 * Notebook class declaration
 *
 * This class implements notebook. Each notebook contains such roles like:
 * name and title
 *
 *******************************************************************/

/********************************************************************
 * Notebook - constructor of the class
 *
 *
 *******************************************************************/
Notebook::Notebook(const QString& name, const QString& title)
    : m_strName(name), m_strTitle(title)
{
}


/********************************************************************
 * name - get name of the notebook
 *
 *
 *******************************************************************/
QString Notebook::name() const
{
    return m_strName;
}


/********************************************************************
 * title - get title of the notebook
 *
 *
 *******************************************************************/
QString Notebook::title() const
{
    return m_strTitle;
}


/********************************************************************
 * NotebooksModel class implementation
 *
 * This class implements notebook data model.
 *
 *******************************************************************/

/********************************************************************
 * NotebooksModel - constructor of the class
 *
 *
 *******************************************************************/
NotebooksModel::NotebooksModel(QObject* parent)
    : QAbstractListModel(parent)
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[TitleRole] = "title";
    roles[NotesCountRole] = "notesCount";
    setRoleNames(roles);
}


/********************************************************************
 * rowCount - get total notebooks number
 *
 *
 *******************************************************************/

int NotebooksModel::rowCount(const QModelIndex& /*parent*/) const
{
    return m_notebooks.count();
}


/********************************************************************
 * data - get notebook data
 *
 *
 *******************************************************************/
QVariant NotebooksModel::data(const QModelIndex& index, int role) const
{
    if (index.row() < 0 || index.row() > m_notebooks.count())
        return QVariant();

    Notebook* notebook = m_notebooks[index.row()];
    if (NULL != notebook)
    {
        if (role == NameRole)
            return notebook->name();
        else if (role == TitleRole)
            return notebook->title();
        else if (role == NotesCountRole)
            return m_handler->getChildNotes(notebook->name());
    }

    return QVariant();
}


/********************************************************************
 * addNotebook - add new notebook
 *
 *
 *******************************************************************/
void NotebooksModel::addNotebook(const QString &name)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_notebooks.append(new Notebook(name, name));
    m_notebooksTitles.append(name);
    endInsertRows();

    if (m_handler->isSorted())
        sort();
}

void NotebooksModel::addNotebook(Notebook *notebook)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_notebooks.append(notebook);
    m_notebooksTitles.append(notebook->name());
    endInsertRows();
}

/********************************************************************
 * clear - remove all notebooks
 *
 *
 *******************************************************************/
void NotebooksModel::clear()
{
    if(!m_notebooks.isEmpty())
    {
        beginRemoveRows(QModelIndex(), 0, m_notebooks.count()-1);
        for(int i = 0; i < m_notebooks.count(); i++)
            delete m_notebooks[i];
        m_notebooks.clear();
        endRemoveRows();
    }
}

void NotebooksModel::init()
{
    connect(m_handler, SIGNAL(notebookAdded(QString)), this, SLOT(addNotebook(QString)));
    connect(m_handler, SIGNAL(notebookRemoved(QString)), this, SLOT(removeNotebook(QString)));
    connect(m_handler, SIGNAL(notebookRenamed(QString,QString)), SLOT(renameNotebook(QString,QString)));
    connect(m_handler, SIGNAL(noteAdded(QString)), this, SLOT(handleNotesChanging()));
    connect(m_handler, SIGNAL(noteRemoved(QString)), this, SLOT(handleNotesChanging()));

    QStringList noteBooksNames, noteBooksTitles;
    bool bSorted = m_handler->isSorted();

    m_handler->getNoteBooks(NotebooksModel::NameRole, noteBooksNames, bSorted);
    m_handler->getNoteBooks(NotebooksModel::TitleRole, noteBooksTitles, bSorted);

    for (int i=0; i< noteBooksNames.count(); i++)
    {
        this->addNotebook(new Notebook(noteBooksNames[i], noteBooksTitles[i]));
    }
}

void NotebooksModel::removeNotebook(const QString &name)
{
    const int index = m_notebooksTitles.indexOf(name);
    if (index != -1) {
        beginRemoveRows(QModelIndex(), index, index);
        delete m_notebooks.takeAt(index);
        m_notebooksTitles.removeAt(index);
        endRemoveRows();
    }
}

void NotebooksModel::renameNotebook(const QString &oldName, const QString &newName)
{
    const int index = m_notebooksTitles.indexOf(oldName);
    if (index < 0)
        return;
    delete m_notebooks[index];
    m_notebooks[index] = new Notebook(newName, newName);
    m_notebooksTitles[index] = newName;
    reset();
}

void NotebooksModel::sort()
{
    beginResetModel();
    quickSort(m_notebooksTitles, 1, m_notebooksTitles.count()-1);
    endResetModel();
}

void NotebooksModel::quickSort(QStringList &list, int left, int right)
{
    int i = left, j = right;
    QString tmp;
    Notebook *tempNotebook;
    QString pivot = list.at((left + right) / 2);

    /* partition */
    while (i <= j) {
        while (list.at(i) < pivot)
            i++;
        while (list.at(j) > pivot)
            j--;
        if (i <= j) {
            tmp = list.at(i);
            tempNotebook = m_notebooks.at(i);
            list[i] = list.at(j);
            m_notebooks[i] = m_notebooks.at(j);
            list[j] = tmp;
            m_notebooks[j] = tempNotebook;
            i++;
            j--;
        }
    };

    /* recursion */
    if (left < j)
        quickSort(list, left, j);
    if (i < right)
        quickSort(list, i, right);
}



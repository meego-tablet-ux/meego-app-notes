/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#include "NoteModel.h"
#include <QDebug>
#include <QTemporaryFile>

/********************************************************************
 * Note class declaration
 *
 * This class implements note. Each note contains such roles like:
 * name, title, notebook and text
 *
 *******************************************************************/

/********************************************************************
 * Note - constructor of the class
 *
 *
 *******************************************************************/
OldNote::OldNote(const QString& name, const QString& title,
           const QString& notebook, const QString& text,
           const QString& position)
    : m_strName(name), m_strTitle(title),
      m_strNotebook(notebook), m_strText(text), m_strPosition(position)
{
}


/********************************************************************
 * name - get name of the note
 *
 *
 *******************************************************************/
QString OldNote::name() const
{
    return m_strName;
}


/********************************************************************
 * title - get title of the note
 *
 *
 *******************************************************************/
QString OldNote::title() const
{
    return m_strTitle;
}


/********************************************************************
 * notebook - get notebook of the note
 *
 *
 *******************************************************************/
QString OldNote::notebook() const
{
    return m_strNotebook;
}


/********************************************************************
 * text - get text of the note
 *
 *
 *******************************************************************/
QString OldNote::text() const
{
    return m_strText;
}


/********************************************************************
 * position - get text of the note
 *
 *
 *******************************************************************/
QString OldNote::position() const
{
    return m_strPosition;
}



/********************************************************************
 * NoteModel class implementation
 *
 * This class implements note data model.
 *
 *******************************************************************/

/********************************************************************
 * NoteModel - constructor of the class
 *
 *
 *******************************************************************/
NoteModel::NoteModel(QObject* parent)
    : QAbstractListModel(parent)
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[TitleRole] = "title";
    roles[NotebookRole] = "notebook";
    roles[TextRole] = "text";
    roles[PositionRole] = "position";
    setRoleNames(roles);
}

/********************************************************************
  * ~NoteModel - destructor of the class
  *
  *
  *******************************************************************/
NoteModel::~NoteModel()
{
    clear();
}

/********************************************************************
 * rowCount - get total notes number
 *
 *
 *******************************************************************/
int NoteModel::rowCount(const QModelIndex& /*parent*/) const
{
    return m_Notes.count();
}


/********************************************************************
 * data - get note data
 *
 *
 *******************************************************************/
QVariant NoteModel::data(const QModelIndex& index, int role) const
{
    if (index.row() < 0 || index.row() > m_Notes.count())
        return QVariant();

    OldNote* note = m_Notes[index.row()];

    if (NULL != note)
    {
        if (role == NameRole)
            return note->name();
        else if (role == TitleRole)
            return note->title();
        else if (role == NotebookRole)
            return note->notebook();
        else if (role == TextRole)
            return note->text();
        else if (role == PositionRole)
            return note->position();
    }

    return QVariant();
}


/********************************************************************
 * addNote - add new note
 *
 *
 *******************************************************************/
void NoteModel::addNote(OldNote* note)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_Notes.append(note);
    m_notesNames.append(note->name());
    endInsertRows();
}

/********************************************************************
  * clear - remove all notes
  *
  *
  *******************************************************************/
void NoteModel::clear()
{
    if(!m_Notes.isEmpty())
    {
        beginResetModel();
        qDeleteAll(m_Notes);
        m_Notes.clear();
        m_notesNames.clear();
        QList<QTemporaryFile *> tempFiles = m_dumpFiles.values();
        qDeleteAll(tempFiles);
        m_dumpFiles.clear();
        endResetModel();
    }
}

void NoteModel::init()
{
    qDebug()<<"NotesInitFunction";
    clear();
    bool bSorted = m_handler->isSorted();
    QStringList notesNames, notesTitles;
    m_handler->getNotes(m_notebookName, NoteModel::NameRole, notesNames, bSorted);
    m_handler->getNotes(m_notebookName, NoteModel::TitleRole, notesTitles, bSorted);
    qDebug()<<"NotesCOunt: "<<notesNames;
    QString pos;

    for (int i=0; i< notesNames.count(); i++)
    {
        //         m_handler->load(m_notebookName, notesNames.at(i), st);
        m_handler->getNotePosition(m_notebookName, notesNames.at(i), pos);
        this->addNote(new OldNote(notesNames.at(i), notesTitles.at(i), m_notebookName, QString(), pos));
    }
}

void NoteModel::addNote(const QString &name)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    QString pos;
    m_handler->getNotePosition(m_notebookName, name, pos);
    m_Notes.append(new OldNote(name, name, m_notebookName, QString(), pos));
    m_notesNames.append(name);
    endInsertRows();

    if (m_handler->isSorted())
        sort();
}

void NoteModel::removeNote(const QString &name)
{
    const int index = m_notesNames.indexOf(name);
    if (index != -1) {
        beginRemoveRows(QModelIndex(), index, index);
        delete m_Notes.takeAt(index);
        m_notesNames.removeAt(index);
        endRemoveRows();
    }
}

void NoteModel::sort()
{
    beginResetModel();
    quickSort(m_notesNames, 0, m_notesNames.count()-1);
    endResetModel();
}

void NoteModel::refresh() {
    beginResetModel();
    endResetModel();
}

void NoteModel::quickSort(QStringList &list, int left, int right)
{
    int i = left, j = right;
    QString tmp;
    OldNote *tempNote;
    QString pivot = list.at((left + right) / 2);

    /* partition */
    while (i <= j) {
        while (list.at(i).toLower() < pivot.toLower())
            i++;
        while (list.at(j).toLower() > pivot.toLower())
            j--;
        if (i <= j) {
            tmp = list.at(i);
            tempNote = m_Notes.at(i);
            list[i] = list.at(j);
            m_Notes[i] = m_Notes.at(j);
            list[j] = tmp;
            m_Notes[j] = tempNote;
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

QString NoteModel::dumpNote(int row)
{
    if (row < 0 || row >= m_Notes.count())
        return QString();

    QTemporaryFile *file = m_dumpFiles.value(row);
    if (!file) {
        file = new QTemporaryFile();
        m_dumpFiles.insert(row, file);
    }

    if (!file->open()) {
        delete file;
        m_dumpFiles.remove(row);
        return QString();
    }

    OldNote *note = m_Notes[row];
    Q_ASSERT(note);
    if (!note) {
        delete file;
        m_dumpFiles.remove(row);
        return QString();
    }

    //because note->text() is empty, I have to do this:
    QString theRealText_OMG_THIS_IS_STUPID = m_handler->loadNoteData(m_notebookName,note->title());

    QTextStream out(file);
    out << theRealText_OMG_THIS_IS_STUPID;

    out.flush();

    return file->fileName();
}

void NoteModel::notebookNameChanged(const QString &oldName, const QString &newName)
{
    Q_UNUSED(oldName);
    setNotebookName(newName);
}

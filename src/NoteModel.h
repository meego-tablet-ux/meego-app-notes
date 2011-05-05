/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#ifndef NOTEMODEL_H
#define NOTEMODEL_H

#include <QAbstractListModel>
#include "DataHandler.h"
/********************************************************************
 * Note class declaration
 *
 * This class implements note. Each note contains such roles like:
 * name, title, notebook and text
 *
 *******************************************************************/
class Note
{
public:
    Note(const QString& name, const QString& title,
         const QString& notebook, const QString& text,
         const QString& position);

    QString name() const;
    QString title() const;
    QString notebook() const;
    QString text() const;
    QString position() const;

protected:
    QString m_strName;
    QString m_strTitle;
    QString m_strNotebook;
    QString m_strText;
    QString m_strPosition;
};

/********************************************************************
 * NoteModel class declaration
 *
 * This class implements note data model.
 *
 *******************************************************************/

class QTemporaryFile;

class NoteModel : public QAbstractListModel
{
    Q_OBJECT
public:
    Q_PROPERTY(CDataHandler *dataHandler READ dataHandler WRITE setDataHandler)
    Q_PROPERTY(QString notebookName READ notebookName WRITE setNotebookName NOTIFY noteBookNameChanged)
    enum NotesRoles
    {
        NameRole = Qt::UserRole + 1,
        TitleRole,
        NotebookRole,
        TextRole,
        PositionRole
    };

    NoteModel(QObject *parent = 0);
    ~NoteModel();
    int rowCount(const QModelIndex& parent = QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;
    void addNote(Note* note);
    void clear();
    void setDataHandler(CDataHandler *handler)
    {
        m_handler = handler;
        connect(m_handler, SIGNAL(noteAdded(QString)), this, SLOT(addNote(QString)));
        connect(m_handler, SIGNAL(noteRemoved(QString)), this, SLOT(removeNote(QString)));
        connect(m_handler, SIGNAL(notebookRenamed(QString,QString)), SLOT(notebookNameChanged(QString,QString)));
    }
    CDataHandler * dataHandler() { return m_handler; }
    void setNotebookName(const QString &name) { m_notebookName = name; init(); emit noteBookNameChanged(); }
    QString notebookName() { return m_notebookName; }

signals:
    void noteBookNameChanged();

public slots:
    void addNote(const QString &name);
    void removeNote(const QString &name);
    void sort();
    void refresh();
    QString dumpNote(int row);

private slots:
    void notebookNameChanged(const QString &oldName, const QString &newName);

protected:
    QStringList m_notesNames;
    QList<Note*> m_Notes;
    CDataHandler *m_handler;
    QString m_notebookName;
    QMap<int, QTemporaryFile *> m_dumpFiles;

private:
    void init();
    void quickSort(QStringList &list, int left, int right);
};

#endif // NOTEMODEL_H

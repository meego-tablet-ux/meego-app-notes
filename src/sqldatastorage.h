/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#ifndef SQLDATASTORAGE_H
#define SQLDATASTORAGE_H

#include <QObject>
#include <QString>
#include <QList>
#include <QSqlDatabase>
#include <QtDeclarative>
#include <QDateTime>

/*
*
* AbstractDataStorage is an abstract interaface for managing NoteBooks
* and Notes. It provides an interface to open/close a storage, create/remove the storage,
* create/remove/modify NoteBooks and Notes.
*
*/
class AbstractDataStorage : public QObject
{
    Q_OBJECT
public:
    explicit AbstractDataStorage(QObject *parent = 0) : QObject(parent) {}

public slots:
    virtual bool openStorage() = 0;
    virtual void closeStorage() = 0;

public:
    class ItemData
    {
    public:
        ItemData() : id(0), position(-1) {}

        quint64 id;
        QString title;
        qint32 position;
        QDateTime created;
    };

    class NoteBook : public ItemData
    {

    };

    class Note : public ItemData
    {
    public:
        Note() : noteBookId(0) {}

        quint64 noteBookId;
        QString html;
    };

    virtual bool createNoteBook(const QString &title, qint32 position) = 0;
    virtual bool removeNoteBook(quint64 id) = 0;
    virtual bool updateNoteBook(quint64 id, const QString &title, qint32 position) = 0;
    virtual bool updateNoteBookTitle(quint64 id, const QString &title) = 0;
    virtual bool updateNoteBookPosition(quint64 id, qint32 position) = 0;
    virtual QList<NoteBook> noteBooks() = 0;
    virtual quint64 noteBooksCount() = 0;
    virtual NoteBook noteBook(quint64 id) = 0;
    virtual NoteBook noteBookByPosition(qint32 position) = 0;
    quint64 defaultNoteBookId() const { return 1; }
    NoteBook defaultNoteBook() { return noteBook(defaultNoteBookId()); }
    virtual bool noteBookExists(const QString &title) = 0;    //TODO: do we need this function now?
    virtual qint32 noteBookPosition(quint64 id) = 0;

    virtual bool createNote(quint64 noteBookId, const QString &title, qint32 position) = 0;
    virtual bool removeNote(quint64 noteBookId, quint64 id) = 0;
    virtual bool updateNote(quint64 noteBookId, quint64 id, const QString &title, const QString &html, qint32 position) = 0;
    virtual bool updateNoteTitle(quint64 noteBookId, quint64 id, const QString &title) = 0;
    virtual bool updateNoteHtml(quint64 noteBookId, quint64 id, const QString &html) = 0;
    virtual bool updateNotePosition(quint64 noteBookId, quint64 id, qint32 position) = 0;
    virtual QList<Note> notes(quint64 noteBookId) = 0;
    virtual quint64 notesCount(quint64 noteBookId) = 0;
    virtual Note note(quint64 noteBookId, quint64 id) = 0;
    virtual Note noteByPosition(quint64 noteBookId, qint32 position) = 0;
    virtual bool noteExists(quint64 noteBookId, const QString &title) = 0;    //TODO: do we need this function now?
    virtual qint32 notePosition(quint64 noteBookId, quint64 id) = 0;
    virtual bool moveNote(quint64 oldNoteBookId, quint64 newNoteBookId, quint64 id) = 0;

signals:
    void noteBookCreated();
    void noteBookRemoved();
    void noteBookUpdated();

    void noteCreated();
    void noteRemoved();
    void noteUpdated();
    void noteMoved();

    void error(const QString &error);

protected:
    virtual bool createStorage() = 0;
    virtual bool removeStorage() = 0;

    /*
    * The following 2 methods are necessary for generating new ids.
    * These functions will be useful when files or databases which, don't have support of autoincremention of ids, are used as real sources.
    * The default value is "0".
    */
    virtual quint64 lastNoteBookId() const { return 0; };
    virtual quint64 lastNoteId() const { return 0; }
};
QML_DECLARE_TYPE(AbstractDataStorage)

/*
*
* AbstractSqlDataStorage is an abstract interaface for managing NoteBooks using SQL database as a source.
*
*/
class AbstractSqlDataStorage : public AbstractDataStorage
{
    Q_OBJECT
public:
    explicit AbstractSqlDataStorage(QObject *parent = 0) : AbstractDataStorage(parent) {}

    void setHostName(const QString &host);
    QString hostName() const;

    void setUserName(const QString &login);
    QString userName() const;

    void setPassword(const QString &passw);
    QString password() const;

    void setPort(int port);
    int port() const;

public slots:
    bool openStorage();
    void closeStorage();

protected:
    bool createStorage();
    bool removeStorage();

    virtual QString driverName() const = 0;
    virtual QString databaseName() const;// { return QString("notes.db"); };
    virtual QString connectionName() const { return QString("meego-app-notes"); };

    QString noteBooksTableName() const { return QString("noteBooks"); }
    QString notesTableName() const { return QString("notes"); }

    virtual QString databaseCreationScript() const = 0;
    virtual QString databaseDeletionScript() const = 0;

    bool checkConnection() const;

protected:
    QSqlDatabase m_database;
};
QML_DECLARE_TYPE(AbstractSqlDataStorage)

/*
*
* SQLiteStorage is class for managing NoteBooks using SQLite3 database as a source.
*
*/
class SQLiteStorage : public AbstractSqlDataStorage
{
    Q_OBJECT
public:
    explicit SQLiteStorage(QObject *parent = 0) : AbstractSqlDataStorage(parent) { AbstractSqlDataStorage::openStorage(); }

    bool createNoteBook(const QString &title, qint32 position);
    bool removeNoteBook(quint64 id);
    bool updateNoteBook(quint64 id, const QString &title, qint32 position);
    bool updateNoteBookTitle(quint64 id, const QString &title);
    bool updateNoteBookPosition(quint64 id, qint32 position);
    QList<NoteBook> noteBooks();
    quint64 noteBooksCount();
    NoteBook noteBook(quint64 id);
    NoteBook noteBookByPosition(qint32 position);
    bool noteBookExists(const QString &title);    //TODO: do we need this function now?
    qint32 noteBookPosition(quint64 id);

    bool createNote(quint64 noteBookId, const QString &title, qint32 position);
    bool removeNote(quint64 noteBookId, quint64 id);
    bool updateNote(quint64 noteBookId, quint64 id, const QString &title, const QString &html, qint32 position);
    bool updateNoteTitle(quint64 noteBookId, quint64 id, const QString &title);
    bool updateNoteHtml(quint64 noteBookId, quint64 id, const QString &html);
    bool updateNotePosition(quint64 noteBookId, quint64 id, qint32 position);
    QList<Note> notes(quint64 noteBookId);
    quint64 notesCount(quint64 noteBookId);
    Note note(quint64 noteBookId, quint64 id);
    Note noteByPosition(quint64 noteBookId, qint32 position);
    bool noteExists(quint64 noteBookId, const QString &title);
    qint32 notePosition(quint64 noteBookId, quint64 id);
    bool moveNote(quint64 oldNoteBookId, quint64 newNoteBookId, quint64 id);

private:
    QString driverName() const { return QString("QSQLITE"); }

    QString databaseCreationScript() const;
    QString databaseDeletionScript() const;
};
QML_DECLARE_TYPE(SQLiteStorage)

#endif // SQLDATASTORAGE_H

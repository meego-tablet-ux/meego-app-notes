/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#ifndef SQLDATASTORAGE_H
#define SQLDATASTORAGE_H

#include <QString>
#include <QList>

class QSqlDatabase;

/*
*
* AbstractDataStorage is an abstract interaface for managin NoteBooks
* and Notes. It provides an interface to open/close a storage, create/remove the storage,
* create/remove/modify NoteBooks and Notes.
*
*/
class AbstractDataStorage
{
public:
    AbstractDataStorage() {}
    virtual ~AbstractDataStorage() {}

    virtual bool openStorage() = 0;
    virtual void closeStorage() = 0;

    struct NoteBook
    {
        quint64 id;
        QString title;
        quint32 position;
    };

    virtual bool createNoteBook(const QString &title, qint32 position) = 0;
    virtual bool removeNoteBook(quint64 id) = 0;
    virtual bool updateNoteBook(quint64 id, const QString &title, qint32 position) = 0;
    virtual QList<quint64> noteBooks() = 0;
    virtual NoteBook noteBook(quint64 id) = 0;

    struct Note : public NoteBook
    {
        quint64 noteBookId;
        QString html;
    };

    virtual bool createNote(quint64 noteBookId, const QString &title, const QString &html, qint32 position) = 0;
    virtual bool removeNote(quint64 noteBookId, quint64 id) = 0;
    virtual bool updateNote(quint64 noteBookId, quint64 id, const QString &title, const QString &html, qint32 position) = 0;
    virtual QList<quint64> notes(quint64 noteBookId) = 0;
    virtual Note note(quint64 id) = 0;

    virtual QString lastErrorString() const = 0;

protected:
    virtual bool createStorage() = 0;
    virtual bool removeStorage() = 0;

    /*
    * The following 2 methods are necessary for generation new ids.
    * The would be useful when files or databases which, don't have support of autoincremention of ids, are used as real sourses.
    * The default value is "0".
    */
    virtual quint64 lastNoteBookId() const { return 0; };
    virtual quint64 lastNoteId() const { return 0; }

private:
    Q_DISABLE_COPY(AbstractDataStorage);
};

/*
*
* AbstractSqlDataStorage is an abstract interaface for managin NoteBooks using SQL database as a source.
*
*/
class AbstractSqlDataStorage : public AbstractDataStorage
{
public:
    AbstractSqlDataStorage() : AbstractDataStorage() {}
    virtual ~AbstractSqlDataStorage() {}

    void setHostName(const QString &host);
    QString hostName() const;

    void setUserName(const QString &login);
    QString userName() const;

    void setPassword(const QString &passw);
    QString password() const;

    void setPort(int port);
    int port() const;

    virtual bool openStorage();
    virtual void closeStorage();

    virtual QString lastErrorString() const;

protected:
    virtual bool createStorage();
    virtual bool removeStorage();

    virtual QString driverName() const = 0;
    virtual QString databaseName() const { return QString("notes"); };
    virtual QString connectionName() const { return QString("meego-app-notes"); };

    QString noteBooksTableName() const { return QString("noteBooks"); }
    QString notesTableName() const { return QString("notes"); }

    virtual QString databaseCreationScript() const = 0;
    virtual QString databaseDeletionScript() const = 0;

    bool checkConnection() const;

protected:
    QSqlDatabase m_database;
};

/*
*
* SQLiteStorage is class for managin NoteBooks using SQLite3 database as a source.
*
*/
class SQLiteStorage : public AbstractSqlDataStorage
{
public:
    SQLiteStorage() : AbstractSqlDataStorage() {}
    virtual ~SQLiteStorage() {}

    virtual bool createNoteBook(const QString &title, qint32 position);
    virtual bool removeNoteBook(quint64 id);
    virtual bool updateNoteBook(quint64 id, const QString &title, qint32 position);
    virtual QList<quint64> noteBooks();
    virtual NoteBook noteBook(quint64 id);

    virtual bool createNote(quint64 noteBookId, const QString &title, const QString &html, qint32 position);
    virtual bool removeNote(quint64 noteBookId, quint64 id);
    virtual bool updateNote(quint64 noteBookId, quint64 id, const QString &title, const QString &html, qint32 position);
    virtual QList<quint64> notes(quint64 noteBookId);
    virtual Note note(quint64 id);

private:
    virtual QString driverName() const { return QString("QSQLITE"); }

    virtual QString databaseCreationScript() const;
    virtual QString databaseDeletionScript() const;
};

#endif // SQLDATASTORAGE_H

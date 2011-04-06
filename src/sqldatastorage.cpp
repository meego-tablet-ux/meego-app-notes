/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#include <QtSql>

#include "sqldatastorage.h"

void AbstractSqlDataStorage::setHostName(const QString &host)
{
    m_database.setHostName(host);
}

QString AbstractSqlDataStorage::hostName() const
{
    return m_database.hostName();
}

void AbstractSqlDataStorage::setUserName(const QString &login)
{
    m_database.setUserName(login);
}

QString AbstractSqlDataStorage::userName() const
{
    return m_database.userName();
}

void AbstractSqlDataStorage::setPassword(const QString &passw)
{
    m_database.setPassword(passw);
}

QString AbstractSqlDataStorage::password() const
{
    return m_database.password();
}

void AbstractSqlDataStorage::setPort(int port)
{
    m_database.setPort(port);
}

int AbstractSqlDataStorage::port() const
{
    return m_database.port();
}

bool AbstractSqlDataStorage::openStorage()
{
    if (QSqlDatabase::contains(connectionName())) {
        m_database = QSqlDatabase::database(connectionName());
    } else {
        m_database = QSqlDatabase::addDatabase(driverName(), connectionName());
        m_database.setDatabaseName(databaseName());
    }
    if (!m_database.isOpen() && !m_database.open())
       return false;
    return createStorage();
}

void AbstractSqlDataStorage::closeStorage()
{
    m_database.close();
    m_database = QSqlDatabase();
    QSqlDatabase::removeDatabase(connectionName());
}

bool AbstractSqlDataStorage::createStorage()
{
    const QStringList tables = m_database.tables();
    if (tables.contains(noteBooksTableName()) && tables.contains(notesTableName()))
        return true;
    QSqlQuery query(m_database);
    return query.exec(databaseCreationScript());
}

bool AbstractSqlDataStorage::removeStorage()
{
    if (!openStorage())
        return false;
    QSqlQuery query(m_database);
    const bool res = query.exec(databaseDeletionScript());
    closeStorage();
    return res;
}

bool AbstractSqlDataStorage::checkConnection() const
{
    return m_database.isValid() && m_database.isOpen();
}

QString AbstractSqlDataStorage::lastErrorString() const
{
    return m_database.lastError().text();
}
//--------------------------------------------------------------------------------------------------------------------------
bool SQLiteStorage::createNoteBook(const QString &title, qint32 position)
{
    if (!checkConnection())
        return false;

    const QString script = QString("INSERT INTO %1 (title, position) VALUES (?, ?)").arg(noteBooksTableName());
    QSqlQuery query(m_database);
    query.prepare(script);
    query.addBindValue(title);
    query.addBindValue(position);
    return query.exec();
}

bool SQLiteStorage::removeNoteBook(quint64 id)
{
    if (!checkConnection())
        return false;

    const QString script = QString("DELETE FROM %1 WHERE id = %2")
            .arg(noteBooksTableName())
            .arg(id);
    QSqlQuery query(m_database);
    return query.exec(script);
}

bool SQLiteStorage::updateNoteBook(quint64 id, const QString &title, qint32 position)
{
    if (!checkConnection())
        return false;

    const QString script = QString("UPDATE %1 SET title = '%2', position = '%3' WHERE id = %4")
            .arg(noteBooksTableName())
            .arg(title)
            .arg(position)
            .arg(id);
    QSqlQuery query(m_database);
    return query.exec(script);
}

QList<quint64> SQLiteStorage::noteBooks()
{
    QList<quint64> res;

    if (!checkConnection())
        return res;

    static const QString script = QString("SELECT id FROM %1").arg(noteBooksTableName());
    QSqlQuery query(m_database);
    if (!query.exec(script))
        return res;

    while (query.next())
        res << query.value(0).toUInt();

    return res;
}

AbstractDataStorage::NoteBook SQLiteStorage::noteBook(quint64 id)
{
    NoteBook res;

    if (!checkConnection())
        return res;

    const QString script = QString("SELECT * FROM %1 WHERE id = '%2").arg(noteBooksTableName()).arg(id);
    QSqlQuery query(m_database);
    if (!query.exec(script) || !query.next())
        return res;

    res.id = query.record().value("id").toUInt();
    res.title = query.record().value("title").toString();
    res.position = query.record().value("position").toUInt();

    return res;
}

bool SQLiteStorage::createNote(quint64 noteBookId, const QString &title, const QString &html, qint32 position)
{
    if (!checkConnection())
        return false;

    const QString script = QString("INSERT INTO %1 (noteBookId, title, html, position) VALUES (?, ?, ?, ?)").arg(notesTableName());
    QSqlQuery query(m_database);
    query.prepare(script);
    query.addBindValue(noteBookId);
    query.addBindValue(title);
    query.addBindValue(html);
    query.addBindValue(position);
    return query.exec();
}

bool SQLiteStorage::removeNote(quint64 noteBookId, quint64 id)
{
    if (!checkConnection())
        return false;

    //TODO: noteBookId is unneccessary parameter since a note's id is always unique.
    const QString script = QString("DELETE FROM %1 WHERE id = %2 AND noteBookId = %3")
            .arg(notesTableName())
            .arg(id)
            .arg(noteBookId);
    QSqlQuery query(m_database);
    return query.exec(script);
}

bool SQLiteStorage::updateNote(quint64 noteBookId, quint64 id, const QString &title, const QString &html, qint32 position)
{
    if (!checkConnection())
        return false;

    //TODO: noteBookId is unneccessary parameter since a note's id is always unique.
    const QString script = QString("UPDATE %1 SET title = '%2', html = '%3', position = '%4' WHERE id = %5 AND noteBookId = %6")
            .arg(notesTableName())
            .arg(title)
            .arg(html)
            .arg(position)
            .arg(id)
            .arg(noteBookId);
    QSqlQuery query(m_database);
    return query.exec(script);
}

QList<quint64> SQLiteStorage::notes(quint64 noteBookId)
{
    QList<quint64> res;

    if (!checkConnection())
        return res;

    static const QString script = QString("SELECT id FROM %1 WHERE noteBookId = %2")
            .arg(notesTableName())
            .arg(noteBookId);
    QSqlQuery query(m_database);
    if (!query.exec(script))
        return res;

    while (query.next())
        res << query.value(0).toUInt();

    return res;
}

AbstractDataStorage::Note SQLiteStorage::note(quint64 id)
{
    Note res;

    if (!checkConnection())
        return res;

    const QString script = QString("SELECT * FROM %1 WHERE id = '%2").arg(notesTableName()).arg(id);
    QSqlQuery query(m_database);
    if (!query.exec(script) || !query.next())
        return res;

    res.id = query.record().value("id").toUInt();
    res.noteBookId = query.record().value("noteBookId").toUInt();
    res.title = query.record().value("title").toString();
    res.html = query.record().value("html").toString();
    res.position = query.record().value("position").toUInt();

    return res;
}

QString SQLiteStorage::databaseCreationScript() const
{
    static const QString script = QString("CREATE TABLE %1 (id INTEGER PRIMARY KEY AUTOINCREMENT,"
                                    "title VARCHAR(255),"
                                    "position INTEGER);"
                                    "CREATE TABLE %2 (id INTEGER PRIMARY KEY AUTOINCREMENT,"
                                    "noteBookId INTEGER,"
                                    "title VARCHAR(255),"
                                    "html TEXT,"
                                    "position INTEGER);").arg(noteBooksTableName()).arg(notesTableName());
    return script;
}

QString SQLiteStorage::databaseDeletionScript() const
{
    static const QString script = QString("DROP TABLE %1;"
                                    "DROP TABLE %2;").arg(noteBooksTableName()).arg(notesTableName());
    return script;
}

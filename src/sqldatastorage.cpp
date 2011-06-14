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
    if (!m_database.isOpen() && !m_database.open()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(m_database.lastError().text()));
        return false;
    }
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
    const QStringList scripts = databaseCreationScript().split(';');
    foreach (const QString &script, scripts) {
        if (!query.exec(script)) {
            emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
            return false;
        }
    }

    query.clear();
    const QString script = QString("INSERT INTO %1 (id, title, position) VALUES (?, ?, ?)").arg(noteBooksTableName());
    query.prepare(script);
    query.addBindValue(defaultNoteBookId());
    query.addBindValue(tr("Everyday Notes (default)"));
    query.addBindValue(0);
    if (!query.exec()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    return true;
}

bool AbstractSqlDataStorage::removeStorage()
{
    if (!openStorage())
        return false;
    QSqlQuery query(m_database);

    const QStringList scripts = databaseDeletionScript().split(';');
    foreach (const QString &script, scripts) {
        if (!query.exec(script)) {
            emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
            return false;
        }
    }

    closeStorage();
    return true;
}

bool AbstractSqlDataStorage::checkConnection() const
{
    return m_database.isValid() && m_database.isOpen();
}
//--------------------------------------------------------------------------------------------------------------------------
bool SQLiteStorage::createNoteBook(const QString &title, qint32 position)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    const QString script = QString("INSERT INTO %1 (title, position) VALUES (?, ?)").arg(noteBooksTableName());
    QSqlQuery query(m_database);
    query.prepare(script);
    query.addBindValue(title);
    query.addBindValue(position);
    if (!query.exec()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    emit noteBookCreated();
    return true;
}

bool SQLiteStorage::removeNoteBook(quint64 id)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    const QString noteBookDeletionScript = QString("DELETE FROM %1 WHERE id = %2")
            .arg(noteBooksTableName())
            .arg(id);
    QSqlQuery noteBookDeletionQuery(m_database);
    const QString notesDeletionScript = QString("DELETE FROM %1 WHERE noteBookId = %2")
            .arg(notesTableName())
            .arg(id);
    QSqlQuery notesDeletionQuery(m_database);
    if (!notesDeletionQuery.exec(notesDeletionScript)) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(notesDeletionQuery.lastError().text()));
        return false;
    }
    if (!noteBookDeletionQuery.exec(noteBookDeletionScript)) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(noteBookDeletionQuery.lastError().text()));
        return false;
    }
    emit noteBookRemoved();
    return true;
}

bool SQLiteStorage::updateNoteBook(quint64 id, const QString &title, qint32 position)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    const QString script = QString("UPDATE %1 SET title = '%2', position = %3 WHERE id = %4")
            .arg(noteBooksTableName())
            .arg(title)
            .arg(position)
            .arg(id);
    QSqlQuery query(m_database);
    if (!query.exec(script)) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    emit noteBookUpdated();
    return true;
}

bool SQLiteStorage::updateNoteBookTitle(quint64 id, const QString &title)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    const QString script = QString("UPDATE %1 SET title = '%2' WHERE id = %3")
            .arg(noteBooksTableName())
            .arg(title)
            .arg(id);
    QSqlQuery query(m_database);
    if (!query.exec(script)) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    emit noteBookUpdated();
    return true;
}

bool SQLiteStorage::updateNoteBookPosition(quint64 id, qint32 position)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    const QString script = QString("UPDATE %1 SET position = %2 WHERE id = %3")
            .arg(noteBooksTableName())
            .arg(position)
            .arg(id);
    QSqlQuery query(m_database);
    if (!query.exec(script)) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    emit noteBookUpdated();
    return true;
}

QList<AbstractDataStorage::NoteBook> SQLiteStorage::noteBooks()
{
    QList<AbstractDataStorage::NoteBook> res;

    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return res;
    }

    const QString script = QString("SELECT * FROM %1").arg(noteBooksTableName());
    QSqlQuery query(m_database);
    if (!query.exec(script)) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return res;
    }

    while (query.next()) {
        NoteBook noteBook;
        noteBook.id = query.record().value("id").toUInt();
        noteBook.title = query.record().value("title").toString();
        noteBook.position = query.record().value("position").toInt();
        res << noteBook;
    }

    return res;
}


quint64 SQLiteStorage::noteBooksCount()
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return 0;
    }

    const QString script = QString("SELECT COUNT(1) AS rowsCount FROM %1")
            .arg(noteBooksTableName());
    QSqlQuery query(m_database);
    if (!query.exec(script) || !query.next()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return 0;
    }
    return query.record().value("rowsCount").toUInt();
}


AbstractDataStorage::NoteBook SQLiteStorage::noteBook(quint64 id)
{
    NoteBook res;

    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return res;
    }

    const QString script = QString("SELECT * FROM %1 WHERE id = %2").arg(noteBooksTableName()).arg(id);
    QSqlQuery query(m_database);
    if (!query.exec(script) || !query.next()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return res;
    }

    res.id = query.record().value("id").toUInt();
    res.title = query.record().value("title").toString();
    res.position = query.record().value("position").toInt();

    return res;
}

AbstractDataStorage::NoteBook SQLiteStorage::noteBookByPosition(qint32 position)
{
    NoteBook res;

    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return res;
    }

    const QString script = QString("SELECT * FROM %1 WHERE position = %2").arg(noteBooksTableName()).arg(position);
    QSqlQuery query(m_database);
    if (!query.exec(script) || !query.next()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return res;
    }

    res.id = query.record().value("id").toUInt();
    res.title = query.record().value("title").toString();
    res.position = query.record().value("position").toInt();

    return res;
}

bool SQLiteStorage::noteBookExists(const QString &title)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    const QString script = QString("SELECT COUNT(1) AS count FROM %1 WHERE title = '%2'").arg(noteBooksTableName()).arg(title);
    QSqlQuery query(m_database);
    if (!query.exec(script) || !query.next()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    return query.record().value("count").toInt() > 0;
}

qint32 SQLiteStorage::noteBookPosition(quint64 id)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return -1;
    }

    const QString script = QString("SELECT position FROM %1 WHERE id = '%2'").arg(noteBooksTableName()).arg(id);
    QSqlQuery query(m_database);
    if (!query.exec(script) || !query.next()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return -1;
    }
    return query.record().value("position").toInt();

}

bool SQLiteStorage::createNote(quint64 noteBookId, const QString &title, qint32 position)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    const QString script = QString("INSERT INTO %1 (noteBookId, title, position) VALUES (?, ?, ?)").arg(notesTableName());
    QSqlQuery query(m_database);
    query.prepare(script);
    query.addBindValue(noteBookId);
    query.addBindValue(title);
    query.addBindValue(position);
    if (!query.exec()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    emit noteCreated();
    return true;
}

bool SQLiteStorage::removeNote(quint64 noteBookId, quint64 id)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    //TODO: noteBookId is unneccessary parameter since a note's id is always unique.
    const QString script = QString("DELETE FROM %1 WHERE id = %2 AND noteBookId = %3")
            .arg(notesTableName())
            .arg(id)
            .arg(noteBookId);
    QSqlQuery query(m_database);
    if (!query.exec(script)) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    emit noteRemoved();
    return true;
}

bool SQLiteStorage::updateNote(quint64 noteBookId, quint64 id, const QString &title, const QString &html, qint32 position)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    //TODO: noteBookId is unneccessary parameter since a note's id is always unique.
    const QString script = QString("UPDATE %1 SET title = '%2', html = '%3', position = %4 WHERE id = %5 AND noteBookId = %6")
            .arg(notesTableName())
            .arg(title)
            .arg(html)
            .arg(position)
            .arg(id)
            .arg(noteBookId);
    QSqlQuery query(m_database);
    if (!query.exec(script)) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    emit noteUpdated();
    return true;
}

bool SQLiteStorage::updateNoteTitle(quint64 noteBookId, quint64 id, const QString &title)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    //TODO: noteBookId is unneccessary parameter since a note's id is always unique.
    const QString script = QString("UPDATE %1 SET title = '%2' WHERE id = %3 AND noteBookId = %4")
            .arg(notesTableName())
            .arg(title)
            .arg(id)
            .arg(noteBookId);
    QSqlQuery query(m_database);
    if (!query.exec(script)) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    emit noteUpdated();
    return true;
}

bool SQLiteStorage::updateNotePosition(quint64 noteBookId, quint64 id, qint32 position)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    //TODO: noteBookId is unneccessary parameter since a note's id is always unique.
    const QString script = QString("UPDATE %1 SET position = %2 WHERE id = %3 AND noteBookId = %4")
            .arg(notesTableName())
            .arg(position)
            .arg(id)
            .arg(noteBookId);
    QSqlQuery query(m_database);
    if (!query.exec(script)) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    emit noteUpdated();
    return true;
}

bool SQLiteStorage::updateNoteHtml(quint64 noteBookId, quint64 id, const QString &html)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    //TODO: noteBookId is unneccessary parameter since a note's id is always unique.
    const QString script = QString("UPDATE %1 SET html = '%2' WHERE id = %3 AND noteBookId = %4")
            .arg(notesTableName())
            .arg(html)
            .arg(id)
            .arg(noteBookId);
    QSqlQuery query(m_database);
    if (!query.exec(script)) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    emit noteUpdated();
    return true;
}

QList<AbstractDataStorage::Note> SQLiteStorage::notes(quint64 noteBookId)
{
    QList<AbstractSqlDataStorage::Note> res;

    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return res;
    }

    const QString script = QString("SELECT * FROM %1 WHERE noteBookId = %2")
            .arg(notesTableName())
            .arg(noteBookId);
    QSqlQuery query(m_database);
    if (!query.exec(script)) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return res;
    }

    while (query.next()) {
        Note note;
        note.id = query.record().value("id").toUInt();
        note.noteBookId = query.record().value("noteBookId").toUInt();
        note.title = query.record().value("title").toString();
        note.html = query.record().value("html").toString();
        note.position = query.record().value("position").toInt();
        res << note;
    }

    return res;
}

quint64 SQLiteStorage::notesCount(quint64 noteBookId)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return 0;
    }

    const QString script = QString("SELECT COUNT(1) AS rowsCount FROM %1 WHERE noteBookId = %2")
            .arg(notesTableName())
            .arg(noteBookId);
    QSqlQuery query(m_database);
    if (!query.exec(script) || !query.next()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return 0;
    }
    return query.record().value("rowsCount").toUInt();
}

AbstractDataStorage::Note SQLiteStorage::note(quint64 noteBookId, quint64 id)
{
    Note res;

    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return res;
    }

    const QString script = QString("SELECT * FROM %1 WHERE noteBookId = %2 AND id = %3")
            .arg(notesTableName())
            .arg(noteBookId)
            .arg(id);
    QSqlQuery query(m_database);
    if (!query.exec(script) || !query.next()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return res;
    }

    res.id = query.record().value("id").toUInt();
    res.noteBookId = query.record().value("noteBookId").toUInt();
    res.title = query.record().value("title").toString();
    res.html = query.record().value("html").toString();
    res.position = query.record().value("position").toInt();

    return res;
}

AbstractDataStorage::Note SQLiteStorage::noteByPosition(quint64 noteBookId, qint32 position)
{
    Note res;

    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return res;
    }

    const QString script = QString("SELECT * FROM %1 WHERE noteBookId = %2 AND position = %3")
            .arg(notesTableName())
            .arg(noteBookId)
            .arg(position);
    QSqlQuery query(m_database);
    if (!query.exec(script) || !query.next()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return res;
    }

    res.id = query.record().value("id").toUInt();
    res.noteBookId = query.record().value("noteBookId").toUInt();
    res.title = query.record().value("title").toString();
    res.html = query.record().value("html").toString();
    res.position = query.record().value("position").toInt();

    return res;
}

bool SQLiteStorage::noteExists(quint64 noteBookId, const QString &title)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    const QString script = QString("SELECT COUNT(1) AS count FROM %1 WHERE noteBookId = %2 title = '%3'")
            .arg(notesTableName())
            .arg(noteBookId)
            .arg(title);
    QSqlQuery query(m_database);
    if (!query.exec(script) || !query.next()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    return query.record().value("count").toInt() > 0;
}

qint32 SQLiteStorage::notePosition(quint64 noteBookId, quint64 id)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return -1;
    }

    const QString script = QString("SELECT position FROM %1 WHERE noteBookId = %2 AND id = %3")
            .arg(notesTableName())
            .arg(noteBookId)
            .arg(id);
    QSqlQuery query(m_database);
    if (!query.exec(script) || !query.next()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return -1;
    }
    return query.record().value("position").toInt();
}

bool SQLiteStorage::moveNote(quint64 oldNoteBookId, quint64 newNoteBookId, quint64 id)
{
    if (!checkConnection()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg("Database isn't opened."));
        return false;
    }

    QSqlQuery lastPositionQuery(m_database);
    const QString lastPositionScript = QString("SELECT MAX(position) AS position FROM %1 WHERE noteBookId = %2")
            .arg(notesTableName())
            .arg(newNoteBookId);
    if (!lastPositionQuery.exec(lastPositionScript) || !lastPositionQuery.next()) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(lastPositionQuery.lastError().text()));
        return false;
    }

    bool ok = true;
    int position = lastPositionQuery.record().value("position").toInt(&ok);
    if (ok)
        position += 1;
    //TODO: noteBookId is unneccessary parameter since a note's id is always unique.
    const QString script = QString("UPDATE %1 SET noteBookId = %2, position = %3 WHERE id = %4 AND noteBookId = %5")
            .arg(notesTableName())
            .arg(newNoteBookId)
            .arg(position)
            .arg(id)
            .arg(oldNoteBookId);
    QSqlQuery query(m_database);
    if (!query.exec(script)) {
        emit error(QString("%1: %2").arg(Q_FUNC_INFO).arg(query.lastError().text()));
        return false;
    }
    emit noteUpdated();
    emit noteMoved();
    return true;
}

QString SQLiteStorage::databaseCreationScript() const
{
    const QString script = QString("CREATE TABLE IF NOT EXISTS %1 (id INTEGER PRIMARY KEY AUTOINCREMENT,"
                                    "title VARCHAR(255),"
                                    "position INTEGER);"
                                    "CREATE TABLE IF NOT EXISTS %2 (id INTEGER PRIMARY KEY AUTOINCREMENT,"
                                    "noteBookId INTEGER,"
                                    "title VARCHAR(255),"
                                    "html TEXT,"
                                    "position INTEGER);").arg(noteBooksTableName()).arg(notesTableName());
    return script;
}

QString SQLiteStorage::databaseDeletionScript() const
{
    const QString script = QString("DROP TABLE %1;"
                                    "DROP TABLE %2;").arg(noteBooksTableName()).arg(notesTableName());
    return script;
}

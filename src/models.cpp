/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#include <QHash>
#include <QTemporaryFile>

#include "models.h"
#include "meegolocale.h"

static const QString noteBookRole = "noteBook";
static const QString noteRole = "note";

using namespace meego;

ItemData::ItemData(QObject *parent) :
    QObject(parent),
    m_storage(0)
{

}

ItemData::ItemData(const AbstractDataStorage::ItemData &itemData, QObject *parent) :
    QObject(parent),
    m_storage(0),
    m_itemData(itemData)
{

}

void ItemData::setTitle(const QString &title)
{
    if (!m_storage)
        return;

    if (m_itemData.title == title)
        return;

    if (!setTitleHelper(title))
        return;

    m_itemData.title = title;
    emit titleChanged();
}

void ItemData::setPosition(qint32 position)
{
    if (!m_storage)
        return;

    if (m_itemData.position == position)
        return;

    if (!setPositionHelper(position))
        return;

    m_itemData.position = position;
    emit positionChanged();
}
//----------------------------------------------------------------------------------------------
NoteBook::NoteBook(QObject *parent) :
    ItemData(parent)
{

}

NoteBook::NoteBook(const AbstractDataStorage::NoteBook &noteBook, QObject *parent) :
    ItemData(noteBook, parent)
{

}

bool NoteBook::setTitleHelper(const QString &title)
{
    return m_storage->updateNoteBookTitle(m_itemData.id, title);
}

bool NoteBook::setPositionHelper(qint32 position)
{
    return m_storage->updateNoteBookPosition(m_itemData.id, position);
}

int NoteBook::notesCount() const
{
    return m_storage ? m_storage->notesCount(id()) : 0;
}

void NoteBook::setStorage(AbstractDataStorage *storage)
{
    if (m_storage) {
        disconnect(m_storage, SIGNAL(noteCreated()));
        disconnect(m_storage, SIGNAL(noteRemoved()));
    }
    ItemData::setStorage(storage);
    if (m_storage) {
        connect(m_storage, SIGNAL(noteCreated()), SIGNAL(notesCountChanged()));
        connect(m_storage, SIGNAL(noteRemoved()), SIGNAL(notesCountChanged()));
    }
}

bool NoteBook::operator < (const NoteBook &other) const
{
    if (!m_storage)
        return false;

    if (id() == m_storage->defaultNoteBookId())
        return true;
    if (other.id() == m_storage->defaultNoteBookId())
        return false;

    //use Locale api
    meego::Locale locale;
    return locale.lessThan(title(), other.title());
}

bool NoteBook::operator > (const NoteBook &other) const
{
    if (!m_storage)
        return false;

    if (id() == m_storage->defaultNoteBookId())
        return true;
    if (other.id() == m_storage->defaultNoteBookId())
        return false;

    return title() > other.title();
}
//----------------------------------------------------------------------------------------------
Note::Note(QObject *parent) :
    ItemData(parent),
    m_noteBook(0)
{

}

Note::Note(const AbstractDataStorage::Note &note, NoteBook *noteBook, QObject *parent) :
    ItemData(note, parent),
    m_note(note),
    m_noteBook(noteBook)
{

}

bool Note::setTitleHelper(const QString &title)
{
    return m_storage->updateNoteTitle(m_note.noteBookId, m_note.id, title);
}

bool Note::setPositionHelper(qint32 position)
{
    return m_storage->updateNotePosition(m_note.noteBookId, m_note.id, position);
}

void Note::setNoteBook(NoteBook *noteBook)
{
    if (!m_storage)
        return;

    if (m_noteBook == noteBook)
        return;

    m_noteBook = noteBook;
    emit noteBookChanged();
}

void Note::setHtml(const QString &html)
{
    if (!m_storage)
        return;

    if (m_note.html == html)
        return;

    if (!m_storage->updateNoteHtml(m_note.noteBookId, m_note.id, html))
        return;

    m_note.html = html;
    emit htmlChanged();
}

bool Note::operator < (const Note &other) const
{
    if (!m_storage)
        return false;

    //use Locale api
    meego::Locale locale;
    return locale.lessThan(title(), other.title());
}

bool Note::operator > (const Note &other) const
{
    if (!m_storage)
        return false;
    return title() > other.title();
}
//----------------------------------------------------------------------------------------------
ItemsDataModel::ItemsDataModel(QObject *parent) :
    QAbstractListModel(parent),
    m_storage(0),
    m_sortOrder(ASC),
    m_sortingEnabled(false)
{

}

void ItemsDataModel::setStorage(AbstractDataStorage *storage)
{
    if (!storage)
        return;

    if (m_storage)
        disconnect(m_storage, SIGNAL(noteMoved()));

    m_storage = storage;

    if (m_storage)
        connect(m_storage, SIGNAL(noteMoved()), SLOT(noteMovedSlot()));

    reset();
    emit storageChanged();
    emit countChanged();
}

void ItemsDataModel::sort(int column, Qt::SortOrder order)
{
    Q_UNUSED(column);

    emit layoutAboutToBeChanged();

    QList<ItemData *> list;
    for (int i = 0; i < rowCount(); ++i)
        list << item(i);

    sortHelper(list, order);

    QVector<int> forwarding(list.count());
    for (int i = 0; i < list.count(); ++i) {
        forwarding[list[i]->position()] = i;
        list[i]->setPosition(i);
    }

    QModelIndexList oldIndexes = persistentIndexList();
    QModelIndexList newIndexes;
    for (int i = 0; i < oldIndexes.count(); ++i)
        newIndexes << index(forwarding[oldIndexes[i].row()]);
    changePersistentIndexList(oldIndexes, newIndexes);

    emit layoutChanged();
    emit modelSorted();
}

ItemData *ItemsDataModel::item(int row) const
{
    QModelIndex index = this->index(row);
    if (!index.isValid())
        return 0;

    return static_cast<ItemData *>(index.internalPointer());
}

void ItemsDataModel::noteMovedSlot()
{
    emit dataChanged(index(0), index(rowCount() - 1));
    emit countChanged();

    if (isSortingEnabled())
        sort(sortOrder());
}
//----------------------------------------------------------------------------------------------
NoteBooksModel::NoteBooksModel(QObject *parent) :
    ItemsDataModel(parent)
{
    QHash<int, QByteArray> roles;
    roles.insert(NoteBookRole, noteBookRole.toAscii());
    setRoleNames(roles);
}

int NoteBooksModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return storage() ? storage()->noteBooksCount() : 0;
}

QVariant NoteBooksModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    if (role != NoteBookRole)
        return QVariant();

    NoteBook *noteBook = static_cast<NoteBook *>(index.internalPointer());
    if (!noteBook)
        return QVariant();

    return qVariantFromValue(noteBook);
}

QModelIndex NoteBooksModel::index(int row, int column, const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    if (!storage())
        return QModelIndex();

    AbstractDataStorage::NoteBook noteBook = storage()->noteBookByPosition(row);
    if (!noteBook.id)
        return QModelIndex();

    NoteBook *nb = new NoteBook(noteBook, const_cast<NoteBooksModel *>(this));
    nb->setStorage(storage());
    return createIndex(row, column, nb);
}

NoteBook *NoteBooksModel::createNoteBook(const QString &title)
{
    if (!storage())
        return 0;

    if (!storage()->createNoteBook(title, rowCount()))
        return 0;

    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    endInsertRows();
    emit countChanged();

    NoteBook *noteBook = this->noteBook(rowCount() - 1);

    if (isSortingEnabled())
        sort(sortOrder());

    return noteBook;
}

void NoteBooksModel::removeNoteBook(quint64 noteBookId)
{
    if (!storage())
        return;

    const int row = storage()->noteBookPosition(noteBookId);

    if (!storage()->removeNoteBook(noteBookId))
        return;

    beginRemoveRows(QModelIndex(), row, row);
    const int rowCount = this->rowCount();
    for (int r = row + 1; r <= rowCount; ++r) {
        NoteBook *noteBook = this->noteBook(r);
        if (noteBook)
            noteBook->setPosition(r - 1);
    }
    endRemoveRows();

    emit countChanged();

    if (isSortingEnabled())
        sort(sortOrder());
}

void NoteBooksModel::renameNoteBook(quint64 noteBookId, const QString &newTitle)
{
    if (!storage())
        return;

    const int row = storage()->noteBookPosition(noteBookId);

    NoteBook *noteBook = this->noteBook(row);
    if (!noteBook)
        return;

    noteBook->setTitle(newTitle);

    emit dataChanged(index(row), index(row));

    if (isSortingEnabled())
        sort(sortOrder());
}

bool NoteBooksModel::noteBookExists(const QString &title)
{
    return storage() ? storage()->noteBookExists(title) : false;
}

NoteBook *NoteBooksModel::noteBook(int row) const
{
    return qobject_cast<NoteBook *>(item(row));
}

NoteBook *NoteBooksModel::noteBookById(quint64 noteBookId) const
{
    if (!storage())
        return 0;
    return noteBook(storage()->noteBookPosition(noteBookId));
}

quint64 NoteBooksModel::defaultNoteBookId() const
{
    return storage() ? storage()->defaultNoteBookId() : 0;
}

static bool noteBookLessThen(ItemData *a, ItemData *b)
{
    return *qobject_cast<NoteBook *>(a) < *qobject_cast<NoteBook *>(b);
}

static bool noteBookGreaterThen(ItemData *a, ItemData *b)
{
    return *qobject_cast<NoteBook *>(a) > *qobject_cast<NoteBook *>(b);
}

void NoteBooksModel::sortHelper(QList<ItemData *> &container, Qt::SortOrder order)
{
    if (order == Qt::AscendingOrder) {
        qSort(container.begin(), container.end(), noteBookLessThen);
    } else {
        qSort(container.begin(), container.end(), noteBookGreaterThen);
    }
}
//----------------------------------------------------------------------------------------------
NotesModel::NotesModel(QObject *parent) :
    ItemsDataModel(parent),
    m_noteBook(0),
    m_dumpFile(0)
{
    QHash<int, QByteArray> roles;
    roles.insert(NoteRole, noteRole.toAscii());
    setRoleNames(roles);
}

void NotesModel::setNoteBook(NoteBook *noteBook)
{
    if (!noteBook || m_noteBook == noteBook)
        return;

    m_noteBook = noteBook;
    reset();
    emit noteBookChanged();
}

int NotesModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_noteBook ? m_noteBook->notesCount() : 0;
}

QVariant NotesModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    if (role != NoteRole)
        return QVariant();

    Note *note = static_cast<Note *>(index.internalPointer());
    if (!note)
        return QVariant();

    return qVariantFromValue(note);
}

QModelIndex NotesModel::index(int row, int column, const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    if (!storage() || !m_noteBook)
        return QModelIndex();

    AbstractDataStorage::Note note = storage()->noteByPosition(m_noteBook->id(), row);
    if (!note.id)
        return QModelIndex();

    Note *n = new Note(note, m_noteBook, const_cast<NotesModel *>(this));
    n->setStorage(storage());
    return createIndex(row, column, n);
}

Note *NotesModel::createNote(const QString &title)
{
    if (!storage() || !m_noteBook)
        return 0;

    if (!storage()->createNote(m_noteBook->id(), title, rowCount()))
        return 0;

    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    endInsertRows();
    emit countChanged();

    Note *note = this->note(rowCount() - 1);

    if (isSortingEnabled())
        sort(sortOrder());

    return note;
}

void NotesModel::removeNote(quint64 noteId)
{
    Note *note = noteById(noteId);
    if (!note)
        return;

    const qint32 row = note->position();

    if (!storage()->removeNote(m_noteBook->id(), noteId))
        return;

    beginRemoveRows(QModelIndex(), row, row);
    const int rowCount = this->rowCount();
    for (int r = row + 1; r <= rowCount; ++r) {
        Note *note = this->note(r);
        if (note)
            note->setPosition(r - 1);
    }
    endRemoveRows();

    emit countChanged();

    if (isSortingEnabled())
        sort(sortOrder());
}

void NotesModel::renameNote(quint64 noteId, const QString &newTitle)
{
    Note *note = noteById(noteId);
    if (!note)
        return;

    const qint32 row = note->position();

    note->setTitle(newTitle);

    emit dataChanged(index(row), index(row));

    if (isSortingEnabled())
        sort(sortOrder());
}

void NotesModel::setNoteText(quint64 noteId, const QString &text)
{
    Note *note = noteById(noteId);
    if (!note)
        return;

    const qint32 row = note->position();

    note->setHtml(text);

    emit dataChanged(index(row), index(row));
}

bool NotesModel::noteExists(const QString &title)
{
    if (!storage() || !m_noteBook)
        return false;
    return storage()->noteExists(m_noteBook->id(), title);
}

void NotesModel::moveNote(quint64 noteId, quint64 newNoteBookId)
{
    Note *note = noteById(noteId);
    if (!note)
        return;

    const qint32 row = note->position();

    if (!storage()->moveNote(m_noteBook->id(), newNoteBookId, note->id()))
        return;

    beginRemoveRows(QModelIndex(), row, row);
    const int rowCount = this->rowCount();
    for (int r = row + 1; r <= rowCount; ++r) {
        Note *note = this->note(r);
        if (note)
            note->setPosition(r - 1);
    }
    endRemoveRows();

    emit countChanged();

    if (isSortingEnabled())
        sort(sortOrder());
}

Note *NotesModel::note(int row) const
{
    return qobject_cast<Note *>(item(row));
}

Note *NotesModel::noteById(quint64 noteId) const
{
    if (!storage() || !m_noteBook)
        return 0;
    return note(storage()->notePosition(m_noteBook->id(), noteId));
}

static bool noteLessThen(ItemData *a, ItemData *b)
{
    return *qobject_cast<Note *>(a) < *qobject_cast<Note *>(b);
}

static bool noteGreaterThen(ItemData *a, ItemData *b)
{
    return *qobject_cast<Note *>(a) > *qobject_cast<Note *>(b);
}

void NotesModel::sortHelper(QList<ItemData *> &container, Qt::SortOrder order)
{
    if (order == Qt::AscendingOrder) {
        qSort(container.begin(), container.end(), noteLessThen);
    } else {
        qSort(container.begin(), container.end(), noteGreaterThen);
    }
}

QString NotesModel::dumpNote(quint64 noteId)
{
    Note *note = noteById(noteId);
    if (!note)
        return QString();

    if (!m_dumpFile)
        m_dumpFile = new QTemporaryFile(this);

    if (!m_dumpFile->open())
        return QString();

    QTextStream out(m_dumpFile);
    out << note->html();

    out.flush();

    return m_dumpFile->fileName();
}

void NotesModel::swapNotes(quint64 firstNoteId, quint64 secondNoteId)
{
    Note *firstNote = noteById(firstNoteId);
    Note *secondNote = noteById(secondNoteId);

    if (!firstNote || !secondNote)
        return;

    emit layoutAboutToBeChanged();

    QModelIndex oldPosition = index(firstNote->position());
    QModelIndex newPosition = index(secondNote->position());

    firstNote->setPosition(newPosition.row());
    secondNote->setPosition(oldPosition.row());

    changePersistentIndex(oldPosition, newPosition);

    emit layoutChanged();
}

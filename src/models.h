/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#ifndef MODELS_H
#define MODELS_H

#include <QtDeclarative>
#include <QAbstractListModel>

#include "sqldatastorage.h"

class QTemporaryFile;

class ItemData : public QObject
{
    Q_OBJECT

    Q_PROPERTY(quint64 id READ id CONSTANT)
    Q_PROPERTY(QString title READ title NOTIFY titleChanged)
    Q_PROPERTY(qint32 position READ position NOTIFY positionChanged)
public:
    explicit ItemData(QObject *parent = 0);
    ItemData(const AbstractDataStorage::ItemData &itemData, QObject *parent = 0);

    quint64 id() const { return m_itemData.id; }

    void setTitle(const QString &title);
    QString title() const { return m_itemData.title; }

    void setPosition(qint32 position);
    qint32 position() const { return m_itemData.position; }

    virtual void setStorage(AbstractDataStorage *storage) { m_storage = storage; }

    virtual bool operator < (const ItemData &other) const = 0;

signals:
    void titleChanged();
    void positionChanged();

protected:
    virtual bool setTitleHelper(const QString &title) = 0;
    virtual bool setPositionHelper(qint32 position) = 0;

protected:
    QPointer<AbstractDataStorage> m_storage;
    AbstractDataStorage::ItemData m_itemData;
};
//----------------------------------------------------------------------------------------------
class NoteBook : public ItemData
{
    Q_OBJECT

    Q_PROPERTY(int notesCount READ notesCount NOTIFY notesCountChanged)
public:
    explicit NoteBook(QObject *parent = 0);
    NoteBook(const AbstractDataStorage::NoteBook &noteBook, QObject *parent = 0);

    bool operator < (const ItemData &other) const;

    int notesCount() const;

    void setStorage(AbstractDataStorage *storage);

signals:
    void titleChanged();
    void positionChanged();
    void notesCountChanged();

private:
    bool setTitleHelper(const QString &title);
    bool setPositionHelper(qint32 position);
};
QML_DECLARE_TYPE(NoteBook)
//----------------------------------------------------------------------------------------------
class Note : public ItemData
{
    Q_OBJECT

    Q_PROPERTY(NoteBook *noteBook READ noteBook NOTIFY noteBookChanged)
    Q_PROPERTY(QString html READ html NOTIFY htmlChanged)
public:
    explicit Note(QObject *parent = 0);
    Note(const AbstractDataStorage::Note &note, NoteBook *noteBook, QObject *parent = 0);

    void setNoteBook(NoteBook *noteBook);
    NoteBook *noteBook() const { return m_noteBook; }

    void setHtml(const QString &html);
    QString html() const { return m_note.html; }

    bool operator < (const ItemData &other) const;

signals:
    void noteBookChanged();
    void htmlChanged();

private:
    bool setTitleHelper(const QString &title);
    bool setPositionHelper(qint32 position);

private:
    AbstractDataStorage::Note m_note;
    QPointer<NoteBook> m_noteBook;
};
QML_DECLARE_TYPE(Note)
//----------------------------------------------------------------------------------------------
class ItemsDataModel : public QAbstractListModel
{
    Q_OBJECT
public:
    explicit ItemsDataModel(QObject *parent = 0);

    void setStorage(AbstractDataStorage *storage);
    AbstractDataStorage *storage() const { return m_storage; }

    ItemData *item(int row) const;

signals:
    void storageChanged();
    void countChanged();

private slots:
    void emitDataChanged();

private:
    QPointer<AbstractDataStorage> m_storage;
};
//----------------------------------------------------------------------------------------------
class ItemsDataSortFilterProxyModel: public QSortFilterProxyModel
{
    Q_OBJECT

    Q_ENUMS(SortOrder)
    Q_PROPERTY(AbstractDataStorage *storage READ storage WRITE setStorage NOTIFY storageChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(SortOrder sortOrder READ sortOrder NOTIFY modelSorted)
    Q_PROPERTY(bool sorting READ isSortingEnabled WRITE setSortingEnabled NOTIFY sortingEnabled)
    Q_PROPERTY(QString filter READ filterText WRITE setFilterText NOTIFY filterChanged)
public:

    enum SortOrder { ASC = Qt::AscendingOrder, DESC = Qt::DescendingOrder };

    explicit ItemsDataSortFilterProxyModel(QObject *parent = 0);

    void setStorage(AbstractDataStorage *storage) { m_sourceModel->setStorage(storage); }
    AbstractDataStorage *storage() const { return m_sourceModel->storage(); }

    SortOrder sortOrder() const { return m_sortOrder; }

    void setSortingEnabled(bool enabled) { m_sortingEnabled = enabled; emit sortingEnabled(); }
    bool isSortingEnabled() const { return m_sortingEnabled; }

    virtual void sort(int column, Qt::SortOrder order);

    void setFilterText(const QString &filter);
    QString filterText() const { return m_filter; }

public slots:
    void sort(SortOrder order) { m_sortOrder = order; sort(0, Qt::SortOrder(order)); }

protected:
    void setItemsDataModel(ItemsDataModel *model);
    ItemData *item(int row) const;

    bool lessThan(const QModelIndex &left, const QModelIndex &right) const;
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;

private:
    void setSourceModel(QAbstractItemModel *sourceModel) { Q_UNUSED(sourceModel); }

private slots:
    void sortHelper();

signals:
    void storageChanged();
    void countChanged();
    void modelSorted();
    void sortingEnabled();
    void filterChanged();

private:
    QPointer<ItemsDataModel> m_sourceModel;
    SortOrder m_sortOrder;
    bool m_sortingEnabled;
    QString m_filter;
};
//----------------------------------------------------------------------------------------------
class NoteBooksModel : public ItemsDataModel
{
    Q_OBJECT
public:
    enum Roles { NoteBookRole = Qt::UserRole + 1 };

    explicit NoteBooksModel(QObject *parent = 0);

    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role) const;
    QModelIndex index(int row, int column = 0, const QModelIndex &parent = QModelIndex()) const;

    quint64 defaultNoteBookId() const;

public slots:
    NoteBook *createNoteBook(const QString &title);
    void removeNoteBook(quint64 noteBookId);
    void renameNoteBook(quint64 noteBookId, const QString &newTitle);
    bool noteBookExists(const QString &title);  //TODO: do we need this function now?
    NoteBook *noteBook(int row) const;
    NoteBook *noteBookById(quint64 noteBookId) const;
};
//----------------------------------------------------------------------------------------------
class NoteBooksSortFilterProxyModel : public ItemsDataSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(quint64 defaultNoteBookId READ defaultNoteBookId NOTIFY storageChanged)
public:
    explicit NoteBooksSortFilterProxyModel(QObject *parent = 0);

    quint64 defaultNoteBookId() const;

public slots:
    NoteBook *createNoteBook(const QString &title);
    void removeNoteBook(quint64 noteBookId);
    void renameNoteBook(quint64 noteBookId, const QString &newTitle);
    bool noteBookExists(const QString &title);  //TODO: do we need this function now?
    NoteBook *noteBook(int row) const;
    NoteBook *noteBookById(quint64 noteBookId) const;

signals:
    void storageChanged();

private:
    QPointer<NoteBooksModel> m_noteBooksModel;
};
//----------------------------------------------------------------------------------------------
class NotesModel : public ItemsDataModel
{
    Q_OBJECT

public:
    enum Roles { NoteRole = Qt::UserRole + 1 };

    explicit NotesModel(QObject *parent = 0);

    void setNoteBook(NoteBook *noteBook);
    NoteBook *noteBook() const { return m_noteBook; }

    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role) const;
    QModelIndex index(int row, int column = 0, const QModelIndex &parent = QModelIndex()) const;

public slots:
    Note *createNote(const QString &title);
    void removeNote(quint64 noteId);
    void renameNote(quint64 noteId, const QString &newTitle);
    void setNoteText(quint64 noteId, const QString &text);
    bool noteExists(const QString &title);  //TODO: do we need this function now?
    void moveNote(quint64 noteId, quint64 newNoteBookId);
    Note *note(int row) const;
    Note *noteById(quint64 noteId) const;
    QString dumpNote(quint64 noteId);
    void swapNotes(quint64 firstNoteId, quint64 secondNoteId);

signals:
    void noteBookChanged();

private:
    QPointer<NoteBook> m_noteBook;
    QTemporaryFile *m_dumpFile;
};
//----------------------------------------------------------------------------------------------
class NotesSortFilterProxyModel : public ItemsDataSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(NoteBook *noteBook READ noteBook WRITE setNoteBook NOTIFY noteBookChanged)
public:
    explicit NotesSortFilterProxyModel(QObject *parent = 0);

    void setNoteBook(NoteBook *noteBook) { m_notesModel->setNoteBook(noteBook); }
    NoteBook *noteBook() const { return m_notesModel->noteBook(); }

public slots:
    Note *createNote(const QString &title);
    void removeNote(quint64 noteId);
    void renameNote(quint64 noteId, const QString &newTitle);
    void setNoteText(quint64 noteId, const QString &text);
    bool noteExists(const QString &title);  //TODO: do we need this function now?
    void moveNote(quint64 noteId, quint64 newNoteBookId);
    Note *note(int row) const;
    Note *noteById(quint64 noteId) const;
    QString dumpNote(quint64 noteId);
    void swapNotes(quint64 firstNoteId, quint64 secondNoteId);

signals:
    void noteBookChanged();

private:
    QPointer<NotesModel> m_notesModel;
};

#endif // MODELS_H

/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#ifndef DATAHANDLER_H
#define DATAHANDLER_H

#include <QtCore/QObject>
#include <QtCore/QFile>
#include <QtCore/QStringList>

/********************************************************************
 * CDataHandler class declaration
 *
 * This class implements notes backend. It provides such functions like:
 * createNote/deleteNote, moveNote/changeNotePosition, createNoteBook
 * and etc.
 *
 *******************************************************************/
class CDataHandler: public QObject
{
	Q_OBJECT

public:
	CDataHandler();
	virtual ~CDataHandler() {};

	void Init();
	Q_INVOKABLE void createNote(const QString& _notebookID, const QString& _noteName, const QString& _noteText);
	Q_INVOKABLE void createNoteBook(const QString& _noteBookName);
	Q_INVOKABLE void deleteNote(const QString& _notebookID, const QString& _noteName);
  Q_INVOKABLE void deleteNotes(const QString& _notebookID, const QStringList& _notes);
	Q_INVOKABLE void deleteNoteBook(const QString& _notebookID);
  Q_INVOKABLE void deleteNoteBooks(const QStringList& _notebooks);
	Q_INVOKABLE void modifyNote(const QString& _notebookID, const QString& _noteName, const QString& _text);
	Q_INVOKABLE void moveNote(const QString& _notebookID, const QString& _noteName, const QString& _newNoteBookName);
  Q_INVOKABLE void moveNotes(const QString& _notebookID, const QStringList& _notes, const QString& _newNoteBookName);
	Q_INVOKABLE void changeNotePosition(const QString& _notebookID, const QString& _noteName, int nNewPos);
	Q_INVOKABLE QString loadNoteData(const QString& _notebookID, const QString& _fileName);
  Q_INVOKABLE void setSort(bool _bSort);
  Q_INVOKABLE void saveToFile(const QString& st);
  Q_INVOKABLE int getChildNotes(const QString& _notebookID);
  Q_INVOKABLE QString getDate(const QString& _notebookID);
  Q_INVOKABLE QStringList getNoteBooks();
  Q_INVOKABLE void setCheckBox(bool _bShow);
  Q_INVOKABLE bool getCheckBox();
  Q_INVOKABLE QStringList removeFromString(const QStringList& _array, const QString& _value);

	bool isSorted();
	void save(const QString& _notebookID, const QString& _fileName, const QString& _data);
	void load(const QString& _notebookID, const QString& _fileName, QString& _data);
	void getNotePosition(const QString& _notebookID, const QString& _fileName, QString& _position);
	void getNoteBooks(int role, QStringList& _noteBooks, bool _sort);
	void getNotes(const QString& _noteBook, int role, QStringList& _notes, bool _sort);

protected:
	bool checkAppData();
	QString getStringAttribute(const QString& _str, const QString& _attrName);
	int getIntAttribute(const QString& _str, const QString& _attrName);
	QString getNameFromFile(QFile& _file, const QString& _value, QString& _resultString);
	int getPositionFromFile(QFile& _file);
	void getStringsFromFile(QFile& _file, int role, QStringList& _list);
	QString generateUniqueName(const QString& _path, const QString& _originalName);
	bool createTempFile(QFile& _source, QFile& _dest, const QString& _noteBookID);
        bool removeDir(const QString &path);

signals:
    void notebookAdded(const QString &name);
    void notebookRemoved(const QString &name);
    void noteAdded(const QString &name);
    void noteRemoved(const QString &name);
};

#endif // DATAHANDLER_H

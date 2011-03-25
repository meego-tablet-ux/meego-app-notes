/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#ifndef NOTEBOOKSMODEL_H
#define NOTEBOOKSMODEL_H

#include <QAbstractListModel>
#include <DataHandler.h>
#include <QDebug>
/********************************************************************
 * Notebook class declaration
 *
 * This class implements notebook. Each notebook contains such roles like:
 * name and title
 *
 *******************************************************************/
 class Notebook
 {
 public:
	 Notebook(const QString& name, const QString& title);

	 QString name() const;
	 QString title() const;

 protected:
	 QString m_strName;
	 QString m_strTitle;
 };


 /********************************************************************
	* NotebooksModel class declaration
	*
	* This class implements notebook data model.
	*
	*******************************************************************/
 class NotebooksModel : public QAbstractListModel
 {
		 Q_OBJECT
 public:
        Q_PROPERTY(CDataHandler *dataHandler READ dataHandler WRITE setDataHandler)

		 enum NotebooksRoles
		 {
				 NameRole = Qt::UserRole + 1,
                                 TitleRole,
                                 NotesCountRole
		 };

		 NotebooksModel(QObject *parent = 0);
		 int rowCount(const QModelIndex& parent = QModelIndex()) const;
		 QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;
                 void addNotebook(Notebook *notebook);
		 void clear();
                 void setDataHandler(CDataHandler *handler) { m_handler = handler; init(); }
                 CDataHandler * dataHandler() { return m_handler; }

 public slots:
       void addNotebook(const QString &name);
       void removeNotebook(const QString &name);
       void handleNotesChanging() { this->reset(); }
       void sort();

 protected:
     QStringList m_notebooksTitles;
     QList<Notebook*> m_notebooks;
     CDataHandler *m_handler;

 private:
     void init();
     void quickSort(QStringList &list, int left, int right);
 };

#endif // NOTEBOOKSMODEL_H

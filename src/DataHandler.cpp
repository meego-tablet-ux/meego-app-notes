/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#include "DataHandler.h"
#include "NoteModel.h"

#include <QtCore/QFile>
#include <QtCore/QDir>
#include <QtCore/QDate>
#include <QtCore/QDateTime>
#include <QtCore/QTextStream>

//#include <sys/types.h>
//#include <sys/stat.h>
//#include <unistd.h>
//#include <stdlib.h>
#include <QDebug>
#define SAME_TITLES 0

static const QString STR_DEFAULT_NOTEBOOK = QObject::tr("Everyday Notes (default)");

/********************************************************************
 * CDataHandler class implementation
 *
 * This class implements notes backend. It provides such functions like:
 * createNote/deleteNote, moveNote/changeNotePosition, createNoteBook
 * and etc.
 *
 *******************************************************************/

/********************************************************************
 * CDataHandler - constructor of the class
 *
 *
 *******************************************************************/
CDataHandler::CDataHandler()
{
    Init();
}


/********************************************************************
 * Init function makes some default operations
 *
 *
 *******************************************************************/
void CDataHandler::Init()
{
    //check if the data folder exists
    if (!checkAppData()) //doen't exist, let's create it!
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QDir dir;
        dir.mkdir(home + ".MeeGo");//create top level folder
        dir.mkdir(home + ".MeeGo/Notes");//create top level folder
        //		mkdir(home.toUtf8() + ".MeeGo", 0777); //create top level folder
        //		mkdir(home.toUtf8() + ".MeeGo/Notes", 0777); //create top level folder
        //QString dbPath(home + ".MeeGo/Notes/Everyday Notes");
        QString dbPath(QString("%1.MeeGo/Notes/%2").arg(home).arg(tr("Everyday Notes")));
        //		mkdir(dbPath.toUtf8(), 0777); //create default subfolder
        dir.mkdir(dbPath);//create default subfolder

        //create databases file which contains info about all note books
        QFile dbs(home + ".MeeGo/Notes/data");
        if (dbs.open(QIODevice::WriteOnly | QIODevice::Append))
        {
            dbs.setTextModeEnabled(true);
            QTextStream out(&dbs);
            out <<QString("name=%1,position=0,path=%2,title=%3,\n").arg(STR_DEFAULT_NOTEBOOK).arg(dbPath).arg(STR_DEFAULT_NOTEBOOK);
            dbs.close();
            //create empty data file for the database
            QFile f(dbPath+"/data");
            if (f.open(QIODevice::WriteOnly | QIODevice::Append))
            {
                f.close();
            }
        }
    }
}


/********************************************************************
 * checkAppData function checks the application data (files and folders)
 *
 *
 *******************************************************************/
bool CDataHandler::checkAppData()
{
    bool bRet = false;

    QString home(QDir::homePath());

    if (!home.endsWith("/"))
    {
        home.append("/");
    }

    //check if the data folder exists
    if (!QFile::exists(home + ".MeeGo/Notes")) //doen't exist, let's create it!
    {
        bRet = false;
    }
    else
    {
        bRet = true;
    }

    return bRet;
}


/********************************************************************
 * createNoteBook function creates new note book
 *
 *
 *******************************************************************/
void CDataHandler::createNoteBook(const QString& _nodeName)
{
    //check if the data folder exists
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/data");
        if (dbs.exists())
        {
            if (dbs.open(QIODevice::ReadWrite | QIODevice::Append))
            {
                int nPos = getPositionFromFile(dbs);

                QString dbPath(home + ".MeeGo/Notes/" + _nodeName);
                if (!QFile::exists(dbPath))
                {
                    QTextStream out(&dbs);
                    out << QString("name=%1,position=%2,path=%3,title=%4,\n").arg(
                               _nodeName).arg(nPos+1).arg(dbPath).arg(_nodeName);
                }
                else //error - note book already exists, let's generate unique name for it
                {
#if SAME_TITLES
                    QString strNodeName = generateUniqueName(home + ".MeeGo/Notes/", _nodeName);
                    dbPath = home + ".MeeGo/Notes/" + strNodeName;
                    QTextStream out(&dbs);
                    out << QString("name=%1,position=%2,path=%3,title=%4,\n").arg(
                               _nodeName).arg(nPos+1).arg(dbPath).arg(_nodeName);
#endif
                }

                QDir dir;
                dir.mkdir(dbPath);
                dbs.close();
                //create empty file
                QFile f(dbPath+"/data");
                if (f.open(QIODevice::WriteOnly | QIODevice::Append))
                {
                    f.close();
                }

                emit notebookAdded(_nodeName);
            }

        }
    }
}


/********************************************************************
 * createNote function creates new note in the existing notes book
 *
 *
 *******************************************************************/
void CDataHandler::createNote(const QString& _notebookID,
                              const QString& _noteName,
                              const QString& _noteText)
{
    //check if the data folder exists
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/data");
        if (dbs.exists())
        {
            if (dbs.open(QIODevice::ReadOnly))
            {
                QString strLine, strPath, strName;
                strName = getNameFromFile(dbs, _notebookID, strLine);

                if (strName == _notebookID)
                {
                    strPath = getStringAttribute(strLine, "path=");
                    if (!strPath.endsWith("/"))
                    {
                        strPath.append("/");
                    }

                    QFile db(strPath + "data");
                    if (db.open(QIODevice::ReadWrite | QIODevice::Append))
                    {
                        QString strName, strLine;
                        QString strNoteName(_noteName);
                        strName = getNameFromFile(db, _noteName, strLine);
                        int nPos = getPositionFromFile(db);
                        QTextStream out(&db);
#if SAME_TITLES
                        if (strName == _noteName) //note already exists
                        {
                            strNoteName = generateUniqueName(strPath+ "/", _noteName);
                        }
                        out << QString("name=%1,position=%2,path=%3,title=%4,\n").arg(
                                   strNoteName).arg(nPos+1).arg(strPath + strNoteName).arg(_noteName);
#else
                        if (strName != _noteName) //note doesn't exists
                        {
                            out << QString("name=%1,position=%2,path=%3,title=%4,\n").arg(
                                       strNoteName).arg(nPos+1).arg(strPath + strNoteName).arg(_noteName);
                        }
#endif


                        QFile f(strPath+ "/" + strNoteName);
                        if (f.open(QIODevice::WriteOnly))
                        {
                            out.setDevice(&f);
                            out << _noteText;
                            f.close();
                        }

                        db.close();

                        emit noteAdded(_noteName);
                    }
                }
            }
        }
        dbs.close();
    }
}


/********************************************************************
 * deleteNote function deletes note from the notebook
 *
 *
 *******************************************************************/
void CDataHandler::deleteNote(const QString& _notebookID, const QString& _noteName)
{
    bool bFound = false;

    //check if the data folder exists
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/data");
        if (dbs.exists())
        {
            QString strLine, strPath, strName;

            if (dbs.open(QIODevice::ReadOnly | QIODevice::Append))
            {
                strName = getNameFromFile(dbs, _notebookID, strLine);
                if (strName == _notebookID)
                {
                    strPath = getStringAttribute(strLine,"path=");
                    if (!strPath.endsWith("/"))
                    {
                        strPath.append("/");
                    }

                    QFile db(strPath + "data");
                    QFile db2(strPath + "data.bak");
                    if (db.open(QIODevice::ReadOnly))
                    {
                        if (db2.open(QIODevice::WriteOnly | QIODevice::Append))
                        {
                            bFound = createTempFile(db, db2, _noteName);
                            db2.close();
                        }
                        db.close();
                    }
                }
                dbs.close();
            }

            if (bFound) //now we should replace old file with new one
            {
                if (QFile::remove(strPath + "data")) //remove old file
                {
                    QFile::rename(strPath + "data.bak", strPath + "data");
                    QFile::remove(strPath + _noteName);

                    emit noteRemoved(_noteName);
                }
            }
        }
    }
}


/********************************************************************
 * deleteNotes function deletes selected notes from the notebook
 *
 *
 *******************************************************************/
void CDataHandler::deleteNotes(const QString& _notebookID, const QStringList& _notes)
{
    for (int i = 0; i < _notes.size(); ++i)
    {
        deleteNote(_notebookID, _notes[i]);
    }
}


/********************************************************************
 * deleteNoteBook function deletes note book from the Notes
 *
 *
 *******************************************************************/
void CDataHandler::deleteNoteBook(const QString& _notebookID)
{
    bool bFound = false;
    // cannot remove default note book
    if (_notebookID == STR_DEFAULT_NOTEBOOK)
    {
        return;
    }

    //check if the data folder exists
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/data");
        if (dbs.exists())
        {

            QFile dbs2(home + ".MeeGo/Notes/data.bak");
            if (dbs.open(QIODevice::ReadOnly))
            {
                if (dbs2.open(QIODevice::WriteOnly | QIODevice::Append))
                {
                    bFound = createTempFile(dbs, dbs2, _notebookID);
                    dbs2.close();
                }
                dbs.close();
            }

            if (bFound) //now we should replace old file with new one
            {
                if (QFile::remove(home + ".MeeGo/Notes/data")) //remove old file
                {
                    QFile::rename(home + ".MeeGo/Notes/data.bak", home + ".MeeGo/Notes/data");
                    QString strNoteBook(_notebookID);
                    strNoteBook.replace(" ", "\\ ");
                    //					QString strCommand = QString("rm -rf %1").arg(home + ".MeeGo/Notes/"+ strNoteBook);
                    //                                        system((const char*)strCommand.toUtf8());
                    removeDir(home + ".MeeGo/Notes/"+ strNoteBook);

                    emit notebookRemoved(_notebookID);
                }
            }
        }
    }
}


/********************************************************************
 * deleteNoteBooks function deletes selected notebooks from the Notes
 *
 *
 *******************************************************************/
void CDataHandler::deleteNoteBooks(const QStringList& _notebooks)
{
    for (int i = 0; i < _notebooks.size(); ++i)
    {
        deleteNoteBook(_notebooks[i]);
    }
}


/********************************************************************
 * modifyNote function modifies the existing note
 *
 *
 *******************************************************************/
void CDataHandler::modifyNote(const QString& _notebookID, const QString& _noteName, const QString& _text)
{
    save(_notebookID, _noteName, _text);
    emit noteChanged();
}


/********************************************************************
 * moveNote function moves note from one notes book to other
 *
 *
 *******************************************************************/
void CDataHandler::moveNote(const QString& _notebookID, const QString& _noteName, const QString& _newNoteBookName)
{
    //check if the data folder exists
    if (checkAppData())
    {
        QString strFilePath,strNotebookPath,newNoteName;
        newNoteName = _noteName;
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/data");
        if (dbs.exists())
        {
            QString strLine, strPath, strName;
            if (dbs.open(QIODevice::ReadOnly | QIODevice::Append))
            {
                strName = getNameFromFile(dbs, _notebookID, strLine);
                if (strName == _notebookID)
                {
                    strPath = getStringAttribute(strLine, "path=");
                    if (!strPath.endsWith("/"))
                    {
                        strPath.append("/");
                    }

                    QFile db(strPath + "data");
                    if (db.open(QIODevice::ReadOnly))
                    {
                        strName = getNameFromFile(db, _noteName, strLine);
                        db.close();
                    }

                    strFilePath = getStringAttribute(strLine, "path=");
                    //get the path of the new notebook
                    if (dbs.reset())
                    {
                        strName = getNameFromFile(dbs, _newNoteBookName, strLine);
                        if (strName == _newNoteBookName)
                        {
                            strNotebookPath = getStringAttribute(strLine,"path=");
                            if (!strNotebookPath.endsWith("/"))
                            {
                                strNotebookPath.append("/");
                            }

                            QFile db2(strNotebookPath + "data");
                            if (db2.open(QIODevice::ReadWrite | QIODevice::Append))
                            {
                                int nPos = -1;
                                if (db2.size() == 0) //empty file
                                {
                                    nPos = 0;
                                }
                                else
                                {
                                    QString strName, strLine;
                                    strName = getNameFromFile(db2, _noteName, strLine);
                                    if (strName != _noteName) //such note does not exist
                                    {
                                        nPos = getPositionFromFile(db2);
                                    }
                                    else //note already exists
                                    {
                                        int counter =2;
                                        newNoteName = tr("%1 (%2)").arg(newNoteName).arg(QString::number(counter));

                                        while(getNameFromFile(db2, newNoteName, strLine) == newNoteName) {
                                            counter++;
                                            newNoteName = tr("%1 (%2)").arg(newNoteName).arg(QString::number(counter));
                                        }

                                        nPos = getPositionFromFile(db2);
                                    }
                                }

                                if (-1 != nPos)
                                {
                                    QTextStream out(&db2);
                                    out << QString("name=%1,position=%2,path=%3,title=%4,\n").arg(
                                               newNoteName).arg(nPos+1).arg(strNotebookPath + newNoteName).arg(newNoteName);

                                    if (QFile::copy(strFilePath, strNotebookPath+newNoteName))
                                    {
                                        deleteNote(_notebookID, _noteName);
                                    }
                                }
                                db2.close();
                            }
                        }

                    }
                }
                dbs.close();
            }
        }
    }
}


/********************************************************************
 *  moveNotes function moves selected notes from one notebook to other
 *
 *
 *******************************************************************/
void CDataHandler::moveNotes(const QString& _notebookID, const QStringList& _notes, const QString& _newNoteBookName)
{
    for (int i = 0; i < _notes.size(); ++i)
    {
        moveNote(_notebookID, _notes[i], _newNoteBookName);
    }
}


/********************************************************************
 * changeNotePosition function changes note position in the notes book
 *
 *
 *******************************************************************/
void CDataHandler::changeNotePosition(const QString& _notebookID, const QString& _noteName, int nNewPos)
{
    //check if the data folder exists
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/data");
        if (dbs.exists())
        {
            if (dbs.open(QIODevice::ReadOnly))
            {
                QString strLine, strPath, strName;
                strName = getNameFromFile(dbs, _notebookID, strLine);

                if (strName == _notebookID)
                {
                    strPath = getStringAttribute(strLine, "path=");

                    if (!strPath.endsWith("/"))
                    {
                        strPath.append("/");
                    }

                    QFile db(strPath + "data");
                    if (db.open(QIODevice::ReadOnly | QIODevice::Append))
                    {
                        QFile db2(strPath + "data.bak");
                        QTextStream outDb(&db);
                        QTextStream outDb2(&db2);
                        if (db2.open(QIODevice::WriteOnly | QIODevice::Append))
                        {
                            int nPos = -1;
                            QString strName, strNoteLine;

                            strName = getNameFromFile(db, _noteName, strNoteLine);

                            if (_noteName == strName)
                            {
                                QString strSaved;
                                QStringList lst;

                                nPos = getIntAttribute(strNoteLine, "position=");

                                if (nPos == nNewPos)
                                {
                                    db2.close();
                                    db.close();
                                    dbs.close();
                                    return;
                                }

                                db.reset();
                                while (!outDb.atEnd())
                                {
                                    QString strLine = outDb.readLine();
                                    if (nPos < nNewPos)
                                    {
                                        int nPos2 = getIntAttribute(strLine, "position=");
                                        int nStrPos2 = strLine.indexOf("position=");
                                        int nStr2Pos2 = strLine.indexOf(",", nStrPos2+1);

                                        if ((nPos2 < nPos) || (nPos2 > nNewPos))
                                        {
                                            outDb2 << strLine << "\n";
                                        }
                                        else if (nPos2 == nPos)
                                        {
                                            strSaved= strLine.replace(nStrPos2 + strlen("position="),
                                                                      nStr2Pos2 - (nStrPos2 + strlen("position=")),
                                                                      QString::number(nNewPos));
                                        }
                                        else
                                        {
                                            strLine.replace(nStrPos2 + strlen("position="),
                                                            nStr2Pos2 - (nStrPos2 + strlen("position=")),
                                                            QString::number(nPos2-1));
                                            outDb2 << strLine << "\n";

                                            if (nPos2 == nNewPos)
                                            {
                                                outDb2 << strSaved << "\n";
                                            }
                                        }
                                    }
                                    else
                                    {
                                        int nPos2 = getIntAttribute(strLine, "position=");

                                        int nStrPos2 = strLine.indexOf("position=");
                                        int nStr2Pos2 = strLine.indexOf(",", nStrPos2+1);
                                        if (nPos2 < nNewPos)
                                        {
                                            outDb2 << strLine << "\n";
                                        }
                                        else if (nPos2 > nPos)
                                        {
                                            if (!lst.isEmpty())
                                            {
                                                for (int i=0; i<lst.count(); i++)
                                                {
                                                    outDb2 << lst.at(i) << "\n";
                                                }

                                                lst.clear();
                                            }

                                            outDb2 << strLine << "\n";
                                        }
                                        else if (nPos2 == nPos)
                                        {
                                            strLine.replace(nStrPos2 + strlen("position="),
                                                            nStr2Pos2 - (nStrPos2 + strlen("position=")),
                                                            QString::number(nNewPos));
                                            outDb2 << strLine << "\n";
                                        }
                                        else
                                        {
                                            strLine.replace(nStrPos2 + strlen("position="),
                                                            nStr2Pos2 - (nStrPos2 + strlen("position=")),
                                                            QString::number(nPos2+1));
                                            lst.append(strLine);
                                        }
                                    }
                                }

                                if (!lst.isEmpty())
                                {
                                    for (int i=0; i<lst.count(); i++)
                                    {
                                        outDb2 << lst.at(i) << "\n";
                                    }
                                    lst.clear();
                                }
                            }
                            db2.close();
                        }
                        db.close();

                        if (QFile::remove(strPath + "data")) //remove old file
                        {
                            QFile::rename(strPath + "data.bak", strPath + "data");
                        }
                    }
                }
                dbs.close();
            }
        }
    }
}


/********************************************************************
 * getStringAttribute function get string attribute from the provided
 * string
 *
 *******************************************************************/
QString CDataHandler::getStringAttribute(const QString& _str, const QString& _attrName)
{
    QString strRet;

    int nStrPos = _str.indexOf(_attrName);
    if (-1 != nStrPos)
    {
        int nStrPos2 = _str.indexOf(",", nStrPos+1);
        if (-1 != nStrPos2)
        {
            strRet = _str.mid(nStrPos + _attrName.length(), nStrPos2 -(nStrPos + _attrName.length()));
        }
    }

    return strRet;
}


/********************************************************************
 * getIntAttribute function get integer attribute from the provided
 * string
 *
 *******************************************************************/
int CDataHandler::getIntAttribute(const QString& _str, const QString& _attrName)
{
    int nRet = -1;

    int nStrPos = _str.indexOf(_attrName);
    if (-1 != nStrPos)
    {
        int nStrPos2 = _str.indexOf(",", nStrPos+1);
        if (-1 != nStrPos2)
        {
            nRet = _str.mid(nStrPos + _attrName.length(), nStrPos2 -(nStrPos + _attrName.length())).toInt();
        }
    }

    return nRet;
}


/********************************************************************
 * getNameFromFile function get name attribute from the provided
 * file
 *
 *******************************************************************/
QString CDataHandler::getNameFromFile(QFile& _file, const QString& _value, QString& strLine)
{
    QString strName;

    _file.reset();
    QTextStream in(&_file);
    while (!in.atEnd())
    {
        strLine = in.readLine();
        strName = getStringAttribute(strLine, "name=");

        if (strName == _value)
        {
            break;
        }
    }

    return strName;
}


/********************************************************************
 * getPositionFromFile function get position attribute from the
 * provided file
 *
 *******************************************************************/
int CDataHandler::getPositionFromFile(QFile& _file)
{
    int nRet = 0;

    _file.reset();
    QTextStream in(&_file);
    QString strLine;
    while (!in.atEnd())
    {
        strLine = in.readLine();
        nRet = getIntAttribute(strLine, "position=");
    }

    return nRet;
}


/********************************************************************
 * save function saves the contents of the opened document to the
 * file
 *
 *******************************************************************/
void CDataHandler::save(const QString& _notebookID, const QString& _nodeName, const QString& _data)
{
    //check if the data folder exists
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/data");
        if (dbs.exists())
        {
            if (dbs.open(QIODevice::ReadOnly))
            {
                QString strLine, strPath, strName;
                strName = getNameFromFile(dbs, _notebookID, strLine);

                if (strName == _notebookID)
                {
                    strPath = getStringAttribute(strLine, "path=");

                    if (!strPath.endsWith("/"))
                    {
                        strPath.append("/");
                    }

                    QFile db(strPath + "data");
                    if (db.open(QIODevice::ReadWrite | QIODevice::Append))
                    {
                        strName = getNameFromFile(db, _nodeName, strLine);

                        if (strName == _nodeName)
                        {
                            QString strNotePath = getStringAttribute(strLine,"path=");

                            QFile db2(strNotePath);
                            if (db2.open(QIODevice::WriteOnly))
                            {
                                QTextStream out(&db2);
                                out << _data;
                                db2.close();
                            }
                        }

                        db.close();
                    }
                }
                dbs.close();
            }
        }
    }
}


/********************************************************************
 * load function loads the contents of the document from the file
 *
 *
 *******************************************************************/
void CDataHandler::load(const QString& _notebookID, const QString& _nodeName, QString& _data)
{
    //check if the data folder exists
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/data");
        if (dbs.exists())
        {
            if (dbs.open(QIODevice::ReadOnly))
            {
                QString strLine, strPath, strName;
                strName = getNameFromFile(dbs, _notebookID, strLine);

                if (strName == _notebookID)
                {
                    strPath = getStringAttribute(strLine, "path=");

                    if (!strPath.endsWith("/"))
                    {
                        strPath.append("/");
                    }

                    QFile db(strPath + "data");
                    if (db.open(QIODevice::ReadWrite | QIODevice::Append))
                    {
                        strName = getNameFromFile(db, _nodeName, strLine);

                        if (strName == _nodeName)
                        {
                            QString strNotePath = getStringAttribute(strLine,"path=");

                            QFile db2(strNotePath);
                            if (db2.open(QIODevice::ReadOnly))
                            {
                                _data = QString::fromUtf8(db2.readAll());
                                db2.close();
                            }
                        }

                        db.close();
                    }
                }
                dbs.close();
            }
        }
    }
}


/********************************************************************
 * getNoteBooks function read names of the existing note books from
 * the file and add them to the _noteBooks list
 *
 *******************************************************************/
void CDataHandler::getNoteBooks(int role, QStringList& _noteBooks, bool _sort)
{
    //check if the data folder exists
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/data");
        if (dbs.exists())
        {
            if (dbs.open(QIODevice::ReadOnly))
            {
                getStringsFromFile(dbs, role, _noteBooks);

                if (_sort)
                {
                    _noteBooks.removeAll(STR_DEFAULT_NOTEBOOK);
                    _noteBooks.sort();
                    _noteBooks.prepend(STR_DEFAULT_NOTEBOOK);
                }

                dbs.close();
            }
        }
    }
}


/********************************************************************
 * getNotes function read names of the existing notes from
 * the file and add them to the _notes list
 *
 *******************************************************************/
void CDataHandler::getNotes(const QString& _noteBook, int role, QStringList& _notes, bool _sort)
{
    //check if the data folder exists
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/data");
        if (dbs.exists())
        {
            if (dbs.open(QIODevice::ReadOnly))
            {
                QString strLine, strPath, strName;
                strName = getNameFromFile(dbs, _noteBook, strLine);

                if (strName == _noteBook)
                {
                    strPath = getStringAttribute(strLine, "path=");
                    if (!strPath.endsWith("/"))
                    {
                        strPath.append("/");
                    }

                    QFile db(strPath + "data");
                    if (db.open(QIODevice::ReadOnly))
                    {
                        getStringsFromFile(db, role, _notes);

                        if (_sort)
                        {
                            _notes.sort();
                        }

                        db.close();
                    }
                }

                dbs.close();
            }
        }
    }
}


QStringList CDataHandler::getNoteNames(QString _noteBook) {
    QStringList returnMe;
    getNotes(_noteBook,NoteModel::TitleRole,returnMe,false);
    return returnMe;
}


/********************************************************************
 * getStringsFromFile function read names of the existing
 * items(notes/notebooks) from the file and add them to the list
 *
 *******************************************************************/
void CDataHandler::getStringsFromFile(QFile& _file, int role, QStringList& _list)
{
    QString strLine, strName;
    QString strValue = (role == NoteModel::TitleRole) ? "title=" : "name=";

    _file.reset();

    QTextStream in(&_file);
    while (!in.atEnd())
    {
        strLine = in.readLine();
        strName = getStringAttribute(strLine, strValue);
        _list.append(strName);
    }
}


/********************************************************************
 * generateUniqueName function generates unique name for the given name
 *
 *
 *******************************************************************/
QString CDataHandler::generateUniqueName(const QString& _path, const QString& _originalName)
{
    QString str(_originalName);

    int i=1;
    while (QFile::exists(_path + str))
    {
        str = _originalName;
        str.append("_("+ QString::number(i) +")");
        i++;
    }

    return str;
}


/********************************************************************
 * createTempFile function creates temporary file
 *
 *
 *******************************************************************/
bool CDataHandler::createTempFile(QFile& dbs, QFile& dbs2, const QString& _notebookID)
{
    bool bFound = false;

    QString strLine, strName;

    dbs.reset();
    QTextStream in(&dbs);
    QTextStream out(&dbs2);
    while (!in.atEnd())
    {
        strLine = in.readLine();
        if (!bFound)
        {
            strName = getStringAttribute(strLine, "name=");
            if (strName == _notebookID)
            {
                bFound = true;
                continue;
            }
            else //add this line to the .bak file
            {
                out << strLine << "\n";
            }
        }
        else //bFound == true
        {
            int nPosition = getIntAttribute(strLine, "position=");
            nPosition--;
            int nStrPositionPos = strLine.indexOf("position=");
            int nStrPositionPos2 = strLine.indexOf(",", nStrPositionPos+1);
            strLine.replace(nStrPositionPos + strlen("position="),
                            nStrPositionPos2 - (nStrPositionPos + strlen("position=")),
                            QString::number(nPosition));
            out << strLine << "\n";
        }
    }

    return bFound;
}


/********************************************************************
 * loadNoteData function loads contents of the file
 *
 *
 *******************************************************************/
QString CDataHandler::loadNoteData(const QString& _notebookID, const QString& _fileName)
{
    QString strRet;

    load(_notebookID, _fileName, strRet);

    return strRet;
}


/********************************************************************
 * setSort function set sort flag to be sorted/unsorted
 *
 *
 *******************************************************************/
void CDataHandler::setSort(bool _bSort)
{
    //check if the data folder exists
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/config");
        //if (dbs.exists())
        {
            if (dbs.open(QIODevice::WriteOnly))
            {
                dbs.reset();
                QString strSort = _bSort ? "true" : "false";
                QTextStream out(&dbs);
                out << QString("SortNoteBooks=%1").arg(strSort);
                dbs.close();
            }
        }
    }
}


/********************************************************************
 * isSorted function returns the sort flag
 *
 *
 *******************************************************************/
bool CDataHandler::isSorted()
{
    bool bRet = false;

    //check if the data folder exists
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/config");
        if (dbs.exists())
        {
            QString strLine;

            if (dbs.open(QIODevice::ReadOnly))
            {
                dbs.reset();
                QTextStream in(&dbs);
                strLine = in.readLine();
                if (strLine == "SortNoteBooks=true")
                {
                    bRet = true;
                }
                dbs.close();
            }
        }
    }

    return bRet;
}


/********************************************************************
 * getNotePosition function returns position of the note
 *
 *
 *******************************************************************/
void CDataHandler::getNotePosition(const QString& _notebookID, const QString& _nodeName, QString& _position)
{
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/data");
        if (dbs.exists())
        {
            if (dbs.open(QIODevice::ReadOnly))
            {
                QString strLine, strPath, strName;
                strName = getNameFromFile(dbs, _notebookID, strLine);

                if (strName == _notebookID)
                {
                    strPath = getStringAttribute(strLine, "path=");
                    if (!strPath.endsWith("/"))
                    {
                        strPath.append("/");
                    }

                    QFile db(strPath + "data");
                    if (db.open(QIODevice::ReadWrite | QIODevice::Append))
                    {
                        strName = getNameFromFile(db, _nodeName, strLine);

                        if (strName == _nodeName)
                        {
                            int nPos = getIntAttribute(strLine, "position=");
                            _position = QString::number(nPos);
                        }

                        db.close();
                    }
                }
                dbs.close();
            }
        }
    }
}


/********************************************************************
 * getChildNotes function returns the total number of the notes in
 * the notebook
 *
 *******************************************************************/
int CDataHandler::getChildNotes(const QString& _notebookID)
{
    QString home(QDir::homePath());
    if (!home.endsWith("/"))
    {
        home.append("/");
    }

    if(STR_DEFAULT_NOTEBOOK == _notebookID) {
        QDir dir(home + ".MeeGo/Notes/" + tr("Everyday Notes"));
        QStringList list = dir.entryList(QDir::Files);
        list.removeAll("data");
        list.removeAll("data.bak");
        return list.count();
    }
    else {
        QDir dir(home + ".MeeGo/Notes/" + _notebookID + "/");
        QStringList list = dir.entryList(QDir::Files);
        list.removeAll("data");
        list.removeAll("data.bak");
        return list.count();
    }
    return 0;
}


/********************************************************************
 * getDate function returns the modification date of the notebook
 *
 *
 *******************************************************************/
QString CDataHandler::getDate(const QString& _notebookID)
{
    //check if the data folder exists
    QString result;
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QString noteBook = (_notebookID == STR_DEFAULT_NOTEBOOK) ?
                    tr("Everyday Notes") : _notebookID;

        QString strPath = home + ".MeeGo/Notes/" + noteBook + "/data";
        QFileInfo fileInfo(strPath);
        result = fileInfo.lastModified().date().toString(tr("dd-MMM-yyyy"));
    }

    return result;
}


/********************************************************************
 * getNoteBooks function returns names of the existing note books
 *
 *
 *******************************************************************/
QStringList CDataHandler::getNoteBooks()
{
    QStringList lst;
    getNoteBooks(NoteModel::NameRole, lst, false);
    return lst;
}


/********************************************************************
 * saveToFile function saves debug strings to the file
 *
 *
 *******************************************************************/
void CDataHandler::saveToFile(const QString& st)
{
    QString home(QDir::homePath());

    if (!home.endsWith("/"))
    {
        home.append("/");
    }

    QFile data(home + "output.txt");
    if (data.open(QFile::WriteOnly | QFile::Append))
    {
        QTextStream out(&data);
        out << st << endl;
    }
}


/********************************************************************
 * setCheckBox function sets checkBox flag to true/false
 *
 *
 *******************************************************************/
void CDataHandler::setCheckBox(bool _bShow)
{
    //check if the data folder exists
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/config");
        //if (dbs.exists())
        {
            if (dbs.open(QIODevice::WriteOnly))
            {
                dbs.reset();
                QString strShow = _bShow ? "true" : "false";
                QTextStream out(&dbs);
                out << QString("ShowCheckBox=%1").arg(strShow);
                dbs.close();
            }
        }
    }
}


/********************************************************************
 * getCheckBox function returns the checkBox flag
 *
 *
 *******************************************************************/
bool CDataHandler::getCheckBox()
{
    bool bRet = false;

    //check if the data folder exists
    if (checkAppData())
    {
        QString home(QDir::homePath());
        if (!home.endsWith("/"))
        {
            home.append("/");
        }

        QFile dbs(home + ".MeeGo/Notes/config");
        if (dbs.exists())
        {
            QString strLine;

            if (dbs.open(QIODevice::ReadOnly))
            {
                dbs.reset();
                QTextStream in(&dbs);
                strLine = in.readLine();
                if (strLine == "ShowCheckBox=true")
                {
                    bRet = true;
                }
                dbs.close();
            }
        }
    }

    return bRet;
}


/********************************************************************
 * removeFromString function removes item from string
 *
 *
 *******************************************************************/
QStringList CDataHandler::removeFromString(const QStringList& _array, const QString& _value)
{
    QStringList lst = _array;
    lst.removeOne(_value);
    return lst;
}

bool CDataHandler::removeDir(const QString &path)
{
    bool result = true;
    QDir dir(path);

    if (dir.exists(path)) {
        Q_FOREACH(QFileInfo info, dir.entryInfoList(QDir::NoDotAndDotDot | QDir::System
                                                    | QDir::Hidden  | QDir::AllDirs | QDir::Files, QDir::DirsFirst)) {
            if (info.isDir()) {
                result = removeDir(info.absoluteFilePath());
            }
            else {
                result = QFile::remove(info.absoluteFilePath());
            }

            if (!result) {
                return result;
            }
        }
        result = dir.rmdir(path);
    }

    return result;
}


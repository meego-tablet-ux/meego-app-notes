/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#ifndef TEXTEDITHANDLER_H
#define TEXTEDITHANDLER_H

#include <QtCore/QObject>
#include <QtGui/QTextEdit>

/********************************************************************
 * CTextEditHandler class declaration
 *
 * This class implements textedit handler. It provides such functions like:
 * bold, italic and underline
 *
 *******************************************************************/
class CTextEditHandler: public QObject
{
    Q_OBJECT

    enum FontRoles
    {
        BoldRole = Qt::UserRole + 1,
        ItalicRole,
        UnderlineRole,
    };

public:
    CTextEditHandler(QObject* parent = NULL);
    virtual ~CTextEditHandler();
    void Init();

    Q_INVOKABLE QString bold(const QString& _text, int _nPos, int _nPosEnd);
    Q_INVOKABLE QString italic(const QString& _text, int _nPos, int _nPosEnd);
    Q_INVOKABLE QString underline(const QString& _text, int _nPos, int _nPosEnd);
    Q_INVOKABLE QString toPlainText(const QString& _text);
    Q_INVOKABLE QString setFontFamily(const QString& _text, int _nPos, int _nPosEnd, const QString& _fontFamily);
    Q_INVOKABLE QString setFontSize(const QString& _text, int _nPos, int _nPosEnd, int _nPointSize);

protected:
    void setTextAndCursor(int role, const QString& _text, int _nPos, int _nPosEnd);

    QTextEdit* m_pEdit;
    bool m_bIsBold;
    bool m_bIsItalic;
    bool m_bIsUnderline;
};

#endif // TEXTEDITHANDLER_H



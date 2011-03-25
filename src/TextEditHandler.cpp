/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#include "TextEditHandler.h"

#include <QtGui/QTextCharFormat>
#include <QtGui/QTextDocumentFragment>


/********************************************************************
 * CTextEditHandler class declaration
 *
 * This class implements textedit handler. It provides such functions like:
 * bold, italic and underline
 *
 *******************************************************************/

/********************************************************************
 * CTextEditHandler - constructor of the class
 *
 *
 *******************************************************************/
CTextEditHandler::CTextEditHandler(QObject* parent):
    QObject(parent), m_pEdit(NULL),
    m_bIsBold(false), m_bIsItalic(false), m_bIsUnderline(false)
{
  Init();
}


/********************************************************************
 * ~CTextEditHandler - destructor of the class
 *
 *
 *******************************************************************/
CTextEditHandler::~CTextEditHandler()
{
  if (NULL != m_pEdit)
  {
    delete m_pEdit;
    m_pEdit = NULL;
  }
}


/********************************************************************
 * Init function makes some default operations
 *
 *
 *******************************************************************/
void CTextEditHandler::Init()
{
  m_pEdit = new QTextEdit(NULL);
  m_pEdit->setText("");
}


/********************************************************************
 * bold function makes selected text bold
 *
 *
 *******************************************************************/
QString CTextEditHandler::bold(const QString& _text, int _nPos, int _nPosEnd)
{
  setTextAndCursor(CTextEditHandler::BoldRole, _text, _nPos, _nPosEnd);
  return m_pEdit->toHtml();
}


/********************************************************************
 * italic function makes selected text italic
 *
 *
 *******************************************************************/
QString CTextEditHandler::italic(const QString& _text, int _nPos, int _nPosEnd)
{
  setTextAndCursor(CTextEditHandler::ItalicRole, _text, _nPos, _nPosEnd);
  return m_pEdit->toHtml();
}


/********************************************************************
 * underline function makes selected text underline
 *
 *
 *******************************************************************/
QString CTextEditHandler::underline(const QString& _text, int _nPos, int _nPosEnd)
{
  setTextAndCursor(CTextEditHandler::UnderlineRole, _text, _nPos, _nPosEnd);
  return m_pEdit->toHtml();
}


/********************************************************************
 * setTextAndCursor function set new text and move cursor to the new
 * position
 *
 *******************************************************************/
void CTextEditHandler::setTextAndCursor(int role, const QString& _text, int _nPos, int _nPosEnd)
{
  m_pEdit->setText(_text);

  QTextCursor cursor = m_pEdit->textCursor();

  if (_nPos == _nPosEnd) //no selection
  {
    cursor.setPosition(_nPos);
    if (!cursor.hasSelection())
    {
      cursor.select(QTextCursor::WordUnderCursor);
    }
  }
  else
  {
    cursor.setPosition(_nPos);
    cursor.setPosition(_nPosEnd, QTextCursor::KeepAnchor);
  }

  QString strSelection = cursor.selection().toHtml();
  QTextCharFormat fmt;

  if (CTextEditHandler::BoldRole == role)
  {
    m_bIsBold = (-1 != strSelection.indexOf("font-weight:")) ? false : true;
    fmt.setFontWeight(m_bIsBold ? QFont::Bold : QFont::Normal);
  }
  else if (CTextEditHandler::ItalicRole == role)
  {
    m_bIsItalic = (-1 != strSelection.indexOf("font-style:italic")) ? false : true;
    fmt.setFontItalic(m_bIsItalic);
  }
  else if (CTextEditHandler::UnderlineRole == role)
  {
    m_bIsUnderline = (-1 != strSelection.indexOf("text-decoration: underline;")) ? false : true;
    fmt.setFontUnderline(m_bIsUnderline);
  }

  cursor.mergeCharFormat(fmt);
  m_pEdit->mergeCurrentCharFormat(fmt);
}


/********************************************************************
 * toPlainText function converts Rich to Plain text
 *
 *
 *******************************************************************/
 QString CTextEditHandler::toPlainText(const QString& _text)
 {
   m_pEdit->setText(_text);
   return m_pEdit->toPlainText();
 }


/********************************************************************
 * setFontFamily function set new font family to the text
 *
 *
 *******************************************************************/
QString CTextEditHandler::setFontFamily(const QString& _text, int _nPos, int _nPosEnd, const QString& _fontFamily)
{
  m_pEdit->setText(_text);

  QTextCursor cursor = m_pEdit->textCursor();

  if (_nPos == _nPosEnd) //no selection
  {
    cursor.setPosition(_nPos);
    if (!cursor.hasSelection())
    {
      cursor.select(QTextCursor::WordUnderCursor);
    }
  }
  else
  {
    cursor.setPosition(_nPos);
    cursor.setPosition(_nPosEnd, QTextCursor::KeepAnchor);
  }

  QTextCharFormat fmt;
  fmt.setFontFamily(_fontFamily);
  cursor.mergeCharFormat(fmt);
  m_pEdit->mergeCurrentCharFormat(fmt);

  return m_pEdit->toHtml();
}


/********************************************************************
 * setFontSize function set new font size to the text
 *
 *
 *******************************************************************/
QString CTextEditHandler::setFontSize(const QString& _text, int _nPos, int _nPosEnd, int _nPointSize)
{
  m_pEdit->setText(_text);

  QTextCursor cursor = m_pEdit->textCursor();

  if (_nPos == _nPosEnd) //no selection
  {
    cursor.setPosition(_nPos);
    if (!cursor.hasSelection())
    {
      cursor.select(QTextCursor::WordUnderCursor);
    }
  }
  else
  {
    cursor.setPosition(_nPos);
    cursor.setPosition(_nPosEnd, QTextCursor::KeepAnchor);
  }

  QTextCharFormat fmt;
  fmt.setFontPointSize(_nPointSize);
  cursor.mergeCharFormat(fmt);
  m_pEdit->mergeCurrentCharFormat(fmt);

  return m_pEdit->toPlainText();
}



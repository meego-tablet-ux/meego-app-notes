include(../common.pri)
TEMPLATE = lib
TARGET = Notes
QT += core gui declarative sql
CONFIG += qt plugin
TARGET = $$qtLibraryTarget($$TARGET)
DESTDIR = $$TARGET
OBJECTS_DIR = .obj
MOC_DIR = .moc

SOURCES += \
    DataHandler.cpp \
    NotebooksModel.cpp \
    NoteModel.cpp \
    TextEditHandler.cpp \
    notesplugin.cpp \
    sqldatastorage.cpp

HEADERS += \
    DataHandler.h \
    NotebooksModel.h \
    NoteModel.h \
    TextEditHandler.h \
    notesplugin.h \
    sqldatastorage.h

qmldir.files += $$TARGET
qmldir.path += $$[QT_INSTALL_IMPORTS]/MeeGo/App
INSTALLS += qmldir

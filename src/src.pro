include(../common.pri)
TEMPLATE = lib
TARGET = Notes
QT += core gui declarative
CONFIG += qt plugin
TARGET = $$qtLibraryTarget($$TARGET)
DESTDIR = $$TARGET
OBJECTS_DIR = .obj
MOC_DIR = .moc

SOURCES += \
    DataHandler.cpp \
    NotebooksModel.cpp \
    NoteModel.cpp \
    ModelManager.cpp \
    TextEditHandler.cpp \
    notesplugin.cpp

HEADERS += \
    DataHandler.h \
    NotebooksModel.h \
    NoteModel.h \
    ModelManager.h \
    TextEditHandler.h \
    notesplugin.h

qmldir.files += $$TARGET
qmldir.path += $$[QT_INSTALL_IMPORTS]/MeeGo/App
INSTALLS += qmldir

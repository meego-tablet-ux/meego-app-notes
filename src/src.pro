include(../common.pri)
TEMPLATE = lib
TARGET = Notes
QT += core gui declarative sql
CONFIG += qt plugin debug link_pkgconfig
PKGCONFIG+= icu-i18n icu-uc meegolocale
TARGET = $$qtLibraryTarget($$TARGET)
DESTDIR = $$TARGET
OBJECTS_DIR = .obj
MOC_DIR = .moc

INCLUDEPATH += /usr/include/mlite

SOURCES += \
#    DataHandler.cpp \
#    NotebooksModel.cpp \
#    NoteModel.cpp \
#    TextEditHandler.cpp \
    notesplugin.cpp \
    sqldatastorage.cpp \
    models.cpp

HEADERS += \
#    DataHandler.h \
#    NotebooksModel.h \
#    NoteModel.h \
#    TextEditHandler.h \
    notesplugin.h \
    sqldatastorage.h \
    models.h

qmldir.files += $$TARGET
qmldir.path += $$[QT_INSTALL_IMPORTS]/MeeGo/App
INSTALLS += qmldir

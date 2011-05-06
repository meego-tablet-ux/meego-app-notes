include(common.pri)
TEMPLATE = subdirs
SUBDIRS+= src

qmlfiles.files += *.qml
qmlfiles.path += $$INSTALL_ROOT/usr/share/$$TARGET

QML_FILES = *.qml

LIB_SOURCES += src/*.cpp
LIB_HEADERS += src/*.h

OTHER_FILES += $${QML_FILES}

RESOURCES += \
    meego-app-notes.qrc

TRANSLATIONS += $${QML_FILES} $${LIB_SOURCES} $${LIB_HEADERS}
PROJECT_NAME = meego-app-notes

dist.commands += rm -fR $${PROJECT_NAME}-$${VERSION} &&
dist.commands += git clone . $${PROJECT_NAME}-$${VERSION} &&
dist.commands += rm -fR $${PROJECT_NAME}-$${VERSION}/.git &&
dist.commands += rm -f $${PROJECT_NAME}-$${VERSION}/.gitignore &&
dist.commands += mkdir -p $${PROJECT_NAME}-$${VERSION}/ts &&
dist.commands += lupdate $${TRANSLATIONS} -ts $${PROJECT_NAME}-$${VERSION}/ts/$${PROJECT_NAME}.ts &&
dist.commands += tar jcpf $${PROJECT_NAME}-$${VERSION}.tar.bz2 $${PROJECT_NAME}-$${VERSION} &&
dist.commands += rm -fR $${PROJECT_NAME}-$${VERSION} &&
dist.commands += echo; echo Created $${PROJECT_NAME}-$${VERSION}.tar.bz2
QMAKE_EXTRA_TARGETS += dist

INSTALLS += qmlfiles

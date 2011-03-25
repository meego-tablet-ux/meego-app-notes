/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Labs.Components 0.1

Item {
    id: container

    property alias contentLoader: contentLoader
    property alias leftButtonText: button1.title
    property alias rightButtonText: button2.title
    property alias dialogTitle: title.text
    property alias dialogHeight: contents.height
    property alias dialogWidth: contents.width

    anchors.fill: parent

    signal dialogClicked (int button)

    Rectangle {
        id: fog

        anchors.fill: parent
        color: theme_dialogFogColor
        opacity: theme_dialogFogOpacity
        Behavior on opacity {
            PropertyAnimation { duration: theme_dialogAnimationDuration }
        }
    }

    /* This mousearea is to prevent clicks from passing through the fog */
    MouseArea {
        anchors.fill: parent
    }

    BorderImage {
        id: dialog

        border.top: 14
        border.left: 20
        border.right: 20
        border.bottom: 20

        source: "image://theme/notificationBox_bg"

        anchors.centerIn: parent

        width: contents.width + 40 //478
        height: contents.height + 40 //318

        Item {
            id: contents

            anchors.centerIn: parent

            width: 400
            height: 220

            Column {
                id: contentColumn
                width: {
                    if (childrenRect.width > contents.width)
                        contents.width = childrenRect.width;

                    contents.width
                }

                Text {
                    anchors.left: parent.left
                    id: title
                    text: qsTr("Title text")
                    font.weight: Font.Bold
                    color: theme_dialogTitleFontColor
                }

                Loader {
                    id: contentLoader
                    anchors.top: title.bottom
                    anchors.topMargin: 20
                    width: parent.width
                    height: contents.height - (buttonBar.height + title.height)
                }

                Row {
                    id: buttonBar
                    height: childrenRect.height
                    spacing: 18
                    anchors.horizontalCenter: parent.horizontalCenter

                    Button {
                        id: button1
                        width: 180
                        height: 60
                        bgSourceUp: "image://theme/btn_red_up"
                        bgSourceDn: "image://theme/btn_red_dn"
                        onClicked: {
                            container.dialogClicked (1);
                        }
                    }

                    Button {
                        id: button2
                        width: button1.width
                        height: button1.height
                        onClicked: {
                            container.dialogClicked (2);
                        }
                    }
                }
            }
        }
    }
}

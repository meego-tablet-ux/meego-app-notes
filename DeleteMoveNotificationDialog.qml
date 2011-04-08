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

    property alias buttonText: button.title
    property alias dialogTitle: title.text
    property alias menuHeight: contents.height
    property alias menuWidth: contents.width
    property alias text: textReport.text

    anchors.fill: parent
    signal dialogClicked


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

        x: (container.width - width) / 2
        y: (container.height - height) / 2
        width: contents.width + 40 //478
        height: contents.height + 40 //318

        Item {
            id: contents
            x: 20
            y: 20

            width: 438
            height: textReport.paintedHeight + title.height + button.height + 45

            Text {
                id: title
                text: qsTr("Title text");
                font.weight: Font.Bold
                font.pixelSize: 14

                anchors { left: parent.left;
                    right: parent.right;
                    top: parent.top;
                }
            }


            Item {
                id: rectText;
                anchors { right: parent.right;
                    left: parent.left;
                    leftMargin:15
                    top: title.bottom;
                    topMargin: 25;
                    bottom: button.top;
                    bottomMargin: 15;
                    horizontalCenter: parent.horizontalCenter;
                }

                Text {
                    id: textReport
                    anchors.fill: parent;
                    text: qsTr("Notebook name");
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                }
            }

            Button {
                id: button
                width: 120
                height: 40
                bgSourceUp: "image://theme/btn_blue_up"
                bgSourceDn: "image://theme/btn_blue_dn"

                anchors {
                    bottom: parent.bottom;
                    bottomMargin: 5;
                    horizontalCenter: parent.horizontalCenter
                }

                onClicked: container.dialogClicked();
            }
        }
    }
}

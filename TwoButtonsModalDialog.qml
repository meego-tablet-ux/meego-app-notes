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
    width: 260
    height:125

    property alias buttonText: button.title
    property alias button2Text: button2.title
    property alias dialogTitle: title.text
    property alias menuHeight: contents.height
    property alias menuWidth: contents.width
    property alias defaultText: textInput.defaultText
    property alias text: textInput.text

    anchors.fill: parent
    signal button1Clicked
    signal button2Clicked

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

            Text {
                id: title
                text: qsTr("Title text");
                font.weight: Font.Bold
                font.pixelSize: 14

                anchors { left: parent.left;
                    right: parent.left;
                    top: parent.top;
                }
            }

            Rectangle {

                anchors { right: parent.right;
                    left: parent.left;
                    top: title.bottom;
                    topMargin: 15;
                    bottom: buttonBar.top;
                    bottomMargin: 15;
                }
                id: rectText;
                color: "white"
                //border.width: 1
                //focus: true

                TextEntry {
                    id: textInput
                    anchors.fill: parent;
                }
            }

            Row {
                id: buttonBar
                width: parent.width
                height: 40
                spacing: 20

                anchors {
                    bottom: parent.bottom;
                    right: parent.right;
                    left: parent.left;
                }

                Button {
                    id: button
                    width: 120
                    height: 40
                    bgSourceUp: "image://theme/btn_blue_up"
                    bgSourceDn: "image://theme/btn_blue_dn"

                    onClicked: container.button1Clicked();
                }

                Button {
                    id: button2
                    width: button.width
                    height: button.height

                    onClicked: container.button2Clicked();
                }
            }
        }
    }
}

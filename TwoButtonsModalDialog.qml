/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Components 0.1

Item {
    id: container
    width: 260
    height:125

    property alias buttonText: button.text
    property alias button2Text: button2.text
    property alias dialogTitle: title.text
    property alias menuHeight: contents.height
    property alias defaultText: textInput.defaultText
    property alias text: textInput.text

    property int minWidth: width
    property int maxCharactersCount: 50

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

            //autoresize
            width: {
                var buttonsWidth = button.width + button2.width
                if (title.paintedWidth < buttonsWidth) {
                    if (buttonsWidth < minWidth)
                        return minWidth;
                    else
                        return buttonsWidth;
                }

                if (title.paintedWidth < minWidth)
                    return minWidth;
                else
                    return title.paintedWidth;
            }

            height: title.height + rectText.height + charsIndicator.height

            Text {
                id: title
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
                    bottom: button.top
                    bottomMargin: 15;
                }
                id: rectText;
                color: "white"

                TextField {
                    id: textInput
                    anchors.fill: parent;

                    onTextChanged: {
                        var string = textInput.text;
                        charsIndicator.text = qsTr("%1/%2").arg(container.maxCharactersCount - string.length).arg(container.maxCharactersCount);
                        if (string.length <= container.maxCharactersCount)
                            return;
                        var cursorPosition = textInput.cursorPosition;
                        textInput.text = string.slice(0, container.maxCharactersCount);
                        textInput.cursorPosition = cursorPosition > container.maxCharactersCount ? cursorPosition - 1 : cursorPosition;
                    }
                }
            }

            Text {
                id: charsIndicator
                font.italic: true

                anchors.right: parent.right
                anchors.top: rectText.bottom

                font.pixelSize: 10

                text: qsTr("%1/%2").arg(container.maxCharactersCount).arg(container.maxCharactersCount)
            }

            Button {
                id: button
                bgSourceUp: "image://theme/btn_blue_up"
                bgSourceDn: "image://theme/btn_blue_dn"
                active: textInput.text.length > 0
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                onClicked:if (active) container.button1Clicked();
                width: 100
            }

            Button {
                id: button2
                onClicked: container.button2Clicked();
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: button.width
            }
        }
    }
}

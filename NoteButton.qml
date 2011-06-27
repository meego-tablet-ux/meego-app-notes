/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Ux.Components.Common 0.1
import MeeGo.Ux.Kernel 0.1
import MeeGo.Ux.Gestures 0.1
import MeeGo.Components 0.1

Rectangle {
    id: noteButton
    smooth: true

    property variant itemData: null //Note: noteBook or note
    property alias title: textElement.text
    property alias comment: textComment.text
    property alias checkBoxVisible: checkboxContainer.visible
    property alias showGrip: grip.visible

    signal itemSelected(variant itemData)
    signal itemDeselected(variant itemData)
    signal itemTapped(variant gesture, variant itemData)
    signal itemTappedAndHeld(variant gesture, variant itemData)
    signal gripTappedAndHeld(variant gesture, variant itemData)
    signal gripPanUpdated(variant gesture, variant itemData)
    signal gripPanFinished(variant gesture, variant itemData)

    height: theme.listBackgroundPixelHeightTwo

    Theme {
        id: theme
    }

    Text {
        id: gridView
        visible: false
    }

    Column {
        anchors.fill: parent
        spacing: 0

        Image {
            anchors.left: parent.left
            anchors.right: parent.right
            source: "image://themedimage/images/tasks/ln_grey_l"
        }

        Row {
            id: container
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 20
            anchors.leftMargin: checkBoxVisible ? 0 : spacing
            height: noteButton.height

            Item {
                id:checkboxContainer
                anchors.verticalCenter: parent.verticalCenter
                width: container.height
                height: container.height

                CheckBox {
                    id:checkbox
                    anchors.centerIn:parent
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.right:parent.right
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Qt.rgba(189/255, 189/255, 189/255, 1) //THEME
                }

		GestureArea {
                    anchors.fill: parent

                    Tap {
                        onFinished: {
                            checkbox.isChecked = !checkbox.isChecked;
                            noteButton.color = checkbox.isChecked ? Qt.rgba(230/255, 240/255, 255/255, 1) : "white";    //TODO: magic color
                            if (checkbox.isChecked)
                                itemSelected(itemData);
                            else
                                itemDeselected(itemData);
                        }
                    }
                }
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: checkBoxVisible ? noteButton.width - checkboxContainer.width - container.spacing - container.anchors.leftMargin
                                       : noteButton.width  - container.anchors.leftMargin
                height: container.height

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: grip.left
                    anchors.rightMargin: 10

                    Text {
                        id: textElement
                        font.pixelSize: theme.fontPixelSizeNormal
                        text: qsTr("Text element")
                        wrapMode: Text.Wrap
                    }

                    Text {
                        id: textComment
                        font.pixelSize: theme.fontPixelSizeSmall
                        text: qsTr("Add some comments here")
                        elide: Text.ElideRight
                        color: theme.fontColorInactive
                    }
                }

                Image {
                    id: grip
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: container.spacing

                    source: "image://themedimage/images/tasks/icn_grabhandle"

                    GestureArea {
                        anchors.fill: parent

                        TapAndHold {
                            onFinished: gripTappedAndHeld(gesture, itemData)
                        }

                        Pan {
                            onUpdated: gripPanUpdated(gesture, itemData)
                            onFinished: gripPanFinished(gesture, itemData)
                        }
                    }
                }

                GestureArea {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: grip.left

                    Tap {
                        onFinished: itemTapped(gesture, itemData)
                    }

                    TapAndHold {
                        onFinished: itemTappedAndHeld(gesture, itemData)
                    }
                }
            }
        }

        Image {
            anchors.left: parent.left
            anchors.right: parent.right
            source: "image://themedimage/images/tasks/ln_grey_l"
        }
    }
}

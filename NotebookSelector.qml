/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Labs.Components 0.1
import MeeGo.App.Notes 0.1

Item {
    id: container
    anchors.fill: parent

    signal notebookSelected(string newNotebookName)
    signal escapePressed()
    signal buttonOKClicked(string newNotebookName)
    signal buttonCancelClicked()

    Rectangle {
        id: fog
        anchors.fill: parent
        color: "slategray"
        opacity: 0.8

        Behavior on opacity {
            PropertyAnimation { duration: 500 }
        }
    }

    /* This mousearea is to prevent clicks from passing through the fog */
    MouseArea {
        anchors.fill: parent
    }

    Rectangle {
	id: mainRect
	color: "lightblue"
        width: 260; height: 200
        anchors.centerIn: parent
        //height: 280
	focus: true

	ListView {

            id:listView
            height: 200
            width: mainRect.width
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter
            property int index: 0;
            property string selectedNotebook:  qsTr("Everyday Notes (default)");

            model: notebooksModel
            delegate:
                Item {
                height: 25
                width: mainRect.width
                property int index: model.index;

                anchors.horizontalCenter: parent.horizontalCenter
                Text {
                    id: delegateText
                    anchors.centerIn: parent
                    text: model.name;
                    color: "white"
                }

                Keys.onReturnPressed:
                {
                    listView.selectedNotebook = delegateText.text;
                    container.notebookSelected(listView.selectedNotebook);
                }

                Keys.onEscapePressed:
                {
                    container.escapePressed();
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked:
                    {
                        listView.currentIndex = index;
                        listView.highlight = listView.highlighter;
                        listView.selectedNotebook = delegateText.text;
                    }

                    onDoubleClicked:
                    {
                        listView.selectedNotebook = delegateText.text;
                        container.notebookSelected(listView.selectedNotebook);
                    }
                }
            }
            highlight:
                Rectangle {
                id: highlighter;
                color: "lightsteelblue";
                width: listView.width
            }
            focus: true
            highlightFollowsCurrentItem: true
            header:
                Item {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 25

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("<b>Pick a notebook</b>");
                    color: "white"
                }
            }

            onCurrentIndexChanged:
            {
                //selectedNotebook = notebooksModel[currentIndex];
            }

            Keys.onReturnPressed:
            {
                container.notebookSelected(selectedNotebook);
                console.log("onReturnPressed");
            }
	}
        /*
  Row {
    //spacing: 30
    anchors.left: parent.left;
    anchors.right: parent.right;
    anchors.top: listView.bottom
    anchors.topMargin: 20

    Button {
      id: okButton
      anchors.right: cancelButton.left;
      anchors.rightMargin: 20
      title: qsTr("OK");
      x: 20;
      width: 100; height: 40;
      smooth:true;
      clip: true;
      bgSourceUp: "image://theme/notes/btn_spelling_up"
      bgSourceDn: "image://theme/notes/btn_spelling_dn"

      MouseArea {
        anchors.fill: parent
        onClicked:
        {
          if (okButton.active)
          {
            okButton.clicked(mouse)
          }

          listView.selectedNotebook = delegateText.text;
          mainRect.buttonOKClicked(listView.selectedNotebook)
        }

        onPressed: if (okButton.active) okButton.pressed = true
        onReleased: if (okButton.active) okButton.pressed = false
      }
    }

    Button {
      id: cancelButton
      anchors.right: parent.right;
      anchors.rightMargin: 20
      title: qsTr("Cancel");
      width: 100; height: 40;
      smooth:true;
      clip: true;
      bgSourceUp: "image://theme/notes/btn_spelling_up"
      bgSourceDn: "image://theme/notes/btn_spelling_dn"

      MouseArea {
        anchors.fill: parent
        onClicked:
        {
          if (cancelButton.active)
          {
            cancelButton.clicked(mouse)
          }

          mainRect.buttonCancelClicked()
          console.log("cancelButton::fontSize = "+ fontSize)
        }

        onPressed: if (cancelButton.active) cancelButton.pressed = true
        onReleased: if (cancelButton.active) cancelButton.pressed = false
      }
    }
  }*/
    }
}

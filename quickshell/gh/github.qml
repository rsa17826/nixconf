import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
  id: root

  // Data variables
  property string repoName: "github.com"
  property string timeStamp: ""
  property string updateTitle: "Waiting for data..."

  // Listen for lines from stdin
  // You can send data via: echo '{"title": "...", ...}' > /proc/<pid>/fd/0
  // or by piping tail -f into quickshell.
  Connections {
    function onLine(data) {
      try {
        for (var thing of JSON.parse(data)) {
          // thing?.title??="No Title"
          // thing?.url??="no url"
          updateTitle = thing.title;

          // Handling date
          let rawDate = thing?.updated_at || ""
          timeStamp = rawDate ? "Updated " + rawDate.split('T')[0] : "recently";

          // Extracting repo from URL
          let url = (thing.url) ? thing.url : (thing.url || "")
        }
      } catch (e) {
        console.log("Error parsing incoming data: " + e)
      }
    }

    target: Quickshell.stdin
  }
  PanelWindow {
    id: win

    implicitHeight: mainLayout.implicitHeight
    implicitWidth: 412

    anchors {
      right: true
      top: true
    }
    Rectangle {
      id: mainLayout

      anchors.fill: parent
      border.color: "#333333"
      border.width: 1
      color: "#121212"
      implicitHeight: 100

      Column {
        anchors.fill: parent
        spacing: 0

        // Header Bar (22px)
        Rectangle {
          color: "#a38b8b"
          height: 22
          width: parent.width

          Text {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: "white"
            font.bold: true
            font.family: "Monospace"
            font.pixelSize: 11
            renderType: Text.NativeRendering
            text: "GitHub Notifications"
          }
        }

        // Notification Body (56px)
        Item {
          anchors.leftMargin: 10
          height: 56
          width: parent.width

          // Text Content
          Column {
            anchors.left: iconBox.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
              color: "#ebc08d"
              elide: Text.ElideRight
              font.bold: true
              font.family: "Monospace"
              font.pixelSize: 15
              renderType: Text.NativeRendering
              text: updateTitle
              width: 340
            }
            Text {
              color: "#d1a77b"
              font.family: "Monospace"
              font.pixelSize: 12
              renderType: Text.NativeRendering
              text: "Release · " + repoName + " · " + timeStamp
            }
          }
        }

        // Footer Bar (22px)
        Rectangle {
          color: "#a38b8b"
          height: 22
          width: parent.width

          Text {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: "#e0e0e0"
            font.family: "Monospace"
            font.pixelSize: 11
            renderType: Text.NativeRendering
            text: "Sync Active"
          }
          Text {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: closeArea.containsMouse ? "white" : "#e0e0e0"
            font.family: "Monospace"
            font.pixelSize: 11
            renderType: Text.NativeRendering
            text: "Close"

            MouseArea {
              id: closeArea

              anchors.fill: parent
              hoverEnabled: true

              onClicked: Qt.quit()
            }
          }
        }
      }
    }
  }
}

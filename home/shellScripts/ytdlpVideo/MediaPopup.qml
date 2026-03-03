import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: root

  property string activeMode: ""
  readonly property string targetUrl: Quickshell.env("TARGET_URL") ?? ""

  // Window styling: Bottom Right
  WlrLayershell.layer: WlrLayershell.Overlay
  color: "transparent"
  implicitHeight: 120
  implicitWidth: 320

  anchors {
    bottom: true
    right: true
  }
  margins {
    bottom: 20
    right: 20
  }
  Rectangle {
    anchors.fill: parent
    border.color: "#313244"
    color: "#1e1e2e"
    radius: 12

    Column {
      anchors.fill: parent
      anchors.margins: 15
      spacing: 10

      Text {
        color: "#cdd6f4"
        font.bold: true
        text: "Media Found"
      }
      Row {
        spacing: 10

        // Video Button
        Rectangle {
          color: "#313244"
          height: 35
          radius: 6
          width: 90

          Text {
            anchors.centerIn: parent
            color: "white"
            text: "Video"
          }
          MouseArea {
            anchors.fill: parent

            onClicked: {
              activeMode = "Video"
              dlProcess.running = true
              root.visible = false
            }
          }
        }

        // Audio Button
        Rectangle {
          color: "#313244"
          height: 35
          radius: 6
          width: 90

          Text {
            anchors.centerIn: parent
            color: "white"
            text: "Audio"
          }
          MouseArea {
            anchors.fill: parent

            onClicked: {
              activeMode = "Audio"
              dlProcess.running = true
              root.visible = false
            }
          }
        }

        // Close Button
        Rectangle {
          color: "#f38ba8"
          height: 35
          radius: 6
          width: 60

          Text {
            anchors.centerIn: parent
            color: "white"
            text: "X"
          }
          MouseArea {
            anchors.fill: parent

            onClicked: Qt.quit()
          }
        }
      }
    }
  }
  Process {
    id: dlProcess

    // detached: true makes the process live on after the popup closes
    command: ["bash", "-c", "download_logic \"" + root.activeMode + "\" \"" + root.targetUrl + "\""]

    onExited: Qt.quit()
  }
}

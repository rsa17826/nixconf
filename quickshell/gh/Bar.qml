import Quickshell
import QtQuick
import QtQuick.Controls
import Quickshell.Io

Scope {
  property string ghBuffer: ""
  property int ghNotifCount

  // Timer {
  //   interval: 60000   // 60 seconds
  //   repeat: true
  //   running: true

  //   onTriggered: {
  //     updateGhNotifCount.running = true
  //   }
  // }
  Process {
    id: updateGhNotifCount

    command: ["sudo", "-n", "githubNotifications"]

    stdout: StdioCollector {
      onStreamFinished: data => {
        ghNotifCount = JSON.parse(data).length
      }
    }

    Component.onCompleted: running = true
    onFinished: (exitCode, exitStatus) => {
      if (exitStatus === Process.NormalExit && ghBuffer.length > 0) {
        try {
          // parse the entire buffer as JSON
          ghNotifCount = JSON.parse(ghBuffer).length
        } catch (e) {
          console.warn("Failed to parse multi-line JSON:", e)
          ghNotifCount = 0
        }
      }
      // clear buffer for next run
      ghBuffer = ""
    }
  }
  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData

      color: "#00000000"
      implicitHeight: 30
      screen: modelData

      Rectangle {
        anchors.centerIn: parent
        anchors.fill: parent
        color: "#00000000"

        Rectangle {
          anchors.centerIn: parent
          // anchors.fill: parent
          color: '#bf000000'
          implicitHeight: clock.implicitHeight + 12
          implicitWidth: clock.implicitWidth + 12
          radius: 0

          ClockWidget {
            id: clock

            anchors.centerIn: parent
          }
        }
        // Right-aligned rectangle (notification badge)
        Rectangle {
          id: ghBadge

          color: ghNotifCount > 0 ? "#d73a49" : "#888888"
          height: 20
          radius: 10
          // Width grows/shrinks based on number of digits
          width: Math.max(20, textItem.width + 10)

          anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
          }

          // Text showing number of notifications
          Text {
            id: textItem

            anchors.centerIn: parent
            color: "white"
            font.bold: true
            font.pixelSize: 12
            text: ghNotifCount > 0 ? ghNotifCount : ""
          }
        }
      }
      anchors {
        left: true
        right: true
        top: true
      }
    }
  }
}
// watch -n 10 'git diff --quiet && git diff --cached --quiet || (git add -A && git commit -m "a" && git push)'

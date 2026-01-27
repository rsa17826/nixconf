import Quickshell
import QtQuick
import QtQuick.Controls
import Quickshell.Io

Scope {
  property int ghNotifCount
  property string ghNotifData

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
      onStreamFinished: _ => {
        ghNotifData = text
        ghNotifCount = JSON.parse(text).length
      }
    }

    Component.onCompleted: running = true
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
        GithubNotif {
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

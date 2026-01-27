import Quickshell
import QtQuick
import QtQuick.Controls
import Quickshell.Io

Scope {
  // no more time object
  Process {
    id: getGhNotifCount

    command: ["sudo", "-n", "githubNotifications"]

    stdout: SplitParser {
      onRead: data => {
        if (!data)
          return
        var p = data.trim().split(/\s+/)
        var idle = parseInt(p[4]) + parseInt(p[5])
        var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)
        if (lastCpuTotal > 0) {
          cpuUsage = Math.round(100 * (1 - (idle - lastCpuIdle) / (total - lastCpuTotal)))
        }
        lastCpuTotal = total
        lastCpuIdle = idle
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

      // MarginWrapperManager {
      //   margin: 5
      // }
      Rectangle {
        anchors.centerIn: parent
        anchors.fill: parent
        color: "#00000000"

        Rectangle {
          anchors.centerIn: parent
          anchors.fill: par
          color: '#bf000000'
          implicitHeight: clock.implicitHeight + 12
          implicitWidth: clock.implicitWidth + 12
          radius: 0

          ClockWidget {
            id: clock

            anchors.centerIn: parent
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

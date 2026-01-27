import Quickshell
import QtQuick
import QtQuick.Controls

Scope {
  // no more time object

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

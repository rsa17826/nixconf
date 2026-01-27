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
          color: "#000000"
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

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

      Rectangle {
        anchors.centerIn: parent
        anchors.fill: parent
        color: "#00000000"

        ClockWidget {
          anchors.centerIn: parent
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

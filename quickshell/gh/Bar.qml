// Bar.qml
import Quickshell

Scope {
  // no more time object

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData

      implicitHeight: 30
      screen: modelData

      anchors {
        left: true
        right: true
        top: true
      }
      ClockWidget {
        anchors.centerIn: parent

        // no more time binding
      }
    }
  }
}

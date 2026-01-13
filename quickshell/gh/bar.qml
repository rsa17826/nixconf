// Bar.qml
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
  id: root

  property string time

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

      // the ClockWidget type we just created
      ClockWidget {
        anchors.centerIn: parent
        time: root.time
      }
    }
  }
  Process {
    id: dateProc

    command: ["date"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: root.time = this.text
    }
  }
  Timer {
    interval: 1000
    repeat: true
    running: true

    onTriggered: dateProc.running = true
  }
}

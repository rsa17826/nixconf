// ShutdownCountdown.qml
// Shows "Shuts Down in 2m23s" when a systemd shutdown is scheduled.
// Reads /run/systemd/shutdown/scheduled via awk every second.

import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property int secondsLeft: -1

  implicitHeight: label.implicitHeight
  implicitWidth: visible ? label.implicitWidth : 0

  // Hide entirely when no shutdown is pending
  visible: secondsLeft > 0

  Text {
    id: label

    property int m: Math.floor(root.secondsLeft / 60)
    property int s: root.secondsLeft % 60

    color: "#c680f0"
    font.pixelSize: 11
    text: `󰐥 Shuts Down in ${m}m${s < 10 ? "0" + s : s}s`
  }
  Process {
    id: proc

    command: ["awk", "-F=", "/^USEC=/{left=int(($2-systime()*1000000)/1000000); if(left>0)print left}", "/run/systemd/shutdown/scheduled"]

    stdout: StdioCollector {
      onStreamFinished: _ => {
        let val = parseInt(text.trim())
        root.secondsLeft = val
      }
    }

    Component.onCompleted: running = true
  }
  Timer {
    interval: 1000
    repeat: true
    running: true

    onTriggered: proc.running = true
  }
}

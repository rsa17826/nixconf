// RecIndicator.qml
// Shows a pulsing "REC 00:12" indicator in the bar while toggleRec.sh has
// an active gpu-screen-recorder session running (tracked via its PID file).
// Hidden entirely when nothing is recording.

import Quickshell
import Quickshell.Io
import QtQuick
import "owoify.js" as Owo

Item {
  id: root

  property bool recording: false
  property int secondsElapsed: 0

  implicitHeight: recording ? label.implicitHeight : 0
  implicitWidth: recording ? (dot.width + label.implicitWidth + 6) : 0
  visible: recording

  // Blink the dot while recording
  Timer {
    id: blinkTimer

    interval: 600
    repeat: true
    running: root.recording

    onTriggered: dot.on = !dot.on
  }

  Row {
    id: row

    spacing: 6

    anchors {
      left: parent.left
      verticalCenter: parent.verticalCenter
    }

    Rectangle {
      id: dot

      property bool on: true

      anchors.verticalCenter: parent.verticalCenter
      color: on ? "#e84d4d" : "#3a1414"
      height: 8
      radius: 4
      width: 8

      Behavior on color {
        ColorAnimation {
          duration: 150
        }
      }
    }
    Text {
      id: label

      color: "#e84d4d"
      font.pixelSize: 11

      text: {
        const h = Math.floor(root.secondsElapsed / 3600)
        const m = Math.floor(root.secondsElapsed / 60) % 60
        const s = root.secondsElapsed % 60
        const pad = n => (n < 10 ? "0" + n : "" + n)
        return Owo.owo(`REC ${h > 0 ? pad(h) + ":" : ""}${pad(m)}:${pad(s)}`)
      }
    }
  }

  // Poll once a second: is the PID in the file still alive, and since when?
  Process {
    id: poll

    command: ["bash", "-c", "PID_FILE=/tmp/gpu-screen-recorder-rec.pid; if [ -f \"$PID_FILE\" ] && kill -0 \"$(cat \"$PID_FILE\")\" 2>/dev/null; then start=$(stat -c %Y \"$PID_FILE\"); now=$(date +%s); echo \"REC $((now - start))\"; else echo IDLE; fi"]

    stdout: StdioCollector {
      onStreamFinished: {
        const t = text.trim()
        if (t.startsWith("REC")) {
          root.recording = true
          root.secondsElapsed = parseInt(t.split(" ")[1]) || 0
        } else {
          root.recording = false
          root.secondsElapsed = 0
        }
      }
    }

    Component.onCompleted: running = true
  }
  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true

    onTriggered: poll.running = true
  }
}

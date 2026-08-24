// RecIndicator.qml
import Quickshell
import Quickshell.Io
import QtQuick
import "owoify.js" as Owo

Item {
  id: root

  property bool checkDeath: false   // true = "should always be running";
  // only surface a warning when it's not
  property bool died: false
  property string filePath: "/tmp/gpu-screen-recorder-rec.pid"
  property bool neverStarted: false
  property bool paused: false
  property bool recording: false
  property int secondsElapsed: 0
  readonly property bool showSelf: checkDeath ? warn : recording
  property string stateFilePath: ""   // optional, e.g. "/tmp/gpu-screen-recorder-stream.state"
  property string text: "REC"

  // What this instance actually shows:
  //  - normal mode: only while recording
  //  - checkDeath mode: only while NOT recording (died or never started)
  readonly property bool warn: checkDeath && (died || neverStarted)

  implicitHeight: showSelf ? Math.max(12, label.implicitHeight) : 0
  implicitWidth: showSelf ? label.implicitWidth + 16 : 0
  visible: showSelf

  Rectangle {
    anchors.fill: parent
    border.color: root.warn ? "#e8b93d" : (root.paused ? "#4a4f6a" : "#2a3a8a")
    border.width: 1
    color: root.warn ? "#2e2508" : (root.paused ? "#1a1a2e" : "#12122c")
    radius: 4

    Text {
      id: label

      anchors.centerIn: parent
      color: root.warn ? "#ffcf4d" : (root.paused ? "#8a8fae" : "#c4cce8")
      font.pixelSize: 11
      text: {
        if (root.warn)
          return Owo.owo("⚠ " + root.text + " " + (root.neverStarted ? "not running" : "died"))
        const h = Math.floor(root.secondsElapsed / 3600)
        const m = Math.floor(root.secondsElapsed / 60) % 60
        const s = root.secondsElapsed % 60
        const pad = n => (n < 10 ? "0" + n : "" + n)
        const time = `${h > 0 ? pad(h) + ":" : ""}${pad(m)}:${pad(s)}`
        return Owo.owo(root.paused ? `${root.text} ⏸ ${time}` : `${root.text} ${time}`)
      }
    }
  }

  // Blink while warning
  Timer {
    interval: 500
    repeat: true
    running: root.warn || root.paused

    onTriggered: label.opacity = label.opacity === 1 ? 0.4 : 1
  }

  // Click to acknowledge/clear a dead pidfile (only relevant once died)
  MouseArea {
    anchors.fill: parent
    cursorShape: root.died ? Qt.PointingHandCursor : Qt.ArrowCursor
    enabled: root.died

    onClicked: clearProc.running = true
  }
  Process {
    id: clearProc

    command: ["rm", "-f", root.filePath]

    onRunningChanged: if (!running)
      root.died = false
  }
  Process {
    id: poll

    command: ["bash", "-c", "PID_FILE=\"" + filePath + "\"; STATE_FILE=\"" + stateFilePath + "\"; " + "if [ ! -f \"$PID_FILE\" ]; then echo NEVER; " + "elif kill -0 \"$(cat \"$PID_FILE\")\" 2>/dev/null; then " + "start=$(stat -c %Y \"$PID_FILE\"); now=$(date +%s); " + "state=Unpaused; [ -n \"$STATE_FILE\" ] && [ -f \"$STATE_FILE\" ] && state=$(cat \"$STATE_FILE\"); " + "echo \"REC $((now - start)) $state\"; " + "else echo DIED; fi"]

    stdout: StdioCollector {
      onStreamFinished: {
        const t = text.trim()
        if (t.startsWith("REC")) {
          const parts = t.split(" ")
          root.recording = true
          root.died = false
          root.neverStarted = false
          root.secondsElapsed = parseInt(parts[1]) || 0
          root.paused = parts[2] === "Paused"
        } else if (t === "DIED") {
          root.recording = false
          root.died = true
          root.neverStarted = false
          root.paused = false
        } else {
          // NEVER
          root.recording = false
          root.died = false
          root.neverStarted = true
          root.secondsElapsed = 0
          root.paused = false
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

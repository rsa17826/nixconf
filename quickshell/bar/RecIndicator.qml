// RecIndicator.qml
// Shows a pulsing "REC 00:12" indicator in the bar while toggleRec.sh has
// an active gpu-screen-recorder session running (tracked via its PID file).
// Hidden entirely when nothing is recording.
//
// ── Shader setup ──────────────────────────────────────────────────
// Uses a real fragment shader (shaders/recglitch.frag + .vert) for
// chromatic aberration / slice-glitch / bloom, instead of faking it with
// layered Rectangles. Qt6's shader pipeline needs GLSL compiled to .qsb:
//
//   qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 \
//       -o shaders/recglitch.vert.qsb shaders/recglitch.vert
//   qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 \
//       -o shaders/recglitch.frag.qsb shaders/recglitch.frag
//
// Run that from the directory containing shaders/, then point
// vertexShader/fragmentShader below at the .qsb outputs (already done).

import Quickshell
import Quickshell.Io
import QtQuick
import "owoify.js" as Owo

Item {
  id: root

  property bool recording: false
  property int secondsElapsed: 0

  implicitHeight: recording ? Math.max(12, contentItem.implicitHeight) : 0
  implicitWidth: recording ? contentItem.implicitWidth : 0
  visible: recording

  // Blink the dot while recording
  Timer {
    id: blinkTimer

    interval: 600
    repeat: true
    running: root.recording

    onTriggered: dot.on = !dot.on
  }

  // Drives iTime for the shader — cheap monotonically increasing seconds,
  // no need for sub-frame precision since it only seeds the slice noise.
  Timer {
    interval: 33
    repeat: true
    running: root.recording

    onTriggered: shaderEffect.iTime += 0.033
  }

  // ── Plain, unstyled content — the shader does all the visual work ──
  // This gets rendered offscreen into a texture (via layer.enabled) and
  // fed to the ShaderEffect below. Keep it simple/high-contrast so the
  // aberration and bloom have clean edges to work with.
  Item {
    id: contentItem

    readonly property int dotSize: 8

    implicitHeight: Math.max(dotSize, label.implicitHeight)
    implicitWidth: dotSize + 7 + label.implicitWidth
    layer.enabled: true
    layer.smooth: true
    visible: false     // only the shaded copy below is actually shown

    Row {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 7

      Rectangle {
        id: dot

        property bool on: true

        anchors.verticalCenter: parent.verticalCenter
        color: on ? "#ff4d6a" : "#3a1414"
        height: contentItem.dotSize
        radius: contentItem.dotSize / 2
        width: contentItem.dotSize
      }
      Text {
        id: label

        color: "#ffffff"
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
  }

  // ── Shaded output ──────────────────────────────────────────────
  ShaderEffect {
    id: shaderEffect

    property real aberration: 0.0035
    property real glitchAmount: 0.03
    property real iTime: 0.0
    property variant source: contentItem

    anchors.fill: contentItem
    fragmentShader: "shaders/recglitch.frag.qsb"
    vertexShader: "shaders/recglitch.vert.qsb"
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

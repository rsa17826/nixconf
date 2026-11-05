import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import Quickshell.Io

import Quickshell.Services.Mpris

Scope {
  Variants {
    model: Quickshell.screens.filter(screen => screen.name === "test_top")

    // model: Quickshell.screens.filter(screen => screen.name === "HDMI-A-1")

    PanelWindow {
      id: root

      property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
      property int ghNotifCount
      property string ghNotifData
      required property var modelData

      WlrLayershell.keyboardFocus: WlrLayershell.None
      WlrLayershell.layer: WlrLayer.Overlay
      color: "transparent"
      // implicitHeight: 34   // a bit taller, spikes eat into the bar

      implicitHeight: 28
      implicitWidth: Screen.width
      screen: modelData

      anchors {
        left: true
        right: true
        top: true
      }
      Item {
        id: barContent

        property real time: 0

        anchors.fill: parent
        layer.enabled: true

        layer.effect: ShaderEffect {
          property real amplitude: 4    // peak depth; a typical spike reaches about half of this
          property real edgeWidth: 10
          property vector2d resolution: Qt.vector2d(barContent.width, barContent.height)
          property real sharpness: 20
          property real speed: 2
          property real spikeWidth: 8   // wider cells so the needles have gaps between them
          property real time: barContent.time

          fragmentShader: "shaders/barspike.frag.qsb"
          vertexShader: "shaders/barspike.vert.qsb"
        }

        FrameAnimation {
          running: true

          onTriggered: barContent.time += frameTime
        }

        // ── Void bar background ──────────────────────────────────
        Rectangle {
          anchors.fill: parent
          color: "#03030a"

          Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            color: "#1e1e40"
            height: 1
          }
        }
        MediaProgress {
        }
        Item {
          id: _LEFT

          anchors {
            left: parent.left
            leftMargin: 5
            verticalCenter: parent.verticalCenter
          }
          CountdownTimerRow {
            id: countdownRow

            maxWidth: _CENTER.x - countdownRow.x - 10

            anchors {
              left: parent.left
              verticalCenter: parent.verticalCenter
            }
          }
          TimerServer {
            timerRow: countdownRow
          }
        }
        // Center container holding just the Clock and absolute-positioned elements
        Item {
          id: _CENTER

          height: clock.implicitHeight > 0 ? clock.implicitHeight : clock.height

          // Explicitly set width to clock's width so countdownRow's math works cleanly
          width: clock.implicitWidth > 0 ? clock.implicitWidth : clock.width

          anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
          }
          Clock {
            id: clock

            timerRow: countdownRow

            anchors {
              horizontalCenter: parent.horizontalCenter
              verticalCenter: parent.verticalCenter
            }
          }
          ShutdownCountdown {
            anchors {
              left: clock.right
              verticalCenter: parent.verticalCenter
            }
          }
        }
        Item {
          id: _RIGHT

          anchors {
            horizontalCenter: parent.right
            verticalCenter: parent.verticalCenter
          }
          RecIndicator {
            id: flashbackIndicator

            checkDeath: true
            filePath: "/tmp/gpu-screen-recorder-flashback.pid"
            text: "FB"

            anchors {
              right: streamIndicator.left
              rightMargin: 12
              verticalCenter: parent.verticalCenter
            }
          }
          RecIndicator {
            id: streamIndicator

            filePath: "/tmp/gpu-screen-recorder-stream.pid"
            stateFilePath: "/tmp/gpu-screen-recorder-stream.state"
            text: "STREAM"

            anchors {
              right: recIndicator.left
              rightMargin: 12
              verticalCenter: parent.verticalCenter
            }
          }
          RecIndicator {
            id: recIndicator

            filePath: "/tmp/gpu-screen-recorder-rec.pid"
            logUnit: "flashback"
            text: "REC"

            anchors {
              right: trayWidget.left
              rightMargin: 12
              verticalCenter: parent.verticalCenter
            }
          }
          Tray {
            id: trayWidget

            anchors {
              right: wifiWidget.left
              rightMargin: 15
              verticalCenter: parent.verticalCenter
            }
          }
          Wifi {
            id: wifiWidget

            anchors {
              right: syncthingWidget.left
              rightMargin: 12
              verticalCenter: parent.verticalCenter
            }
          }
          Syncthing {
            id: syncthingWidget

            anchors {
              right: githubWidget.left
              rightMargin: 15
              verticalCenter: parent.verticalCenter
            }
          }
          GithubNotif {
            id: githubWidget

            anchors {
              right: notifBell.left
              rightMargin: 12
              verticalCenter: parent.verticalCenter
            }
          }
          NotifBell {
            id: notifBell

            anchors {
              right: parent.right
              rightMargin: 12
              verticalCenter: parent.verticalCenter
            }
          }
        }
      }
    }
  }
}

// watch -n 10 'git diff --quiet && git diff --cached --quiet || (git add -A && git commit -m "a" && git push)'

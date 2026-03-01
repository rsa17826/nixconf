import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import Quickshell.Io

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: root

      property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
      property int ghNotifCount
      property string ghNotifData
      required property var modelData

      WlrLayershell.keyboardFocus: WlrLayershell.None
      WlrLayershell.layer: WlrLayer.Overlay
      color: "transparent"
      implicitHeight: 32
      implicitWidth: Screen.width
      screen: modelData

      anchors {
        left: true
        right: true
        top: true
      }
      Rectangle {
        anchors.fill: parent
        color: root.activePlayer ? "rgba(0, 0, 0, 0.4)" : "transparent"

        Rectangle {
          id: progressFill

          color: '#d12121'
          height: 2
          width: (root.activePlayer && root.activePlayer.length > 0) ? (parent.width * (root.activePlayer.position / root.activePlayer.length)) : 0
        }
      }

      // Update the position from DBus
      Timer {
        interval: 500
        repeat: true
        running: !!root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing

        onTriggered: root.activePlayer.positionChanged()
      }
      Rectangle {
        anchors.centerIn: parent
        anchors.fill: parent
        color: "transparent"

        Rectangle {
          anchors.centerIn: parent
          // anchors.fill: parent
          color: '#bf000000'
          implicitHeight: clock.implicitHeight + 12
          implicitWidth: clock.implicitWidth + 12
          radius: 0

          ClockWidget {
            id: clock

            anchors.centerIn: parent
          }
        }
        // Right-aligned rectangle (notification badge)
        GithubNotif {
          Timer {
            interval: 60000   // 60 seconds
            repeat: true
            running: true

            onTriggered: {
              updateGhNotifCount.running = true
            }
          }
          Process {
            id: updateGhNotifCount

            command: ["sudo", "-n", "githubNotifications"]

            stdout: StdioCollector {
              onStreamFinished: _ => {
                ghNotifData = text
                ghNotifCount = JSON.parse(text).length
              }
            }

            Component.onCompleted: running = true
          }
        }
      }
    }
  }
}

// watch -n 10 'git diff --quiet && git diff --cached --quiet || (git add -A && git commit -m "a" && git push)'

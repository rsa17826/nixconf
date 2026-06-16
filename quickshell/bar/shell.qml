//@ pragma UseQApplication
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
      implicitHeight: 28
      implicitWidth: Screen.width
      screen: modelData

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
      anchors {
        left: true
        right: true
        top: true
      }
      Rectangle {
        id: _LEFT

        anchors {
          horizontalCenter: parent.left
          verticalCenter: parent.verticalCenter
        }
        // ClipHist {
        //   id: clipboardLogic

        //   anchors {
        //     left: root.left
        //     verticalCenter: parent.verticalCenter
        //   }
        // }
      }
      Rectangle {
        id: _CENTER

        anchors {
          horizontalCenter: parent.horizontalCenter
          verticalCenter: parent.verticalCenter
        }
        Clock {
          id: clock

          anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
          }
        }
        ShutdownCountdown {
          anchors {
            left: clock.right
            leftMargin: 15
            verticalCenter: parent.verticalCenter
          }
        }
        Row {
          anchors {
            verticalCenter: parent.verticalCenter
          }
        }
      }
      Rectangle {
        id: _RIGHT

        anchors {
          horizontalCenter: parent.right
          verticalCenter: parent.verticalCenter
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

// watch -n 10 'git diff --quiet && git diff --cached --quiet || (git add -A && git commit -m "a" && git push)'

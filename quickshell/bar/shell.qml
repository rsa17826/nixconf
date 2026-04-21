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
      MediaProgress {
      }
      Row {
        spacing: 8

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
      Tray {
        anchors {
          right: githubWidget.left
          rightMargin: 15
          verticalCenter: parent.verticalCenter
        }
      }
      GithubNotif {
        id: githubWidget

      }
      ClipHist {
        id: clipboardLogic

        anchors {
          left: main.left
          verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}

// watch -n 10 'git diff --quiet && git diff --cached --quiet || (git add -A && git commit -m "a" && git push)'

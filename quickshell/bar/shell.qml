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

      // Clipboard text aligned left
      Text {
        id: clipboardDisplay

        color: "#cccccc"
        elide: Text.ElideRight
        font.pixelSize: 11
        text: clipboardLogic.clipboardItems.length > 0 ? clipboardLogic.clipboardItems[0].preview : "Empty"
        width: 400

        anchors {
          left: parent.left
          leftMargin: 10
          verticalCenter: parent.verticalCenter
        }
      }

      // Clock centered
      Clock {
        anchors {
          horizontalCenter: parent.horizontalCenter
          verticalCenter: parent.verticalCenter
        }
      }

      // Tray positioned to the left of Github widget
      Tray {
        anchors {
          right: githubWidget.left
          rightMargin: 15
          verticalCenter: parent.verticalCenter
        }
      }

      // Github widget on the far right
      GithubNotif {
        id: githubWidget

      }
      ClipHist {
        id: clipboardLogic

      }
    }
  }
}

// watch -n 10 'git diff --quiet && git diff --cached --quiet || (git add -A && git commit -m "a" && git push)'

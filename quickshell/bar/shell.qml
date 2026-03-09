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

      MediaProgress {
      }
      anchors {
        left: true
        right: true
        top: true
      }

      // Left side content (Clock)
      Clock {
        anchors {
          left: parent.left
          verticalCenter: parent.verticalCenter
        }
      }

      // Center content (Media progress + Clipboard text)
      Row {
        spacing: 20

        anchors {
          left: parent.left
          leftMargin: 100
          verticalCenter: parent.verticalCenter
        }
        Text {
          id: clipboardDisplay

          anchors.verticalCenter: parent.verticalCenter
          color: "#cccccc"
          elide: Text.ElideRight
          font.pixelSize: 11
          text: clipboardLogic.clipboardItems.length > 0 ? clipboardLogic.clipboardItems[0].preview : "Empty"
          width: 300
        }
      }

      // Right side content (Tray + Github Notifications)
      Row {
        spacing: 15

        anchors {
          right: parent.right
          rightMargin: 10
          verticalCenter: parent.verticalCenter
        }
        Tray {
        }
        GithubNotif {
        }
      }
      ClipHist {
        id: clipboardLogic

      }
    }
  }
}

// watch -n 10 'git diff --quiet && git diff --cached --quiet || (git add -A && git commit -m "a" && git push)'

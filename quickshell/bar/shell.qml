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
      Clock {
      }
      MediaProgress {
      }
      GithubNotif {
      }
      Tray {
      }
      ClipHist {
      }
      // inside shell.qml
      ClipHist {
        id: clipboardLogic

      }

      // Then in your bar
      Text {
        text: clipboardLogic.clipboardItems.length > 0 ? clipboardLogic.clipboardItems[0].preview : "Empty"
      }
    }
  }
}

// watch -n 10 'git diff --quiet && git diff --cached --quiet || (git add -A && git commit -m "a" && git push)'

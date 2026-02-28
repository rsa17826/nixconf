import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

PanelWindow {
  id: root

  property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

  color: "transparent"

  // 1. Start with a standard window to let Wayland initialize
  implicitHeight: 4
  width: Screen.width

  // 2. Use a Timer to attach LayerShell properties after 100ms
  // This bypasses the "Non-existent attached object" crash
  Timer {
    id: initTimer

    interval: 100
    repeat: false
    running: true

    onTriggered: {
      WlrLayerShell.layer = WlrLayerShell.Overlay
      WlrLayerShell.anchor = WlrLayerShell.Top | WlrLayerShell.Left | WlrLayerShell.Right
      WlrLayerShell.exclusive = false
    }
  }
  Rectangle {
    anchors.fill: parent
    color: root.activePlayer ? "rgba(0, 0, 0, 0.4)" : "transparent"

    Rectangle {
      id: progressFill

      color: "#7aa2f7"
      height: parent.height
      width: (root.activePlayer && root.activePlayer.length > 0) ? (parent.width * (root.activePlayer.position / root.activePlayer.length)) : 0

      Behavior on width {
        NumberAnimation {
          duration: 500
          easing.type: Easing.Linear
        }
      }
    }
  }
  Timer {
    interval: 500
    repeat: true
    running: !!root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing

    onTriggered: {
      if (root.activePlayer)
        root.activePlayer.positionChanged()
    }
  }
}

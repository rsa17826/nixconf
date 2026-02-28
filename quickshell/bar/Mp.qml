import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

PanelWindow {
  id: root

  property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

  WlrLayershell.keyboardFocus: None
  WlrLayershell.layer: WlrLayer.Overlay
  color: "transparent"
  implicitHeight: 2
  implicitWidth: Screen.width

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
      height: parent.height
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
}

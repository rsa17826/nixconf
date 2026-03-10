import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import Quickshell.Io

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

Rectangle {
  color: root.activePlayer ? "rgba(0, 0, 0, 0.4)" : "transparent"
  height: 2
  width: parent.width

  Rectangle {
    id: progressFill

    color: '#d12121'
    height: 2
    width: (root.activePlayer && root.activePlayer.length > 0) ? (parent.width * (root.activePlayer.position / root.activePlayer.length)) : 0
  }
  // Update the position from DBus
  Timer {
    interval: 500
    repeat: true
    running: !!root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing

    onTriggered: root.activePlayer.positionChanged()
  }
}

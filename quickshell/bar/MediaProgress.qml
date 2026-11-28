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
  color: root.activePlayer ? "#071426" : "transparent"
  height: 0
  width: parent.width

  Rectangle {
    id: progressFill

    color: '#40d9ff'
    height: 2
    width: (root.activePlayer?.length > 0) ? (parent.width * (root.activePlayer.position / root.activePlayer.length)) : 0
  }
  // Update the position from DBus
  Timer {
    interval: 500
    repeat: true
    running: !!root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing

    onTriggered: root.activePlayer.positionChanged()
  }
}

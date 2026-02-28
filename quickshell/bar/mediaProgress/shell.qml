import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import QtQuick.Controls

PanelWindow {
  id: root

  property var activePlayer: players.length > 0 ? players[0] : null
  property var players: Mpris.players.values

  implicitHeight: 120
  implicitWidth: 400

  Rectangle {
    anchors.fill: parent
    border.color: activePlayer ? "#7aa2f7" : "#3b4261"
    border.width: 2
    color: "#1a1b26"
    radius: 8
  }
  Column {
    anchors.centerIn: parent
    spacing: 10
    width: parent.width - 40

    Text {
      color: "white"
      elide: Text.ElideRight
      font.bold: true
      horizontalAlignment: Text.AlignHCenter
      // Use the 'metadata' property if 'title' is blank,
      // and provide a fallback so it doesn't stay stuck on "Waiting..."
      text: (root.activePlayer && root.activePlayer.title) ? root.activePlayer.title : (root.activePlayer ? "Unknown Track" : "No Player Detected")
      width: parent.width
    }
    Slider {
      id: progressSlider

      enabled: !!root.activePlayer

      // MPRIS length is in microseconds. Slider works better in seconds.
      from: 0
      to: root.activePlayer ? (root.activePlayer.length / 1000000) : 100
      value: root.activePlayer ? (root.activePlayer.position / 1000000) : 0
      width: parent.width

      onMoved: {
        if (root.activePlayer) {
          // IMPORTANT: Brave expects microseconds for seeking.
          // If you send 'seconds' here, it seeks to the very beginning (0.00x),
          // which makes the song restart.
          root.activePlayer.position = value * 1000000
        }
      }
    }
  }
  Timer {
    interval: 500
    repeat: true
    running: true

    onTriggered: {
      if (root.activePlayer) {
        root.activePlayer.positionChanged()
      }
    }
  }
}

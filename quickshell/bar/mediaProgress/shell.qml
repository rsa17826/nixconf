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

  // 1. Initial window setup
  implicitHeight: 4
  width: Screen.width

  // Logic to enable animation ONLY after the first value is set
  // onActivePlayerChanged: {
  //   if (activePlayer) {
  //     // Small delay to ensure the bar has moved to its starting position
  //     // before we enable smooth sliding animations.
  //     timerEnableAnim.start()
  //   } else {
  //     widthBehavior.enabled = false
  //   }
  // }

  anchors {
    left: true
    right: true
    top: true
  }

  // 2. Delayed attachment to fix "Non-existent attached object"
  // This ensures the bar is on top of EVERYTHING, including fullscreen apps.
  Timer {
    interval: 100
    repeat: false
    running: true

    onTriggered: {

      // Doesn't push windows down
    }
  }
  Rectangle {
    anchors.fill: parent
    color: root.activePlayer ? "rgba(0, 0, 0, 0.4)" : "transparent"

    Rectangle {
      id: progressFill

      color: "#7aa2f7"
      height: parent.height

      // Width logic
      width: (root.activePlayer && root.activePlayer.length > 0) ? (parent.width * (root.activePlayer.position / root.activePlayer.length)) : 0

      // 3. Animation with onFirst: false behavior
      // Behavior on width {
      //   id: widthBehavior

      //   enabled: root.targetWidth > progressFill.width

      //   NumberAnimation {
      //     duration: 500
      //     easing.type: Easing.Linear
      //   }
      // }
    }
  }
  Timer {
    id: timerEnableAnim

    interval: 1000

    onTriggered: widthBehavior.enabled = true
  }

  // Update the position from DBus
  Timer {
    interval: 500
    repeat: true
    running: !!root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing

    onTriggered: root.activePlayer.positionChanged()
  }
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

ShellRoot {
  Variants {
    model: Quickshell.screens

    delegate: WlrLayerShell {
      anchors.left: true
      anchors.right: true

      // Anchor to top, left, and right to span the screen
      anchors.top: true

      // Ensure it doesn't take focus or block mouse clicks
      exclusionMode: WlrLayer.ExclusionMode.None

      // Total height of 4px
      height: 4
      keyboardFocus: WlrLayer.KeyboardFocus.None

      // Layer 'Overlay' keeps it above fullscreen apps
      layer: WlrLayer.Overlay
      // Target every screen
      screen: modelData

      // The Progress Bar Container
      Rectangle {

        // We use the first available active player
        property var player: Mpris.player

        anchors.fill: parent
        color: "transparent"
        visible: Mpris.player?.playbackStatus === Mpris.Playing

        // Calculate width based on position/length
        Rectangle {
          id: progressBar

          color: "transparent"
          height: parent.height
          width: parent.width * (parent.player?.position / parent.player?.length || 0)

          // Smooth animation for position updates
          Behavior on width {
            NumberAnimation {
              duration: 500
            }
          }

          // Top 2px: Red
          Rectangle {
            anchors.top: parent.top
            color: "#FF0000"
            height: 2
            width: parent.width
          }

          // Bottom 2px: Black
          Rectangle {
            anchors.bottom: parent.bottom
            color: "#000000"
            height: 2
            width: parent.width
          }
        }
      }
    }
  }
}

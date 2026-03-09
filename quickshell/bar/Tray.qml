import Quickshell
import Quickshell.Services.SystemTray
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import Quickshell.Io

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Widgets

Row {
  // This repeats for every icon (OpenSnitch, Network, etc.)
  Repeater {
    model: SystemTray.items

    delegate: MouseArea {
      height: 24
      width: 24

      onClicked: mouse => modelData.activate(mouse.x, mouse.y)
      // onSecondaryClicked: mouse => modelData.contextMenu(mouse.x, mouse.y)

      IconImage {
        anchors.fill: parent
        source: modelData.icon // This is where OpenSnitch's icon lives
      }
    }
  }
}

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
  color: "transparent"
  implicitHeight: clock.implicitHeight + 12
  implicitWidth: clock.implicitWidth + 12

  Text {
    id: clock

    anchors.centerIn: parent
    color: "#c4cce8"
    text: Time.time

    font {
      family: "monospace"
      pointSize: 10
    }
  }
}

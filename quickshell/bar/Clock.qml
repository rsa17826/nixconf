import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import Quickshell.Io

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "owoify.js" as Owo

Rectangle {
  color: "transparent"
  implicitHeight: clock.implicitHeight + 12
  implicitWidth: clock.implicitWidth + 12

  GlitchEffect {
    id: clockGlitch

    aberration: 0.0025
    glitchAmount: 0.035
    glitchRate: 1.4

    anchors {
      leftMargin: 4
      verticalCenter: parent.verticalCenter
    }
    Text {
      id: clock

      anchors.centerIn: parent
      color: "#c4cce8"
      text: Owo.owo(Time.time)

      font {
        family: "monospace"
        pointSize: 10
      }
    }
  }
}

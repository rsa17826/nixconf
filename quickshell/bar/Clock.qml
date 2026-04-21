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
  // anchors.fill: parent
  color: '#77000000'
  implicitHeight: clock.implicitHeight + 12
  implicitWidth: clock.implicitWidth + 12
  radius: 0

  Text {
    id: clock

    anchors.centerIn: parent
    color: '#d40105'
    // we no longer need time as an input

    // directly access the time property from the Time singleton
    text: Time.time

    font {
      // family:
      pointSize: 10
    }
  }
}

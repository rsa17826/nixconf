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
  id: ghBadge

  color: ghNotifCount > 0 ? '#d31f31' : "#888888"
  height: 10
  // Width grows/shrinks based on number of digits
  implicitWidth: Math.max(height, ghNotifCountTextItem.implicitWidth + 8)
  radius: 20

  anchors {
    right: parent.right
    rightMargin: 10
    verticalCenter: parent.verticalCenter
  }

  // Text showing number of notifications
  Text {
    id: ghNotifCountTextItem

    anchors.centerIn: parent
    color: "white"
    font.bold: true
    font.pixelSize: 8
    text: ghNotifCount > 0 ? ghNotifCount : ""
  }
  Timer {
    interval: 60000   // 60 seconds
    repeat: true
    running: true

    onTriggered: {
      updateGhNotifCount.running = true
    }
  }
  Process {
    id: updateGhNotifCount

    command: ["sudo", "-n", "githubNotifications"]

    stdout: StdioCollector {
      onStreamFinished: _ => {
        ghNotifData = text
        ghNotifCount = JSON.parse(text).length
      }
    }

    Component.onCompleted: running = true
  }
}

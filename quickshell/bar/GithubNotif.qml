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

  property string newestAge: ""

  function timeSince(dateString) {
    const lastUpdate = new Date(dateString)
    const now = new Date()
    const seconds = Math.floor((now - lastUpdate) / 1000)

    let interval = Math.floor(seconds / 86400)
    if (interval >= 1)
      return interval + "d ago"

    interval = Math.floor(seconds / 3600)
    if (interval >= 1)
      return interval + "h ago"

    interval = Math.floor(seconds / 60)
    if (interval >= 1)
      return interval + "m ago"

    return "just now"
  }

  color: ghNotifCount > 0 ? '#d31f31' : "#888888"
  height: 10
  // Width grows/shrinks based on number of digits
  implicitWidth: Math.max(height, ghNotifCountTextItem.implicitWidth + 8)
  radius: 20

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      const data = JSON.parse(ghNotifData)
      if (data.length > 0) {
        const newest = data.reduce((a, b) => new Date(a.updated_at) > new Date(b.updated_at) ? a : b);

        // Create the request
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
          if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
              const json = JSON.parse(xhr.responseText)
              if (json.html_url) {
                // 1. Open Browser
                Qt.openUrlExternally(json.html_url);

                // 2. Mark as read via your bash script
                ghReadNotif.command = ["githubNotifications", "read", newest.thread_url]
                ghReadNotif.running = true;

                // 3. UI Cleanup
                ghNotifCount = 0
                newestAge = ""
              }
            } else {
              console.error("Failed to fetch GitHub metadata. Status:", xhr.status)
            }
          }
        }

        xhr.open("GET", newest.url)
        xhr.send()
      }
    }
  }

  // Add a small timer to reset the command after the "read" process starts
  Timer {
    id: resetTimer

    interval: 5000

    onTriggered: updateGhNotifCount.running = true
  }
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
    text: ghNotifCount > 0 ? (`[${ghNotifCount}] ${newestAge}`) : ""
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

    command: ["githubNotifications"]

    stdout: StdioCollector {
      onStreamFinished: _ => {
        const data = JSON.parse(text)
        ghNotifData = text
        ghNotifCount = data.length

        if (data.length > 0) {
          // Sort to find the most recent update
          const dates = data.map(n => new Date(n.updated_at))
          const newestDate = new Date(Math.max(...dates));

          // Set your human-readable age string
          newestAge = timeSince(newestDate)
        }
      }
    }

    Component.onCompleted: running = true
  }
  Process {
    id: ghReadNotif

    stdout: StdioCollector {
      onStreamFinished: resetTimer.start()
    }
  }
}

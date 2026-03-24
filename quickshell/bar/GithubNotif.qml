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
        // 1. Find the newest notification
        const newest = data.reduce((a, b) => new Date(a.updated_at) > new Date(b.updated_at) ? a : b)
        newestAge = "Loading..."
        // 2. Fetch the real browser URL directly in JS
        fetch(newest.url).then(response => response.json()).then(json => {
          if (json.html_url) {
            // Open the correct browser link (e.g., the tag link for releases)
            Qt.openUrlExternally(json.html_url);

            // 3. Mark as read via your bash script
            updateGhNotifCount.command = ["githubNotifications", "read", newest.thread_url]
            updateGhNotifCount.running = true;

            // 4. Clean up UI
            ghNotifCount = 0
            newestAge = ""
            resetTimer.start()
          }
        }).catch(err => console.error("Failed to fetch GitHub metadata:", err))
      }
    }
  }

  // Add a small timer to reset the command after the "read" process starts
  Timer {
    id: resetTimer

    interval: 1000

    onTriggered: updateGhNotifCount.command = ["githubNotifications"]
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
}

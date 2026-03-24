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

    onClicked: {
      const data = JSON.parse(ghNotifData)
      if (data.length > 0) {
        const newest = data.reduce((a, b) => new Date(a.updated_at) > new Date(b.updated_at) ? a : b)

        let link = ""
        if (newest.type === "Release") {
          // For releases, go to the repo's release page to avoid 404s
          link = newest.repo_url + "/releases"
        } else {
          // For Issues/PRs, the string replacement works perfectly
          link = newest.thread_url.replace("api.github.com/notifications/threads", "github.com");
          // Note: Using thread_url -> github.com usually redirects correctly
        }

        Qt.openUrlExternally(link);

        // Mark as read logic
        updateGhNotifCount.command = ["githubNotifications", "read", newest.thread_url]
        updateGhNotifCount.running = true
        ghNotifCount = 0
        resetTimer.start()
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

import Quickshell
import Quickshell.Io
import QtQuick

Rectangle {
  id: clipRoot

  property var clipboardItems: []

  // 2. Function to "re-copy" an item to the clipboard
  function selectItem(id) {
    // We create a one-shot process to decode the ID back to wl-copy
    const proc = Quickshell.createChild(Process, {
      command: ["sh", "-c", `cliphist decode ${id} | wl-copy`],
      running: true
    })
  }

  Text {
    id: clipboardDisplay

    color: "#6a72a0"
    elide: Text.ElideRight
    font.pixelSize: 11
    text: clipboardLogic.clipboardItems.length > 0 ? clipboardLogic.clipboardItems[0].preview : "Empty"
    width: 400

    anchors {
      left: parent.left
      leftMargin: 10
      verticalCenter: parent.verticalCenter
    }
  }

  // 1. The main process to list history
  Process {
    id: getList

    command: ["cliphist", "list"]
    running: true // Starts immediately

    // Connect a collector to the stdout channel
    stdout: StdioCollector {
      onStreamFinished: {
        let lines = text.split("\n")
        let temp = []
        for (let line of lines) {
          if (line.trim() === "")
            continue

          // Split "ID [tab] Content"
          let parts = line.split(/\s+/)
          let id = parts[0]
          let content = line.substring(id.length).trim()

          temp.push({
            "id": id,
            "preview": content
          })
        }
        clipRoot.clipboardItems = temp.slice(0, 10)
      }
    }
  }

  // Refresh every 5 seconds to keep the list current
  Timer {
    interval: 5000
    repeat: true
    running: true

    onTriggered: getList.running = true
  }
}

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris

Rectangle {
  id: root

  readonly property string apiKey: "AJVfciLh4WWSAMGPobaPp7ns4MXEk3Ys"
  property bool error: false
  property string statusText: "?"
  property int syncthingRemainingData: 0
  readonly property string url: "http://127.0.0.1:8384"

  function formatRemainingBytes(bytes) {
    // syncthing uses 1000 bytes not 1024
    if (bytes === 0)
      return "0 MB"
    if (bytes < 1000 * 1000)
      return "< 1 MB"
    if (bytes < 1000 * 1000 * 1000) {
      return (bytes / 1000 / 1000).toFixed(1) + " MB"
    }
    return (bytes / 1000 / 1000 / 1000).toFixed(2) + " GB"
  }
  function getSyncthingStatus() {
    var xhr = new XMLHttpRequest()
    xhr.open("GET", url + "/rest/db/completion", true)
    xhr.setRequestHeader("X-API-Key", apiKey)
    xhr.setRequestHeader("Accept", "application/json")

    xhr.onreadystatechange = function () {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status === 200) {
          try {
            var data = JSON.parse(xhr.responseText)
            var percent = data.completion || 0
            var needBytes = data.needBytes || 0

            syncthingRemainingData = needBytes

            var remainingStr = formatRemainingBytes(needBytes)

            if (percent === "100.0" || needBytes === 0) {
              statusText = ""
            } else {
              statusText = remainingStr + " left"
            }
            error = false
            return
          } catch (e) {
            statusText = "Error parsing JSON"
            error = true
            console.log("Error parsing JSON: " + e)
            return
          }
        } else {
          console.log("HTTP error! status: " + xhr.status)
          statusText = "🔄 Offline"
          error = true
          return
        }
        error = true
        statusText = "No case set to handle this"
        return
      }
    }
    xhr.send()
  }

  color: error ? "#ff9100" : syncthingRemainingData === 0 ? '#1fafd3' : '#11a42c'
  height: 11
  implicitWidth: Math.max(height, label.implicitWidth + 8)
  radius: 20

  anchors {
    right: parent.right
    rightMargin: 10
    verticalCenter: parent.verticalCenter
  }
  Text {
    id: label

    anchors.centerIn: parent
    color: '#ffffff'
    font.pixelSize: 11
    text: statusText
  }
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor

    onClicked: Qt.openUrlExternally(url)
  }
  Timer {
    id: refreshTimer

    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true

    onTriggered: getSyncthingStatus()
  }
}

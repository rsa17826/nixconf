import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: root

  property string activeMode: ""
  property bool downloading: false
  property real progressValue: 0
  property string statusText: downloading ? "Downloading..." : "Media Link Detected"
  readonly property string targetUrl: Quickshell.env("TARGET_URL") ?? ""

  function handleOutput(data) {
    const lines = data.toString().split("\n")
    for (let line of lines) {
      // Debugging log so you can see the raw output in your console
      console.log("DEBUG qml: " + line)
      if (parseFloat(line))
        progressValue = parseFloat(line)
    }
  }
  function startDownload(mode) {
    if (!targetUrl) {
      statusText = "No URL found!"
      return
    }
    activeMode = mode
    downloading = true
    dlProcess.running = true
  }

  color: "transparent"
  implicitHeight: downloading ? 100 : 150
  implicitWidth: 400

  anchors {
    left: true
    top: true
  }
  margins {
    left: 20
    top: 20
  }
  Rectangle {
    anchors.fill: parent
    border.color: "#333"
    border.width: 1
    color: "#1e1e1e"
    radius: 12

    Column {
      anchors.fill: parent
      anchors.margins: 15
      spacing: 12

      Text {
        color: "#3498db"
        font.bold: true
        font.pixelSize: 16
        text: statusText
      }
      Text {
        color: "#888"
        elide: Text.ElideMiddle
        font.pixelSize: 12
        text: targetUrl
        visible: !downloading
        width: parent.width - 30
      }
      Row {
        spacing: 12
        visible: !downloading

        Rectangle {
          color: "#333"
          height: 35
          radius: 6
          width: 90

          Text {
            anchors.centerIn: parent
            color: "white"
            text: "Video"
          }
          MouseArea {
            anchors.fill: parent

            onClicked: startDownload("Video")
          }
        }
        Rectangle {
          color: "#333"
          height: 35
          radius: 6
          width: 90

          Text {
            anchors.centerIn: parent
            color: "white"
            text: "Audio"
          }
          MouseArea {
            anchors.fill: parent

            onClicked: startDownload("Audio")
          }
        }
        Rectangle {
          color: "#422"
          height: 35
          radius: 6
          width: 90

          Text {
            anchors.centerIn: parent
            color: "white"
            text: "Abort"
          }
          MouseArea {
            anchors.fill: parent

            onClicked: Qt.quit()
          }
        }
      }
      Column {
        spacing: 8
        visible: downloading
        width: parent.width

        Rectangle {
          color: "#2a2a2a"
          height: 10
          radius: 5
          width: parent.width

          Rectangle {
            color: "#3498db"
            height: parent.height
            radius: 5
            width: Math.min(parent.width * (progressValue / 100), parent.width)

            // Behavior on width {
            //   NumberAnimation {
            //     duration: 250
            //   }
            // }
          }
        }
        Text {
          anchors.right: parent.right
          color: "white"
          font.pixelSize: 12
          text: Math.floor(progressValue) + "%"
        }
      }
    }
  }
  Process {
    id: dlProcess

    command: ["bash", "-c", "download_logic \"" + root.activeMode + "\" \"" + root.targetUrl + "\""]

    stderr: StdioCollector {
      onStreamFinished: console.log(`linea read: ${this.text}`)
    }
    stdout: SplitParser {
      onRead: function (data) {
        console.log('asdasdasdasd', data)
        handleOutput(data)
      }
    }

    onExited: {
      // console.log(dlProcess.exitCode)
      statusText = "Finished!"
      progressValue = 100
      exitTimer.start()
    }
  }
  Connections {
    function onRead(data) {
      console.log('asdasda5445sdasd', this.text, data)
      handleOutput(data)
    }

    ignoreUnknownSignals: true
    target: dlProcess.stdout
  }
  Timer {
    id: exitTimer

    interval: 2000

    onTriggered: Qt.quit()
  }
}

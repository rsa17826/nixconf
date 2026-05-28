// Wifi.qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

Item {
  id: root

  property bool connected: false
  property var networks: []     // [{ssid, signal, security, active}]
  property bool scanning: false
  property int signal: 0        // 0-100

  // ── Public state ──────────────────────────────────────────────
  property string ssid: ""

  function signalColor(pct) {
    if (!connected || pct <= 0)
      return "#888888"
    if (pct >= 60)
      return "#88c0d0"
    if (pct >= 30)
      return "#ebcb8b"
    return "#d08770"
  }

  // Map signal strength (0-100) → one of 4 block characters
  function signalIcon(pct) {
    if (!connected || pct <= 0)
      return "󰤭"
    if (pct >= 75)
      return "󰤨"
    if (pct >= 50)
      return "󰤥"
    if (pct >= 25)
      return "󰤢"
    return "󰤟"
  }

  implicitHeight: pill.implicitHeight
  implicitWidth: pill.implicitWidth

  // ── Status pill ───────────────────────────────────────────────
  Rectangle {
    id: pill

    color: "transparent"
    implicitHeight: 20
    implicitWidth: iconText.implicitWidth + ssidText.implicitWidth + 8

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor

      onClicked: {
        if (!networkPopup.visible) {
          scanNetworks.running = true
          networkPopup.visible = true
        } else {
          networkPopup.visible = false
        }
      }
    }

    // WiFi icon (Nerd Font glyph)
    Text {
      id: iconText

      color: signalColor(root.signal)
      font.pixelSize: 12
      text: signalIcon(root.signal)

      anchors {
        left: parent.left
        verticalCenter: parent.verticalCenter
      }
    }

    // SSID label
    Text {
      id: ssidText

      color: root.connected ? "#d8dee9" : "#888888"
      font.pixelSize: 10
      text: root.connected ? root.ssid : "no wifi"

      anchors {
        left: iconText.right
        leftMargin: 4
        verticalCenter: parent.verticalCenter
      }
    }
  }

  // ── Network list Window ───────────────────────────────────────
  // Replaced Popup with PanelWindow so it doesn't get clipped by your bar's boundaries
  PanelWindow {
    id: networkPopup

    color: "transparent"
    height: menuColumn.implicitHeight + 12 // Content height + padding
    visible: false
    width: 240

    anchors {
      right: true
      top: true
    }
    margins {
      right: 3
      top: 0
    }
    Rectangle {
      anchors.fill: parent
      border.color: "#3b4252"
      border.width: 1
      color: "#2e3440"
      radius: 6
    }
    Column {
      id: menuColumn

      spacing: 2

      anchors {
        fill: parent
        margins: 6
      }

      // Header row
      Row {
        spacing: 6
        width: parent.width

        Text {
          color: "#81a1c1"
          font.bold: true
          font.pixelSize: 9
          text: "WiFi"
          width: parent.width - rescanButton.width - 6
        }
        Text {
          id: rescanButton

          color: root.scanning ? "#888888" : "#81a1c1"
          font.pixelSize: 9
          text: root.scanning ? "scanning…" : "↻ rescan"

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: !root.scanning

            onClicked: scanNetworks.running = true
          }
        }
      }

      // Thin divider
      Rectangle {
        color: "#3b4252"
        height: 1
        width: parent.width
      }

      // Network entries
      Repeater {
        model: root.networks

        delegate: Rectangle {
          id: delegateRow

          property bool hovered: false
          property bool isActive: modelData.active === "yes" // nmcli terse returns "yes"/"no"

          color: hovered ? "#3b4252" : "transparent"
          height: 24
          radius: 4
          width: parent.width

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: {
              if (!isActive) {
                connectProcess.command = ["nmcli", "dev", "wifi", "connect", modelData.ssid]
                connectProcess.running = true
                networkPopup.visible = false
              }
            }
            onEntered: parent.hovered = true
            onExited: parent.hovered = false
          }

          // Active indicator dot
          Rectangle {
            id: activeDot

            color: isActive ? "#a3be8c" : "transparent"
            height: 5
            radius: 3
            width: 5

            anchors {
              left: parent.left
              leftMargin: 4
              verticalCenter: parent.verticalCenter
            }
          }

          // Signal strength badge (Declared near top / clean tracking)
          Text {
            id: signalBadge

            color: signalColor(modelData.signal)
            font.pixelSize: 11
            text: signalIcon(modelData.signal)

            anchors {
              right: parent.right
              rightMargin: 6
              verticalCenter: parent.verticalCenter
            }
          }

          // Lock icon for secured networks
          Text {
            id: lockIcon

            color: "#888888"
            font.pixelSize: 8
            text: (modelData.security !== "--" && modelData.security !== "") ? "󰌾" : ""

            anchors {
              right: signalBadge.left
              rightMargin: 4
              verticalCenter: parent.verticalCenter
            }
          }

          // SSID (Uses explicit anchor bounds instead of broken sibling math)
          Text {
            color: isActive ? "#a3be8c" : "#d8dee9"
            elide: Text.ElideRight
            font.pixelSize: 10
            text: modelData.ssid

            anchors {
              left: activeDot.right
              leftMargin: 6
              right: lockIcon.left
              rightMargin: 6
              verticalCenter: parent.verticalCenter
            }
          }
        }
      }

      // Empty state
      Text {
        color: "#888888"
        font.pixelSize: 9
        horizontalAlignment: Text.AlignHCenter
        text: "no networks found"
        visible: root.networks.length === 0 && !root.scanning
        width: parent.width
      }
    }
  }

  // ── Processes ─────────────────────────────────────────────────

  // Poll active connection status every 15 s
  Process {
    id: statusProcess

    command: ["bash", "-c", "nmcli -t -f active,ssid,signal dev wifi | grep '^yes' | head -1"]

    stdout: StdioCollector {
      onStreamFinished: {
        const line = text.trim()
        if (line === "") {
          root.connected = false
          root.ssid = ""
          root.signal = 0
          return
        }
        const parts = line.split(":")
        root.connected = parts[0] === "yes"
        root.ssid = parts[1] ?? ""
        root.signal = parseInt(parts[2]) || 0
      }
    }

    Component.onCompleted: running = true
  }
  Timer {
    interval: 15000
    repeat: true
    running: true

    onTriggered: statusProcess.running = true
  }
  Process {
    id: scanNetworks

    command: ["bash", "-c", "nmcli -t -f active,ssid,signal,security dev wifi list --rescan no 2>/dev/null | sort -t: -k3 -rn | awk -F: '!seen[$2]++'"]

    stdout: StdioCollector {
      onStreamFinished: {
        root.scanning = false
        const lines = text.trim().split("\n").filter(l => l.length > 0)
        const parsed = lines.map(line => {
          let sanitized = line.replace("\\:", '___COLON___')
          let parts = sanitized.split(':')
          parts = parts.map(function (item) {
            return item.replace(/___COLON___/g, ':')
          })
          return {
            active: parts[0] ?? "",
            ssid: (parts[1] ?? "").replace(/\\:/g, ":"),
            signal: parseInt(parts[2]) || 0,
            security: parts[3] ?? ""
          }
        }).filter(n => n.ssid !== "" && n.ssid !== "--")
        root.networks = parsed
      }
    }

    onRunningChanged: {
      if (running)
        root.scanning = true
    }
  }

  // Connect to a selected network
  Process {
    id: connectProcess

    stdout: StdioCollector {
      onStreamFinished: {
        refreshTimer.start()
      }
    }
  }
  Timer {
    id: refreshTimer

    interval: 2000
    repeat: false

    onTriggered: statusProcess.running = true
  }
}

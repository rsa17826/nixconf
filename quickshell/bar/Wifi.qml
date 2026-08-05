import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "owoify.js" as Owo

Item {
  id: root

  property var c: {
    "bg": "#0d0d1e"   // void surface
    ,
    "border": "#1e1e40"   // void border
    ,
    "divider": "#1e1e40"   // matching divider
    ,
    "hovered": "#12122c"   // void raised
    ,
    "scanning": "#30324a"   // ghost — muted while scanning
    ,
    "rescan": "#4d6fff"   // accent blue
    ,
    "wifiSelectLogo": "#4d6fff"   // accent blue

    ,
    "activeWifi": "#4d6fff"   // signal blue for active connection
    ,
    "inactiveWifi": "#6a72a0"   // fg1 — muted slate
    ,
    "lockColor": "#30324a"   // ghost
    ,
    "noNetworksFoundText": "#30324a"   // ghost
    ,
    "disconnected": "#30324a"   // ghost

    ,
    "goodCon": '#539268'             // Soft blue/indigo for good connection
    ,
    "okCon": '#689260'             // Soft blue/indigo for good connection
    ,
    "mehCon": '#8e8c57'              // Soft pastel yellow for okay connection
    ,
    "badCon": '#896c54'               // Soft pastel red/pink for bad connection
    ,
    "worstCon": '#80314e'            // deep violet — nearly dead
  }
  //
  property bool connected: false
  property var networks: []     // [{ssid, signal, security, active}]
  property bool scanning: false
  property int signal: 0        // 0-100

  // ── Public state ──────────────────────────────────────────────
  property string ssid: ""

  function parseNets(text) {
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
    return parsed
  }
  function signalColor(pct, useConnected) {
    // console.log(pct, useConnected)
    if ((useConnected && !connected) || pct <= 0)
      return c.disconnected
    if (pct >= 80)
      return c.goodCon
    if (pct >= 60)
      return c.okCon
    if (pct >= 40)
      return c.mehCon
    if (pct >= 20)
      return c.badCon
    return c.worstCon
  }

  // Map signal strength (0-100) → one of 4 block characters
  function signalIcon(pct, useConnected) {
    if ((useConnected && !connected) || pct <= 0)
      return "󰤭"
    if (pct >= 80)
      return "󰤨"
    if (pct >= 60)
      return "󰤥"
    if (pct >= 40)
      return "󰤢"
    if (pct >= 20)
      return "󰤟"
    return "󰤯"
  }

  implicitHeight: pill.implicitHeight
  implicitWidth: pill.width

  // ── Status pill ───────────────────────────────────────────────
  Rectangle {
    id: pill

    color: "transparent"
    implicitHeight: 20
    implicitWidth: iconText.width + ssidText.width + 8

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor

      onClicked: {
        if (!networkPopup.visible) {
          scanNetworks.running = true
          scanNetworksNoCache.running = true
          networkPopup.visible = true
        } else {
          networkPopup.visible = false
        }
      }
    }
    GlitchEffect {
      id: wifiGlitch

      aberration: 0.0025
      active: root.scanning
      glitchAmount: 0.02
      glitchRate: 1.4

      anchors {
        leftMargin: 4
        verticalCenter: parent.verticalCenter
      }
      Row {
        spacing: 4

        anchors {
          leftMargin: 4
          verticalCenter: parent.verticalCenter
        }

        // WiFi icon (Nerd Font glyph)
        Text {
          id: iconText

          color: signalColor(root.signal, true)
          font.pixelSize: 12
          text: Owo.owo(root.signal + " " + signalIcon(root.signal, true))

          // anchors {
          //   left: pill.left
          //   verticalCenter: pill.verticalCenter
          // }
        }

        // SSID label
        Text {
          id: ssidText

          color: root.connected ? "#c4cce8" : "#30324a"
          font.pixelSize: 10
          text: Owo.owo(root.connected ? root.ssid : "no wifi")

          // anchors {
          //   left: iconText.right
          //   leftMargin: 4
          //   verticalCenter: pill.verticalCenter
          // }
        }
      }
    }
  }

  // ── Network list Window ───────────────────────────────────────
  // Click-away dismiss layer — fullscreen transparent panel behind the popup
  PanelWindow {
    id: wifiDismiss

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    screen: Quickshell.screens.find(s => s.name === "test_bottom")
    visible: networkPopup.visible

    anchors {
      bottom: true
      left: true
      right: true
      top: true
    }
    MouseArea {
      anchors.fill: parent

      onClicked: networkPopup.visible = false
    }
  }
  PanelWindow {
    id: networkPopup

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitHeight: menuColumn.implicitHeight + 12
    implicitWidth: 240
    screen: Quickshell.screens.find(s => s.name === "test_bottom")
    visible: false

    margins {
      // TODO
      right: 60
      top: 4
    }
    anchors {
      right: true
      top: true
    }
    Rectangle {
      anchors.fill: parent
      border.color: c.border
      border.width: 1
      color: c.bg
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
          color: c.wifiSelectLogo
          font.bold: true
          font.pixelSize: 9
          text: Owo.owo("WiFi")
          width: parent.width - rescanButton.width - 6
        }
        Text {
          id: rescanButton

          color: root.scanning ? c.scanning : c.rescan
          font.pixelSize: 9
          text: Owo.owo(root.scanning ? "scanning…" : "↻ rescan")

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: !root.scanning

            onClicked: scanNetworksNoCache.running = true
          }
        }
      }

      // Thin divider
      Rectangle {
        color: c.divider
        implicitHeight: 1
        implicitWidth: parent.width
      }

      // Network entries
      Repeater {
        model: root.networks

        delegate: Rectangle {
          id: delegateRow

          property bool hovered: false
          property bool isActive: modelData.active === "yes" // nmcli terse returns "yes"/"no"

          color: hovered ? c.hovered : "transparent"
          implicitHeight: 24
          implicitWidth: parent.width
          radius: 4

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

            color: isActive ? c.activeWifi : "transparent"
            implicitHeight: 5
            implicitWidth: 5
            radius: 3

            anchors {
              left: parent.left
              leftMargin: 4
              verticalCenter: parent.verticalCenter
            }
          }

          // Signal strength badge (Declared near top / clean tracking)
          Text {
            id: signalBadge

            color: signalColor(modelData.signal, false)
            font.pixelSize: 11
            text: Owo.owo(modelData.signal + " " + signalIcon(modelData.signal, false))

            anchors {
              right: parent.right
              rightMargin: 6
              verticalCenter: parent.verticalCenter
            }
          }

          // Lock icon for secured networks
          Text {
            id: lockIcon

            color: c.lockColor
            font.pixelSize: 8
            text: Owo.owo((modelData.security !== "--" && modelData.security !== "") ? "󰌾" : "")

            anchors {
              right: signalBadge.left
              rightMargin: 4
              verticalCenter: parent.verticalCenter
            }
          }

          // SSID (Uses explicit anchor bounds instead of broken sibling math)
          Text {
            color: isActive ? c.activeWifi : c.inactiveWifi
            elide: Text.ElideRight
            font.pixelSize: 10
            text: Owo.owo(modelData.ssid)

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
        color: c.noNetworksFoundText
        font.pixelSize: 9
        horizontalAlignment: Text.AlignHCenter
        text: Owo.owo("no networks found")
        visible: root.networks.length === 0 && !root.scanning
        width: parent.width
      }
    }
  }

  // ── Processes ─────────────────────────────────────────────────

  // Poll active connection status every 15 s
  Process {
    id: statusProcess

    // Two-step: trigger rescan and wait (discard output), then read fresh cache.
    // --rescan yes corrupts the active flag mid-scan; --rescan no after it is correct.
    command: ["bash", "-c", "nmcli dev wifi list --rescan yes >/dev/null 2>&1; nmcli -t -f active,ssid,signal,security dev wifi list --rescan no 2>/dev/null | sort -t: -k1,1r -k3,3rn | awk -F: '!seen[$2]++'"]

    stdout: StdioCollector {
      onStreamFinished: {
        const nets = parseNets(text)
        const activeNet = nets.find(n => n.active === "yes")
        if (activeNet) {
          root.connected = true
          root.ssid = activeNet.ssid
          root.signal = activeNet.signal
        } else {
          root.connected = false
          root.ssid = ""
          root.signal = 0
        }
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
    id: scanNetworksNoCache

    command: ["bash", "-c", "nmcli dev wifi list --rescan yes >/dev/null 2>&1; nmcli -t -f active,ssid,signal,security dev wifi list --rescan no 2>/dev/null | sort -t: -k1,1r -k3,3rn | awk -F: '!seen[$2]++'"]

    stdout: StdioCollector {
      onStreamFinished: {
        root.scanning = false
        const activeNet = parseNets(text).find(n => n.active === "yes")
        if (activeNet) {
          root.connected = true
          root.ssid = activeNet.ssid
          root.signal = activeNet.signal
        }
      }
    }

    onRunningChanged: {
      if (running)
        root.scanning = true
    }
  }
  Process {
    id: scanNetworks

    command: ["bash", "-c", "nmcli -t -f active,ssid,signal,security dev wifi list --rescan no 2>/dev/null | sort -t: -k1,1r -k3,3rn | awk -F: '!seen[$2]++'"]

    stdout: StdioCollector {
      onStreamFinished: {
        const nets = parseNets(text)
        const activeNet = nets.find(n => n.active === "yes")
        if (activeNet) {
          root.connected = true
          root.ssid = activeNet.ssid
          root.signal = activeNet.signal
        }
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

    Component.onCompleted: {
      statusProcess.running = true
    }
  }
  Timer {
    id: refreshTimer

    interval: 2000
    repeat: false

    onTriggered: statusProcess.running = true
  }
}

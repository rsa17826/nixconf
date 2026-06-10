import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  // Panel width — animates open/closed
  readonly property int panelW: 400

  WlrLayershell.anchors: WlrAnchors.Top | WlrAnchors.Right | WlrAnchors.Bottom
  WlrLayershell.exclusiveZone: -1
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-notif-center"
  color: "transparent"
  implicitWidth: NotifState.centerOpen ? panelW : 0

  // Only show on the primary (first) screen
  screen: Quickshell.screens[0]

  // clip: true

  Rectangle {
    id: panel

    border.color: "#1e1e40"
    border.width: 1
    color: "#03030a"
    width: root.panelW

    // Slide in from the right
    transform: Translate {
      x: NotifState.centerOpen ? 0 : root.panelW
    }

    anchors {
      bottom: parent.bottom
      right: parent.right
      top: parent.top
      topMargin: 28        // clear the bar
    }
    ColumnLayout {
      anchors.fill: parent
      spacing: 0

      // ── Header ──────────────────────────────────────────────
      Rectangle {
        Layout.fillWidth: true
        border.color: "#1e1e40"
        border.width: 0
        color: "#08081a"
        height: 40

        // bottom divider only
        Rectangle {
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          color: "#1e1e40"
          height: 1
        }
        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 10
          spacing: 8

          Text {
            color: "#6a72a0"
            font.family: "monospace"
            font.pointSize: 10
            text: "notifications"
          }
          Text {
            Layout.fillWidth: true
            color: "#30324a"
            font.family: "monospace"
            font.pointSize: 9
            text: NotifState.historyCount > 0 ? NotifState.historyCount + " stored" : "quiet"
          }

          // Clear all button
          Rectangle {
            border.color: "#1e1e40"
            border.width: 1
            color: clearMa.containsMouse ? "#12122c" : "transparent"
            height: 22
            implicitWidth: clearLbl.implicitWidth + 14
            radius: 3
            visible: NotifState.historyCount > 0

            Text {
              id: clearLbl

              anchors.centerIn: parent
              color: clearMa.containsMouse ? "#6a72a0" : "#30324a"
              font.family: "monospace"
              font.pointSize: 9
              text: "clear all"
            }
            MouseArea {
              id: clearMa

              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true

              onClicked: NotifState.clearHistory()
            }
          }

          // Close panel button
          Rectangle {
            border.color: "#1e1e40"
            border.width: 1
            color: xMa.containsMouse ? "#12122c" : "transparent"
            height: 22
            radius: 3
            width: 22

            Text {
              anchors.centerIn: parent
              color: xMa.containsMouse ? "#c4cce8" : "#30324a"
              font.pointSize: 9
              text: "✕"
            }
            MouseArea {
              id: xMa

              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true

              onClicked: NotifState.centerOpen = false
            }
          }
        }
      }

      // ── Notification list ────────────────────────────────────
      ScrollView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        clip: true

        Column {
          padding: 10
          spacing: 6
          width: root.panelW

          Repeater {
            model: NotifState.historyNotifs

            delegate: NotifToast {
              required property var modelData

              dimmed: true
              entry: modelData
              width: root.panelW - 20
            }
          }

          // Empty state
          Item {
            height: emptyCol.implicitHeight + 48
            visible: NotifState.historyCount === 0
            width: root.panelW - 20

            Column {
              id: emptyCol

              anchors.centerIn: parent
              spacing: 8

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#30324a"
                font.family: "monospace"
                font.pointSize: 10
                text: "the void is quiet"
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#1e1e40"
                font.family: "monospace"
                font.pointSize: 9
                text: "no notifications stored"
              }
            }
          }
        }
      }
    }
  }
}

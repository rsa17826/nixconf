import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

Item {
  id: root

  implicitWidth:  bellRow.implicitWidth + 14
  implicitHeight: bellRow.implicitHeight + 8

  // ── Bell pill ────────────────────────────────────────────────
  Row {
    id: bellRow
    anchors.centerIn: parent
    spacing: 5

    Text {
      id: bellIcon
      anchors.verticalCenter: parent.verticalCenter
      text: NotifState.historyCount > 0 ? "󰂚" : "󰂜"
      color: NotifState.centerOpen       ? "#c4cce8"
           : NotifState.activeCount  > 0 ? "#4d6fff"
           : NotifState.historyCount > 0 ? "#6a72a0"
           :                               "#30324a"
      font.family: "monospace"
      font.pointSize: 11

      Behavior on color { ColorAnimation { duration: 150 } }
    }

    // Badge — history count
    Rectangle {
      visible: NotifState.historyCount > 0
      anchors.verticalCenter: parent.verticalCenter
      height: 13
      width: Math.max(13, badgeText.implicitWidth + 6)
      radius: 6
      color: NotifState.centerOpen ? "#12122c" : "#0d0d1e"
      border.color: NotifState.centerOpen ? "#4d6fff" : "#2a3a8a"
      border.width: 1

      Text {
        id: badgeText
        anchors.centerIn: parent
        text: NotifState.historyCount > 99 ? "99+" : NotifState.historyCount
        color: "#4d6fff"
        font.family: "monospace"
        font.pointSize: 7
        font.bold: true
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: NotifState.toggleCenter()
  }

  // ── Active notification popups ───────────────────────────────
  // Appears automatically whenever there are live notifications.
  // grabFocus: false so it never steals keyboard input.
  PopupWindow {
    id: toastPopup

    visible: NotifState.activeCount > 0
    grabFocus: false
    color: "transparent"
    implicitWidth: 396   // 380 toast + 16 right padding
    implicitHeight: Math.max(1, toastCol.implicitHeight + 8)

    anchor {
      item:    root
      edges:   Edges.Bottom | Edges.Right
      gravity: Edges.Bottom | Edges.Left
      margins { top: 8 }
    }

    Column {
      id: toastCol
      anchors.top:   parent.top
      anchors.right: parent.right
      anchors.topMargin:   4
      anchors.rightMargin: 16
      spacing: 8
      width: 380

      Repeater {
        model: NotifState.activeNotifs

        delegate: NotifToast {
          required property var modelData
          entry: modelData
          width: 380
        }
      }
    }
  }

  // ── Notification center (history) ────────────────────────────
  // Shown on bell click; grabFocus so clicking outside auto-closes it.
  PopupWindow {
    id: centerPopup

    visible: NotifState.centerOpen
    grabFocus: true
    color: "transparent"
    implicitWidth:  400
    implicitHeight: 520

    // Sync grabFocus auto-close back into NotifState
    onVisibleChanged: if (!visible) NotifState.centerOpen = false

    anchor {
      item:    root
      edges:   Edges.Bottom | Edges.Right
      gravity: Edges.Bottom | Edges.Left
      margins { top: 8 }
    }

    Rectangle {
      anchors.fill: parent
      color: "#03030a"
      border.color: "#1e1e40"
      border.width: 1
      radius: 6
      clip: true

      ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
          Layout.fillWidth: true
          height: 40
          color: "#08081a"
          radius: 6

          // Cover bottom radius
          Rectangle {
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            height: 6
            color: "#08081a"
          }

          // Bottom divider
          Rectangle {
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            height: 1
            color: "#1e1e40"
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin:  14
            anchors.rightMargin: 10
            spacing: 8

            Text {
              text: "notifications"
              color: "#6a72a0"
              font.family: "monospace"
              font.pointSize: 10
            }

            Text {
              text: NotifState.historyCount > 0
                    ? NotifState.historyCount + " stored"
                    : "quiet"
              color: "#30324a"
              font.family: "monospace"
              font.pointSize: 9
              Layout.fillWidth: true
            }

            // Clear all
            Rectangle {
              visible: NotifState.historyCount > 0
              height: 22
              implicitWidth: clearLbl.implicitWidth + 14
              color: clearMa.containsMouse ? "#12122c" : "transparent"
              border.color: "#1e1e40"
              border.width: 1
              radius: 3

              Text {
                id: clearLbl
                anchors.centerIn: parent
                text: "clear all"
                color: clearMa.containsMouse ? "#6a72a0" : "#30324a"
                font.family: "monospace"
                font.pointSize: 9
              }

              MouseArea {
                id: clearMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotifState.clearHistory()
              }
            }

            // Close
            Rectangle {
              width: 22; height: 22
              color: closeCenterMa.containsMouse ? "#12122c" : "transparent"
              border.color: "#1e1e40"
              border.width: 1
              radius: 3

              Text {
                anchors.centerIn: parent
                text: "✕"
                color: closeCenterMa.containsMouse ? "#c4cce8" : "#30324a"
                font.pointSize: 9
              }

              MouseArea {
                id: closeCenterMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotifState.centerOpen = false
              }
            }
          }
        }

        // Scrollable history list
        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
          ScrollBar.vertical.policy:   ScrollBar.AsNeeded

          Column {
            width: 400
            spacing: 6
            padding: 10

            Repeater {
              model: NotifState.historyNotifs

              delegate: NotifToast {
                required property var modelData
                entry:  modelData
                width:  380
              }
            }

            // Empty state
            Item {
              visible: NotifState.historyCount === 0
              width: 380
              height: emptyCol.implicitHeight + 48

              Column {
                id: emptyCol
                anchors.centerIn: parent
                spacing: 8

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "the void is quiet"
                  color: "#30324a"
                  font.family: "monospace"
                  font.pointSize: 10
                }

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "no notifications stored"
                  color: "#1e1e40"
                  font.family: "monospace"
                  font.pointSize: 9
                }
              }
            }
          }
        }
      }
    }
  }
}

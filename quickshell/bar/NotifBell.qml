import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "owoify.js" as Owo

Item {
  id: root

  implicitHeight: bellRow.implicitHeight + 8
  implicitWidth: bellRow.implicitWidth + 14

  // ── Bell pill ────────────────────────────────────────────────
  Row {
    id: bellRow

    anchors.centerIn: parent
    spacing: 5

    Text {
      id: bellIcon

      anchors.verticalCenter: parent.verticalCenter
      color: NotifState.centerOpen ? "#c4cce8" : NotifState.activeCount > 0 ? "#4d6fff" : NotifState.storedCount > 0 ? "#6a72a0" : "#30324a"
      font.family: "monospace"
      font.pointSize: 11
      text: NotifState.storedCount > 0 ? "󰂚" : "󰂜"

      Behavior on color {
        ColorAnimation {
          duration: 150
        }
      }
    }

    // Badge — history count
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      border.color: NotifState.centerOpen ? "#4d6fff" : "#2a3a8a"
      border.width: 1
      color: NotifState.centerOpen ? "#12122c" : "#0d0d1e"
      height: 13
      radius: 6
      visible: NotifState.storedCount > 0
      width: Math.max(13, badgeText.implicitWidth + 6)

      Text {
        id: badgeText

        anchors.centerIn: parent
        color: "#4d6fff"
        font.bold: true
        font.family: "monospace"
        font.pointSize: 7
        text: NotifState.storedCount > 99 ? "99+" : NotifState.storedCount
      }
    }
  }
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true

    onClicked: NotifState.toggleCenter()
  }

  // ── Active notification popups ───────────────────────────────
  // Appears automatically whenever there are live notifications.
  // grabFocus: false so it never steals keyboard input.
  PopupWindow {
    id: toastPopup

    color: "transparent"
    grabFocus: false
    implicitHeight: Math.max(1, toastCol.implicitHeight + 8)
    implicitWidth: 396   // 380 toast + 16 right padding
    visible: NotifState.activeCount > 0

    anchor {
      edges: Edges.Bottom | Edges.Right
      gravity: Edges.Bottom | Edges.Left
      item: root

      margins {
        top: 8
      }
    }
    Column {
      id: toastCol

      anchors.right: parent.right
      anchors.rightMargin: 16
      anchors.top: parent.top
      anchors.topMargin: 4
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

    color: "transparent"
    grabFocus: true
    implicitHeight: 520
    implicitWidth: 400
    visible: NotifState.centerOpen

    // Sync grabFocus auto-close back into NotifState
    onVisibleChanged: if (!visible)
      NotifState.centerOpen = false

    anchor {
      edges: Edges.Bottom | Edges.Right
      gravity: Edges.Bottom | Edges.Left
      item: root

      margins {
        top: 8
      }
    }
    Rectangle {
      anchors.fill: parent
      border.color: "#1e1e40"
      border.width: 1
      clip: true
      color: "#03030a"
      radius: 6

      ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
          Layout.fillWidth: true
          color: "#08081a"
          height: 40
          radius: 6

          // Cover bottom radius
          Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            color: "#08081a"
            height: 6
          }

          // Bottom divider
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
              text: Owo.owo("notifications")
            }
            Text {
              Layout.fillWidth: true
              color: "#30324a"
              font.family: "monospace"
              font.pointSize: 9
              text: Owo.owo(NotifState.storedCount > 0 ? NotifState.storedCount + " stored" : "quiet")
            }

            // Clear all
            Rectangle {
              border.color: "#1e1e40"
              border.width: 1
              color: clearMa.containsMouse ? "#12122c" : "transparent"
              height: 22
              implicitWidth: clearLbl.implicitWidth + 14
              radius: 3
              visible: NotifState.storedCount > 0

              Text {
                id: clearLbl

                anchors.centerIn: parent
                color: clearMa.containsMouse ? "#6a72a0" : "#30324a"
                font.family: "monospace"
                font.pointSize: 9
                text: Owo.owo("clear all")
              }
              MouseArea {
                id: clearMa

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: NotifState.clearStored()
              }
            }

            // Close
            Rectangle {
              border.color: "#1e1e40"
              border.width: 1
              color: closeCenterMa.containsMouse ? "#12122c" : "transparent"
              height: 22
              radius: 3
              width: 22

              Text {
                anchors.centerIn: parent
                color: closeCenterMa.containsMouse ? "#c4cce8" : "#30324a"
                font.pointSize: 9
                text: "✕"
              }
              MouseArea {
                id: closeCenterMa

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: NotifState.centerOpen = false
              }
            }
          }
        }

        // Scrollable history list
        Item {
          Layout.fillHeight: true
          Layout.fillWidth: true
          clip: true

          Flickable {
            id: historyFlickable

            anchors.fill: parent
            anchors.rightMargin: historyFlickable.contentHeight > historyFlickable.height ? 8 : 0
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: historyCol.implicitHeight
            contentWidth: width
            flickableDirection: Flickable.VerticalFlick
            // Disable touch drag and all momentum — wheel handler takes over entirely
            interactive: false

            Column {
              id: historyCol

              padding: 10
              spacing: 6
              width: 400

              // ── Stored notifications ─────────────────────────
              Repeater {
                model: NotifState.storedNotifs

                delegate: NotifToast {
                  required property var modelData

                  entry: modelData
                  width: 380
                }
              }

              // Empty stored state
              Item {
                height: emptyStoredCol.implicitHeight + 32
                visible: NotifState.storedCount === 0
                width: 380

                Column {
                  id: emptyStoredCol

                  anchors.centerIn: parent
                  rightPadding: 400
                  spacing: 6

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#30324a"
                    font.family: "monospace"
                    font.pointSize: 10
                    text: Owo.owo("the void is quiet")
                  }
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#1e1e40"
                    font.family: "monospace"
                    font.pointSize: 9
                    text: Owo.owo("no notifications stored")
                  }
                }
              }

              // ── History divider ──────────────────────────────
              Item {
                height: historyHeaderRow.implicitHeight + 16
                visible: NotifState.history.length > 0
                width: 380

                RowLayout {
                  id: historyHeaderRow

                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 8 // RowLayout respects this, or you can use Layout.spacing

                  Rectangle {
                    // Layouts handle vertical centering automatically if specified,
                    // but keeping this alignment is safe.
                    Layout.alignment: Qt.AlignVCenter
                    color: "#1e1e40"
                    height: 1
                    width: 16
                  }
                  Text {
                    Layout.alignment: Qt.AlignVCenter
                    color: "#30324a"
                    font.family: "monospace"
                    font.pointSize: 8
                    text: Owo.owo("history")
                  }
                  Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    color: "#1e1e40"
                    height: 1
                  }

                  // Clear history button
                  Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 4
                    border.color: "#1e1e40"
                    border.width: 1
                    color: clearHistMa.containsMouse ? "#12122c" : "transparent"
                    height: 18
                    implicitWidth: clearHistLbl.implicitWidth + 10
                    radius: 3

                    Text {
                      id: clearHistLbl

                      anchors.centerIn: parent
                      color: clearHistMa.containsMouse ? "#6a72a0" : "#30324a"
                      font.family: "monospace"
                      font.pointSize: 8
                      text: Owo.owo("clear")
                    }
                    MouseArea {
                      id: clearHistMa

                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      hoverEnabled: true

                      onClicked: NotifState.clearHistory()
                    }
                  }
                }
              }

              // ── History entries (last 50, dimmed) ────────────
              Repeater {
                model: NotifState.historyFiltered

                delegate: NotifToast {
                  required property var modelData

                  entry: modelData
                  opacity: 0.55
                  width: 380
                }
              }
            }
          }

          // Instant step scroll — no momentum, no smooth animation
          WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            acceptedModifiers: Qt.NoModifier
            target: null

            onWheel: event => {
              const step = (event.angleDelta.y / 120) * 150
              const maxY = Math.max(0, historyFlickable.contentHeight - historyFlickable.height)
              historyFlickable.contentY = Math.max(0, Math.min(historyFlickable.contentY - step, maxY))
            }
          }

          // Explicit scrollbar — AlwaysOn so it doesn't fade on hover
          ScrollBar {
            id: vBar

            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.top: parent.top
            minimumSize: 0.05
            orientation: Qt.Vertical
            // AlwaysOn prevents the default hover-fade; gate visibility manually instead
            policy: ScrollBar.AlwaysOn

            // Bind position to Flickable
            position: historyFlickable.contentY / Math.max(1, historyFlickable.contentHeight)
            size: historyFlickable.height / Math.max(1, historyFlickable.contentHeight)
            visible: historyFlickable.contentHeight > historyFlickable.height

            // Allow dragging the scrollbar to scroll
            onPositionChanged: {
              if (pressed) {
                const maxY = Math.max(0, historyFlickable.contentHeight - historyFlickable.height)
                historyFlickable.contentY = Math.max(0, Math.min(position * historyFlickable.contentHeight, maxY))
              }
            }
          }
        }
      }
    }
  }
}

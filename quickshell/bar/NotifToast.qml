import QtQuick
import QtQuick.Layouts

Rectangle {
  id: root

  required property var entry

  border.color: entry.urgency === 2 ? "#9933cc" : "#1e1e40"
  border.width: 1
  clip: true
  color: entry.urgency === 0 ? "#03030a" : entry.urgency === 1 ? "#0d0d1e" : '#1f0d25'
  implicitHeight: contentRow.implicitHeight + 24

  // ── Appear animation ─────────────────────────────────────────
  opacity: 0
  radius: 6

  Component.onCompleted: opacity = 1

  // ── 20s countdown bar (only on live popups) ─────────────────
  Rectangle {
    id: timerTrack

    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    color: "#08081a"
    height: 2
    visible: !root.entry.expired

    Rectangle {
      id: timerFill

      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.top: parent.top
      color: root.entry.urgency === 2 ? "#9933cc" : root.entry.urgency === 1 ? "#4d6fff" : "#30324a"
      radius: 1
      width: timerTrack.width

      NumberAnimation on width {
        duration: 20000
        from: root.width
        running: !root.entry.expired
        to: 0
      }
    }
  }

  // ── Content ──────────────────────────────────────────────────
  RowLayout {
    id: contentRow

    spacing: 10

    anchors {
      left: parent.left
      margins: 12
      right: parent.right
      rightMargin: 8
      top: parent.top
    }

    // App icon
    Rectangle {
      color: root.entry.urgency === 2 ? "#1a0a2e" : root.entry.urgency === 0 ? "#0a0a18" : "#0d1030"
      height: 28
      radius: 4
      visible: root.entry.appIcon !== ""
      width: 28

      Image {
        anchors.fill: parent
        anchors.margins: 4
        fillMode: Image.PreserveAspectFit
        smooth: true
        source: root.entry.appIcon !== "" ? ("image://icon/" + root.entry.appIcon) : ""
      }
    }

    // Text block
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4

      // App name (subtle, above summary)
      Text {
        Layout.fillWidth: true
        // color: root.dimmed ? "#30324a" : "#6a72a0"
        color: "#30324a"
        elide: Text.ElideRight
        font.family: "monospace"
        font.pointSize: 8
        text: root.entry.appName
        visible: root.entry.appName !== ""
      }
      Text {
        Layout.fillWidth: true
        // color: root.dimmed ? "#6a72a0" : "#c4cce8"
        color: "#6a72a0"
        elide: Text.ElideRight
        font.family: "monospace"
        font.pointSize: 10
        text: root.entry.summary
        visible: root.entry.summary !== ""
      }
      Text {
        Layout.fillWidth: true
        // color: root.dimmed ? "#30324a" : "#6a72a0"
        color: "#30324a"
        elide: Text.ElideRight
        font.family: "monospace"
        font.pointSize: 9
        maximumLineCount: 4
        text: root.entry.body
        visible: root.entry.body !== ""
        wrapMode: Text.WordWrap
      }

      // Action buttons
      Row {
        spacing: 6
        topPadding: 2
        visible: root.entry.actions.length > 0

        Repeater {
          model: root.entry.actions

          delegate: Rectangle {
            required property var modelData

            border.color: "#2a3a8a"
            border.width: 1
            color: actionMa.containsMouse ? "#12122c" : "transparent"
            implicitHeight: actionLbl.implicitHeight + 8
            implicitWidth: actionLbl.implicitWidth + 14
            radius: 3

            Text {
              id: actionLbl

              anchors.centerIn: parent
              color: "#4d6fff"
              font.family: "monospace"
              font.pointSize: 9
              text: modelData.text
            }
            MouseArea {
              id: actionMa

              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true

              onClicked: NotifState.invokeAction(root.entry.id, modelData.id)
            }
          }
        }
      }
    }

    // Dismiss button
    Rectangle {
      Layout.alignment: Qt.AlignTop
      color: closeMa.containsMouse ? "#1e1e40" : "transparent"
      height: 20
      radius: 3
      width: 20

      Text {
        anchors.centerIn: parent
        color: closeMa.containsMouse ? "#c4cce8" : "#30324a"
        font.pointSize: 9
        text: "✕"
      }
      MouseArea {
        id: closeMa

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: NotifState.dismiss(root.entry.id)
      }
    }
  }
}

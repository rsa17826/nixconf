import Quickshell           // <── ADD THIS LINE
import QtQuick
import QtQuick.Layouts
import "owoify.js" as Owo

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

  NumberAnimation on opacity {
    duration: Math.max(0, 300 - (Date.now() - root.entry.addedAt))
    from: 0
    running: true
    to: 1
  }

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

      readonly property int remainingDuration: root.entry.remainingTime !== undefined ? root.entry.remainingTime : root.entry.stayVisibleFor

      // 1. Create helper properties to calculate the adjusted lifespan
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.top: parent.top
      color: root.entry.urgency === 2 ? "#9933cc" : root.entry.urgency === 1 ? "#4d6fff" : "#30324a"
      radius: 1

      // 2. Set the initial width based on the remaining time fraction
      width: root.width * (remainingDuration / root.entry.stayVisibleFor)

      NumberAnimation on width {
        // 3. Scale down the duration and start point dynamically
        duration: Math.max(0, root.entry.stayVisibleFor - (Date.now() - root.entry.addedAt))
        from: root.width * ((root.entry.stayVisibleFor - (Date.now() - root.entry.addedAt)) / root.entry.stayVisibleFor)
        running: !root.entry.expired && (root.entry.stayVisibleFor - (Date.now() - root.entry.addedAt)) > 0
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
    GlitchEffect {
      id: iconGlitch

      aberration: 0.0025
      glitchAmount: 0.02
      glitchRate: 1.4
      visible: appIconImg.visible

      Rectangle {
        color: root.entry.urgency === 2 ? "#1a0a2e" : root.entry.urgency === 0 ? "#0a0a18" : "#0d1030"
        height: 28
        radius: 4
        visible: root.entry.appIcon !== "" && appIconImg.status === Image.Ready
        width: 28

        Image {
          id: appIconImg

          anchors.fill: parent
          anchors.margins: 4
          fillMode: Image.PreserveAspectFit
          smooth: true
          source: {
            const icon = root.entry.appIcon
            if (icon === "")
              return ""
            if (icon.startsWith("/") || icon.startsWith("file://"))
              return icon
            return Quickshell.iconPath(icon, true)
          }
          sourceSize.height: 64
          sourceSize.width: 64
        }
      }
    }

    // Text block
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4

      GlitchEffect {
        id: textGlitch

        aberration: 0.0025
        glitchAmount: 0.02
        glitchRate: 1.4

        // App name (subtle, above summary)
        Text {
          Layout.fillWidth: true
          // color: root.dimmed ? "#30324a" : "#6a72a0"
          color: "#30324a"
          elide: Text.ElideRight
          font.family: "monospace"
          font.pointSize: 8
          text: Owo.owo(root.entry.appName)
          visible: root.entry.appName !== ""
        }
      }
      GlitchEffect {
        id: text2Glitch

        aberration: 0.0025
        glitchAmount: 0.02
        glitchRate: 1.4

        Text {
          Layout.fillWidth: true
          // color: root.dimmed ? "#6a72a0" : "#c4cce8"
          color: "#6a72a0"
          elide: Text.ElideRight
          font.family: "monospace"
          font.pointSize: 10
          text: Owo.owo(root.entry.summary)
          visible: root.entry.summary !== ""
        }
      }
      GlitchEffect {
        id: text3Glitch

        aberration: 0.0025
        glitchAmount: 0.02
        glitchRate: 1.4

        Text {
          Layout.fillWidth: true
          // color: root.dimmed ? "#30324a" : "#6a72a0"
          color: "#30324a"
          elide: Text.ElideRight
          font.family: "monospace"
          font.pointSize: 9
          maximumLineCount: 4
          text: Owo.owo(root.entry.body)
          visible: root.entry.body !== ""
          wrapMode: Text.WordWrap
        }
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

            border.color: "#00000000"
            border.width: 1
            color: "#00000000"
            implicitHeight: actionLbl.implicitHeight + 8
            implicitWidth: actionLbl.implicitWidth + 14

            // Only the label is glitched — GlitchEffect renders its
            // content offscreen (visible: false) and shows a separate
            // shaded copy, so a MouseArea nested inside it never gets
            // hit-tested. Keep interactive items (this Rectangle,
            // MouseArea) outside any GlitchEffect.
            GlitchEffect {
              id: actionGlitch

              aberration: 0.0025
              anchors.centerIn: parent
              glitchAmount: 0.02
              glitchRate: 1.4

              Rectangle {
                anchors.centerIn: parent
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
                  text: Owo.owo(modelData.text)
                }
              }
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

      GlitchEffect {
        id: closeGlitch

        aberration: 0.0025
        glitchAmount: 0.02
        glitchRate: 1.4

        Text {
          anchors.centerIn: parent
          color: closeMa.containsMouse ? "#c4cce8" : "#30324a"
          font.pointSize: 9
          text: "✕"
        }
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

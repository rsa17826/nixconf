import Quickshell           // <── ADD THIS LINE
import QtQuick
import QtQuick.Layouts
import "owoify.js" as Owo

Rectangle {
  id: root

  required property var entry

  anchors.topMargin: 250
  border.width: 0
  clip: true
  color: "transparent"
  implicitHeight: contentRow.implicitHeight + 34
  // layer.enabled: true

  // ── Appear animation ─────────────────────────────────────────
  opacity: 0
  radius: 0

  // layer.effect: ShaderEffect {
  //   property real amplitude: 10
  //   property real edgeWidth: 30
  //   property vector2d resolution: Qt.vector2d(root.width, root.height)
  //   property real speed: 8
  //   property real spikeWidth: 10
  //   property real time: barContent.time

  //   fragmentShader: "shaders/barspike.frag.qsb"
  //   vertexShader: "shaders/barspike.vert.qsb"
  // }
  NumberAnimation on opacity {
    duration: Math.max(0, 300 - (Date.now() - root.entry.addedAt))
    from: 0
    running: true
    to: 1
  }

  SysFrame {
    accent: root.entry.urgency === 2 ? "#ff6666" : root.entry.urgency === 0 ? "#2c8aa6" : "#40d9ff"
    anchors.fill: parent
  }
  MouseArea {
    acceptedButtons: Qt.RightButton
    anchors.fill: parent

    onClicked: NotifState.dismiss(root.entry.id)
  }

  // ── 20s countdown bar (only on live popups) ─────────────────
  Rectangle {
    id: timerTrack

    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    color: "#061020"
    height: 2
    visible: !root.entry.expired

    Rectangle {
      id: timerFill

      readonly property int remainingDuration: root.entry.remainingTime !== undefined ? root.entry.remainingTime : root.entry.stayVisibleFor

      // 1. Create helper properties to calculate the adjusted lifespan
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.top: parent.top
      color: root.entry.urgency === 2 ? "#9933cc" : root.entry.urgency === 1 ? "#40d9ff" : "#3a6280"
      radius: 0

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
      leftMargin: 18
      margins: 12
      right: parent.right
      rightMargin: 8
      top: parent.top
      topMargin: 16
    }

    // App icon
    GlitchEffect {
      id: iconGlitch

      aberration: 0.0025
      glitchAmount: 0.02
      glitchRate: 1.4
      visible: root.entry.appIcon !== "" && appIconImg.status === Image.Ready

      Rectangle {
        color: root.entry.urgency === 2 ? "#1a0a2e" : root.entry.urgency === 0 ? "#050e1c" : "#0a1d36"
        height: 28
        radius: 0
        width: 28

        Image {
          id: appIconImg

          anchors.fill: parent
          anchors.margins: 4
          fillMode: Image.PreserveAspectFit
          smooth: true
          source: {
            console.log(root.entry.appIcon, "root.entry.appIcon")
            const icon = root.entry.appIcon
            if (icon === "")
              return ""
            if (icon.startsWith("file://"))
              return icon
            if (icon.startsWith("/"))
              return "file://" + icon
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

        Layout.fillWidth: true
        aberration: 0.0015
        glitchAmount: 0.02
        glitchRate: 1.4

        // App name (subtle, above summary)
        Text {
          // color: root.dimmed ? "#3a6280" : "#73b3d9"
          color: "#3a6280"
          elide: Text.ElideRight
          font.family: "monospace"
          font.pointSize: 8
          text: Owo.owo("◈ " + root.entry.appName)
          visible: root.entry.appName !== ""
          width: textGlitch.width
        }
      }
      GlitchEffect {
        id: textGlitchHeader

        Layout.fillWidth: true
        aberration: 0.0035
        glitchAmount: 0.04
        glitchRate: 1.4

        Text {
          // color: root.dimmed ? "#73b3d9" : "#d9f7ff"
          color: "#73b3d9"
          elide: Text.ElideRight
          font.family: "monospace"
          font.pointSize: 10
          text: Owo.owo(root.entry.summary)
          visible: root.entry.summary !== ""
          width: textGlitchHeader.width
        }
      }
      GlitchEffect {
        id: textGlitchBody

        Layout.fillWidth: true
        aberration: 0.0015
        glitchAmount: 0.01
        glitchRate: 1.4

        Text {
          color: "#3a6280"
          elide: Text.ElideRight
          font.family: "monospace"
          font.pointSize: 9
          maximumLineCount: 4
          text: Owo.owo(root.entry.body)
          visible: root.entry.body !== ""
          width: textGlitchBody.width
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
            readonly property real btnH: actionLbl.implicitHeight + 8
            required property var modelData
            readonly property real shearPad: Math.ceil(0.06 * btnH) + 1

            border.color: "#00000000"
            border.width: 1
            color: "#00000000"
            implicitHeight: btnH
            implicitWidth: actionLbl.implicitWidth + 14

            GlitchEffect {
              id: actionGlitch

              aberration: 0.02
              anchors.centerIn: parent
              glitchAmount: 0.1
              glitchRate: 1.8

              // Padded wrapper: gives the sheared corners room inside the texture
              Item {
                implicitHeight: btnH
                implicitWidth: actionLbl.implicitWidth + 14 + shearPad * 2

                Rectangle {
                  anchors.centerIn: parent
                  border.color: "#2f8fd0"
                  border.width: 1
                  color: actionMa.containsMouse ? "#0c2340" : "transparent"
                  implicitHeight: btnH
                  implicitWidth: actionLbl.implicitWidth + 14
                  radius: 0

                  // x' = x - 0.12*(y - h/2): shear pivoted on the vertical center
                  transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(1, -0.12, 0, 0.06 * btnH, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                  }

                  Text {
                    id: actionLbl

                    anchors.centerIn: parent
                    color: "#40d9ff"
                    font.family: "monospace"
                    font.pointSize: 9
                    text: Owo.owo(modelData.text)
                  }
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
    // Rectangle {
    //   Layout.alignment: Qt.AlignTop
    //   color: closeMa.containsMouse ? "#15486f" : "transparent"
    //   transform: SysShear {}
    //   border.color: closeMa.containsMouse ? "#f2d9faff" : "#b373e0ff"
    //   border.width: 1
    //   height: 20
    //   radius: 0
    //   width: 20

    //   GlitchEffect {
    //     id: closeGlitch

    //     aberration: 0.0025
    //     glitchAmount: 0.02
    //     glitchRate: 1.4

    //     Text {
    //       anchors.centerIn: parent
    //       color: closeMa.containsMouse ? "#d9f7ff" : "#3a6280"
    //       font.pointSize: 9
    //       text: "✕"
    //     }
    //   }
    //   MouseArea {
    //     id: closeMa

    //     anchors.fill: parent
    //     cursorShape: Qt.PointingHandCursor
    //     hoverEnabled: true

    //     onClicked: NotifState.dismiss(root.entry.id)
    //   }
    // }
  }
}

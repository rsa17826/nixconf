import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import Quickshell.Io

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "owoify.js" as Owo

Rectangle {
  id: root

  // The CountdownTimerRow instance — wired up from shell.qml so the
  // calendar popup can create/inspect timers.
  property var timerRow: null

  color: "transparent"
  implicitHeight: clock.implicitHeight + 12
  implicitWidth: clock.implicitWidth + 12

  GlitchEffect {
    id: clockGlitch

    aberration: 0.00825
    glitchAmount: 0.25
    glitchRate: 2.2

    anchors {
      leftMargin: 4
      verticalCenter: parent.verticalCenter
    }
    Text {
      id: clock

      anchors.centerIn: parent
      color: "#c4cce8"
      text: Owo.owo(Time.time)

      font {
        family: "monospace"
        pointSize: 10
      }
    }
  }
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor

    onClicked: calendarPopup.visible = !calendarPopup.visible
  }

  // ── Click-away dismiss layer ─────────────────────────────────────
  PanelWindow {
    id: calendarDismiss

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    screen: Quickshell.screens.find(s => s.name === "test_bottom")
    visible: calendarPopup.visible

    anchors {
      bottom: true
      left: true
      right: true
      top: true
    }
    MouseArea {
      anchors.fill: parent

      onClicked: calendarPopup.visible = false
    }
  }

  // ── Calendar popup ────────────────────────────────────────────────
  PanelWindow {
    id: calendarPopup

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitHeight: calendarColumn.implicitHeight + 16
    implicitWidth: 280
    screen: Quickshell.screens.find(s => s.name === "test_bottom")
    visible: false

    margins {
      // Roughly centers the popup under the clock. Same fixed-offset
      // approach used by the other bar popups (Wifi/CountdownTimer).
      left: Math.max(0, (calendarPopup.screen.width - calendarPopup.implicitWidth) / 2)
      top: 4
    }
    anchors {
      left: true
      top: true
    }
    Rectangle {
      anchors.fill: parent
      border.color: "#1e1e40"
      border.width: 1
      color: "#03030a"
      radius: 6
    }
    Column {
      id: calendarColumn

      spacing: 0

      anchors {
        fill: parent
        margins: 8
      }
      TimerCalendar {
        id: calendarWidget

        timerRow: root.timerRow

        onTimerSet: name => {
        // Keep the popup open so multiple timers can be set in a row;
        // close it explicitly by clicking away or the clock again.
        }
      }
    }
  }
}

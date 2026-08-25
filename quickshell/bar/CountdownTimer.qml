// CountdownTimer.qml
// Click to set a target date/time. Counts down until it, turning orange on
// the day of the event and shading from orange -> red in the final 3 hours.
//
// This component is now "dumb": it owns no file/persistence, just draft
// editing + display for a single (timerId, targetTimestamp) pair. The
// parent (CountdownTimerRow) owns the list and writes it to disk.
import Quickshell
import Quickshell.Io
import QtQuick
import "owoify.js" as Owo

Item {
  id: root

  property var c: {
    "bg": "#0d0d1e",
    "border": "#1e1e40",
    "divider": "#1e1e40",
    "hovered": "#12122c",
    "muted": "#30324a",
    "text": "#c4cce8",
    "normal": "#4d6fff"   // more than a day away
    ,
    "orange": "#e8974d"   // same calendar day, > 3h left
    ,
    "red": "#e84d4d"      // 0h left
    ,
    "expired": "#ff3b3b",
    "accent": "#4d6fff",
    "buttonBg": "#1e1e40"
  }

  // ── Draft state used while editing in the popup ─────────────────
  property var draft: ({
      y: 2026,
      mo: 1,
      d: 1,
      h: 0,
      mi: 0,
      url: ""
    })
  // "none" (or unset) / "single" -> one-shot, shows the progress bar.
  // "weekly" / "monthly" / "yearly" -> repeating, no progress bar.
  property string repeatType: "none"
  property real startTimestamp: 0
  property real targetTimestamp: 0

  // ── Identity + external state (owned by the parent list) ─────────
  property var timerId: 0
  property string timerName: ""
  property string url: ""

  signal cleared(var id)

  // Emitted instead of writing files directly. Parent listens and
  // updates/persists its canonical list.
  signal committed(var id, real ts, string url, real startTs)

  function adjustDraft(field, delta, step) {
    const dr = Object.assign({}, root.draft)
    const s = step || 1
    if (field === "y") {
      dr.y += delta
    } else if (field === "mo") {
      let m = dr.mo - 1 + delta
      let y = dr.y
      while (m < 0) {
        m += 12
        y -= 1
      }
      while (m > 11) {
        m -= 12
        y += 1
      }
      dr.mo = m + 1
      dr.y = y
    } else if (field === "d") {
      const maxD = daysInMonth(dr.y, dr.mo)
      let d = dr.d + delta
      if (d < 1)
        d = maxD
      if (d > maxD)
        d = 1
      dr.d = d
    } else if (field === "h") {
      let h = (dr.h + delta) % 24
      if (h < 0)
        h += 24
      dr.h = h
    } else if (field === "mi") {
      // snap to the nearest step multiple first, so a draft loaded from an
      // arbitrary time (e.g. "now" = :47) always lands on 0/5/10/... after
      // the first click, instead of drifting to 52/57/2/...
      const snapped = Math.round(dr.mi / s) * s
      let mi = (snapped + delta * s) % 60
      if (mi < 0)
        mi += 60
      dr.mi = mi
    }
    // keep day in range if month/year changed elsewhere
    const maxD = daysInMonth(dr.y, dr.mo)
    if (dr.d > maxD)
      dr.d = maxD
    root.draft = dr
  }
  function clearTimer() {
    root.targetTimestamp = 0
    root.startTimestamp = 0
    root.url = ""
    root.cleared(root.timerId)
    picker.visible = false
  }
  function commitDraft() {
    const dr = root.draft
    const ts = new Date(dr.y, dr.mo - 1, dr.d, dr.h, dr.mi, 0).getTime();
    // Only stamp a fresh "start" when this timer didn't already have a
    // target set — editing an existing timer keeps its original start so
    // the progress bar doesn't jump back to 100%.
    if (root.targetTimestamp <= 0)
      root.startTimestamp = Date.now()
    root.targetTimestamp = ts
    root.url = dr.url || ""
    root.committed(root.timerId, ts, root.url, root.startTimestamp)
    picker.visible = false
  }

  // ── Helpers ──────────────────────────────────────────────────────
  function daysInMonth(y, mo) {
    return new Date(y, mo, 0).getDate()
  }
  function formatCountdown() {
    if (root.targetTimestamp <= 0)
      return "set timer"
    const left = msLeft()
    if (left <= 0)
      return "expired"
    const totalSeconds = Math.floor(left / 1000)
    const days = Math.floor(totalSeconds / 86400)
    const hours = Math.floor(totalSeconds / 3600) % 24
    const mins = Math.floor(totalSeconds / 60) % 60
    const secs = totalSeconds % 60
    if (days > 0)
      return `${days}d ${hours}h ${mins}m`
    if (hours > 0)
      return `${hours}h ${mins}m ${secs}s`
    return `${mins}m ${secs}s`
  }
  function isSameDay() {
    if (root.targetTimestamp <= 0)
      return false
    const t = new Date(root.targetTimestamp)
    const n = clock.date
    return t.getFullYear() === n.getFullYear() && t.getMonth() === n.getMonth() && t.getDate() === n.getDate()
  }
  function lerpColor(a, b, t) {
    const tt = Math.max(0, Math.min(1, t))
    const pa = parseInt(a.slice(1), 16)
    const pb = parseInt(b.slice(1), 16)
    const ar = (pa >> 16) & 255, ag = (pa >> 8) & 255, ab = pa & 255
    const br = (pb >> 16) & 255, bg = (pb >> 8) & 255, bb = pb & 255
    const rr = Math.round(ar + (br - ar) * tt)
    const rg = Math.round(ag + (bg - ag) * tt)
    const rb = Math.round(ab + (bb - ab) * tt)
    return "#" + ((1 << 24) + (rr << 16) + (rg << 8) + rb).toString(16).slice(1)
  }

  // ── Countdown math ───────────────────────────────────────────────
  function msLeft() {
    return root.targetTimestamp - clock.date.getTime()
  }

  // Load the draft either from the currently-set timer, or default to
  // "one hour from now", whenever the popup is opened.
  function openPicker() {
    const base = root.targetTimestamp > 0 ? new Date(root.targetTimestamp) : new Date(clock.date.getTime() + 3600000)
    root.draft = {
      y: base.getFullYear(),
      mo: base.getMonth() + 1,
      d: base.getDate(),
      h: base.getHours(),
      mi: Math.round(base.getMinutes() / 5) * 5 % 60,
      url: root.url || ""
    }
    picker.visible = true
  }
  function pad(n) {
    return n < 10 ? "0" + n : "" + n
  }
  function timerColor() {
    if (root.targetTimestamp <= 0)
      return c.muted
    const left = msLeft()
    if (left <= 0)
      return blink.on ? c.expired : c.red
    const hoursLeft = left / 3600000
    if (!isSameDay())
      return c.normal
    if (hoursLeft > 3)
      return c.orange
    return lerpColor(c.orange, c.red, 1 - hoursLeft / 3)
  }

  implicitHeight: pill.implicitHeight + (progressTrack.visible ? progressTrack.height + 2 : 0)
  implicitWidth: pill.implicitWidth

  // ── Ticking clock (drives re-evaluation every second) ────────────
  SystemClock {
    id: clock

    precision: SystemClock.Seconds
  }
  // Blink toggle used only while expired
  Timer {
    id: blinkTimer

    interval: 600
    repeat: true
    running: root.targetTimestamp > 0 && root.msLeft() <= 0

    onTriggered: blink.on = !blink.on
  }
  QtObject {
    id: blink

    property bool on: true
  }

  // ── Status pill ────────────────────────────────────────────────
  Rectangle {
    id: pill

    color: "transparent"
    implicitHeight: 14
    implicitWidth: label.implicitWidth + 4 + (root.url ? linkBtn.implicitWidth + 4 : 0)

    anchors {
      topMargin: 20
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor

      onClicked: picker.visible ? (picker.visible = false) : root.openPicker()
    }
    GlitchEffect {
      id: timerGlitch

      aberration: 0.0084 / (isSameDay() ? 1 : 3)
      // active: isSameDay()
      glitchAmount: 0.111 / (isSameDay() ? 1 : 3)
      // TODO rerange root.targetTimestamp 1h 0 ~1.5 ~2.3
      glitchRate: isSameDay() ? 2 : 1.7

      Text {
        id: label

        color: root.timerColor()
        font.pixelSize: 11
        text: Owo.owo("⏰ " + (root.timerName ? root.timerName + ": " : "") + root.formatCountdown())

        anchors {
          left: parent.left
          verticalCenter: parent.verticalCenter
        }
      }
    }

    // Link button — only shown once a url is attached to this timer.
    // Kept outside GlitchEffect so its MouseArea stays hit-testable
    // (see NotifToast's action buttons for the same rule).
    Rectangle {
      id: linkBtn

      color: linkMa.containsMouse ? c.hovered : "transparent"
      implicitHeight: 16
      implicitWidth: linkLbl.implicitWidth + 6
      radius: 3
      visible: root.url !== ""

      anchors {
        left: timerGlitch.right
        leftMargin: 6
        verticalCenter: parent.verticalCenter
      }
      Text {
        id: linkLbl

        anchors.centerIn: parent
        color: c.accent
        font.pixelSize: 10
        text: "🔗"
      }
      MouseArea {
        id: linkMa

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: Qt.openUrlExternally(root.url)
      }
    }
  }

  // ── Progress bar (non-repeating timers only) ──────────────────────
  // Runs from 100% width at startTimestamp down to 0% width at
  // targetTimestamp. Repeating timers (weekly/monthly/yearly) don't have
  // a stable "start" that makes sense to bar-ify, so they're excluded.
  Rectangle {
    id: progressTrack

    color: "#08081a"
    height: 2
    radius: 1
    visible: root.targetTimestamp > 0 && root.startTimestamp > 0 && (!root.repeatType || root.repeatType === "none" || root.repeatType === "single")
    width: pill.width

    anchors {
      left: pill.left
      top: pill.bottom
      topMargin: 2
    }
    Rectangle {
      id: progressFill

      readonly property real fraction: Math.max(0, Math.min(1, (root.targetTimestamp - clock.date.getTime()) / span))
      readonly property real span: Math.max(1, root.targetTimestamp - root.startTimestamp)

      color: root.timerColor()
      height: parent.height
      radius: parent.radius
      width: parent.width * fraction

      anchors {
        left: parent.left
        top: parent.top
      }
    }
  }

  // ── Click-away dismiss layer ──────────────────────────────────────
  PanelWindow {
    id: pickerDismiss

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    screen: Quickshell.screens.find(s => s.name === "test_bottom")
    visible: picker.visible

    anchors {
      bottom: true
      left: true
      right: true
      top: true
    }
    MouseArea {
      anchors.fill: parent

      onClicked: picker.visible = false
    }
  }

  // ── Date/time picker popup ────────────────────────────────────────
  PanelWindow {
    id: picker

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitHeight: pickerColumn.implicitHeight + 12
    implicitWidth: 210
    screen: Quickshell.screens.find(s => s.name === "test_bottom")
    visible: false

    margins {
      left: 60
      top: 4
    }
    anchors {
      left: true
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
      id: pickerColumn

      spacing: 6

      anchors {
        fill: parent
        margins: 8
      }
      GlitchEffect {
        id: settimerGlitch

        aberration: 0.0120
        glitchAmount: 0.07
        glitchRate: 1.4

        Text {
          color: c.accent
          font.bold: true
          font.pixelSize: 9
          text: Owo.owo("Set Countdown")
        }
      }
      Rectangle {
        color: c.divider
        implicitHeight: 1
        implicitWidth: parent.width
      }
      Repeater {
        model: [
          {
            key: "y",
            label: "Year",
            step: 1
          },
          {
            key: "mo",
            label: "Month",
            step: 1
          },
          {
            key: "d",
            label: "Day",
            step: 1
          },
          {
            key: "h",
            label: "Hour",
            step: 1
          },
          {
            key: "mi",
            label: "Min",
            step: 5
          }
        ]

        delegate: Row {
          spacing: 6
          width: pickerColumn.width

          GlitchEffect {
            id: labelGlitch

            aberration: 0.0120
            anchors.verticalCenter: parent.verticalCenter
            glitchAmount: 0.07
            glitchRate: 1.4

            Text {
              color: c.text
              font.pixelSize: 10
              text: Owo.owo(modelData.label)
              width: 38
            }
          }
          Rectangle {
            id: minusBtn

            color: minusArea.containsMouse ? c.hovered : c.buttonBg
            implicitHeight: 18
            implicitWidth: 18
            radius: 4

            // Only the glyph is glitched — MouseArea must stay outside
            // any GlitchEffect (see NotifToast's action buttons for why:
            // GlitchEffect's real content is visible:false and never
            // gets hit-tested).
            GlitchEffect {
              id: minusGlitch

              aberration: 0.0120
              anchors.centerIn: parent
              glitchAmount: 0.07
              glitchRate: 1.4

              Text {
                color: c.text
                font.pixelSize: 10
                text: "-"
              }
            }
            MouseArea {
              id: minusArea

              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true

              onClicked: root.adjustDraft(modelData.key, -1, modelData.step)
            }
          }
          GlitchEffect {
            id: valueGlitch

            aberration: 0.0120
            anchors.verticalCenter: parent.verticalCenter
            glitchAmount: 0.07
            glitchRate: 1.4

            Text {
              color: c.text
              font.pixelSize: 10
              horizontalAlignment: Text.AlignHCenter
              text: {
                const v = root.draft[modelData.key]
                return modelData.key === "mo" || modelData.key === "d" || modelData.key === "h" || modelData.key === "mi" ? root.pad(v) : "" + v
              }
              width: 32
            }
          }
          Rectangle {
            id: plusBtn

            color: plusArea.containsMouse ? c.hovered : c.buttonBg
            implicitHeight: 18
            implicitWidth: 18
            radius: 4

            GlitchEffect {
              id: plusGlitch

              aberration: 0.0120
              anchors.centerIn: parent
              glitchAmount: 0.07
              glitchRate: 1.4

              Text {
                color: c.text
                font.pixelSize: 10
                text: "+"
              }
            }
            MouseArea {
              id: plusArea

              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true

              onClicked: root.adjustDraft(modelData.key, 1, modelData.step)
            }
          }
        }
      }
      Rectangle {
        color: c.divider
        implicitHeight: 1
        implicitWidth: parent.width
      }
      Row {
        spacing: 6
        width: pickerColumn.width

        Text {
          anchors.verticalCenter: parent.verticalCenter
          color: c.text
          font.pixelSize: 10
          text: Owo.owo("URL")
          width: 38
        }
        Rectangle {
          id: urlBox

          anchors.verticalCenter: parent.verticalCenter
          border.color: urlInput.activeFocus ? c.accent : c.buttonBg
          border.width: 1
          color: c.bg
          height: 20
          radius: 4
          width: pickerColumn.width - 38 - 6

          TextInput {
            id: urlInput

            clip: true
            color: c.text
            font.pixelSize: 9
            selectByMouse: true
            text: root.draft.url || ""
            verticalAlignment: TextInput.AlignVCenter

            onTextChanged: root.draft = Object.assign({}, root.draft, {
              url: text
            })

            anchors {
              fill: parent
              leftMargin: 5
              rightMargin: 5
              verticalCenter: parent.verticalCenter
            }
          }
        }
      }
      Rectangle {
        color: c.divider
        implicitHeight: 1
        implicitWidth: parent.width
      }
      Row {
        id: buttonRow

        spacing: 8
        width: parent.width

        Rectangle {
          id: setBtn

          color: setArea.containsMouse ? c.hovered : c.buttonBg
          implicitHeight: 22
          implicitWidth: (buttonRow.width - 8) / 2
          radius: 4

          GlitchEffect {
            id: setGlitch

            aberration: 0.0120
            anchors.centerIn: parent
            glitchAmount: 0.07

            Text {
              color: c.accent
              font.pixelSize: 10
              text: Owo.owo("Set")
            }
          }
          MouseArea {
            id: setArea

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: root.commitDraft()
          }
        }
        Rectangle {
          id: clearBtn

          color: clearArea.containsMouse ? c.hovered : c.buttonBg
          implicitHeight: 22
          implicitWidth: (buttonRow.width - 8) / 2
          radius: 4

          GlitchEffect {
            id: clearGlitch

            aberration: 0.0120
            anchors.centerIn: parent
            glitchAmount: 0.07

            Text {
              color: c.red
              font.pixelSize: 10
              text: Owo.owo("Clear")
            }
          }
          MouseArea {
            id: clearArea

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: root.clearTimer()
          }
        }
      }
    }
  }
}

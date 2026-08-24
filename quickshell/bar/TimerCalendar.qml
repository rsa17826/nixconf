// TimerCalendar.qml
// Month grid used from Clock.qml's popup. Clicking a day opens an inline
// "set timer" panel where you pick a repeat mode:
//   Once     -> single timer for that exact date
//   Weekly   -> repeats every <weekday> (e.g. "Mondays")
//   Monthly  -> repeats every month on that day-of-month ("the 15th")
//   Yearly   -> repeats every year on that month/day ("12/26 (yearly)")
// Days that already have a timer attached (via timerRow.hasTimerOnDate)
// get a highlighted background and a stronger glitch effect than plain
// days, so they stand out at a glance.
import QtQuick
import "owoify.js" as Owo

Item {
  id: root

  property var c: {
    "bg": "#0d0d1e",
    "border": "#1e1e40",
    "divider": "#1e1e40",
    "hovered": "#12122c",
    "text": "#c4cce8",
    "muted": "#30324a",
    "accent": "#4d6fff",
    "markedBg": "#161235",
    "markedBorder": "#4d2f8a",
    "selectedBorder": "#4d6fff"
  }

  // Draft for the inline "set timer" panel
  property var draft: ({
      h: 9,
      mi: 0
    })
  property int selectedDay: -1

  // Must be set by the parent: the CountdownTimerRow instance that owns
  // addRepeatingTimer / hasTimerOnDate / daysInMonth.
  required property var timerRow
  // "y" / "mo" (1-indexed) — month currently shown
  property int viewMonth: new Date().getMonth() + 1
  property int viewYear: new Date().getFullYear()

  signal timerSet(string name)

  function commit(repeatType) {
    if (root.selectedDay <= 0)
      return
    let anchor
    if (repeatType === "single") {
      anchor = {
        y: root.viewYear,
        mo: root.viewMonth,
        d: root.selectedDay,
        h: root.draft.h,
        mi: root.draft.mi
      }
    } else if (repeatType === "weekly") {
      anchor = {
        weekday: new Date(root.viewYear, root.viewMonth - 1, root.selectedDay).getDay(),
        h: root.draft.h,
        mi: root.draft.mi
      }
    } else if (repeatType === "monthly") {
      anchor = {
        d: root.selectedDay,
        h: root.draft.h,
        mi: root.draft.mi
      }
    } else if (repeatType === "yearly") {
      anchor = {
        mo: root.viewMonth,
        d: root.selectedDay,
        h: root.draft.h,
        mi: root.draft.mi
      }
    }
    const name = root.timerRow.addRepeatingTimer(repeatType, anchor)
    root.timerSet(name)
    root.selectedDay = -1
  }
  function daysInMonth(y, mo) {
    return new Date(y, mo, 0).getDate()
  }
  function firstWeekday(y, mo) {
    return new Date(y, mo - 1, 1).getDay()
  }
  function goNextMonth() {
    root.selectedDay = -1
    let mo = root.viewMonth + 1
    let y = root.viewYear
    if (mo > 12) {
      mo = 1
      y += 1
    }
    root.viewMonth = mo
    root.viewYear = y
  }
  function goPrevMonth() {
    root.selectedDay = -1
    let mo = root.viewMonth - 1
    let y = root.viewYear
    if (mo < 1) {
      mo = 12
      y -= 1
    }
    root.viewMonth = mo
    root.viewYear = y
  }
  function monthName(mo) {
    const names = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    return names[mo - 1]
  }
  function pad(n) {
    return n < 10 ? "0" + n : "" + n
  }
  function selectDay(d) {
    root.selectedDay = (root.selectedDay === d) ? -1 : d
    root.draft = {
      h: 9,
      mi: 0
    }
  }

  implicitHeight: col.implicitHeight
  implicitWidth: 260

  Column {
    id: col

    spacing: 8
    width: root.implicitWidth

    // ── Month header ──────────────────────────────────────────
    Row {
      spacing: 6
      width: parent.width

      Rectangle {
        color: prevMa.containsMouse ? c.hovered : "transparent"
        height: 20
        radius: 4
        width: 20

        Text {
          anchors.centerIn: parent
          color: c.text
          font.pixelSize: 10
          text: "‹"
        }
        MouseArea {
          id: prevMa

          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true

          onClicked: root.goPrevMonth()
        }
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        color: c.accent
        font.bold: true
        font.pixelSize: 10
        horizontalAlignment: Text.AlignHCenter
        text: Owo.owo(root.monthName(root.viewMonth) + " " + root.viewYear)
        width: parent.width - 48
      }
      Rectangle {
        color: nextMa.containsMouse ? c.hovered : "transparent"
        height: 20
        radius: 4
        width: 20

        Text {
          anchors.centerIn: parent
          color: c.text
          font.pixelSize: 10
          text: "›"
        }
        MouseArea {
          id: nextMa

          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true

          onClicked: root.goNextMonth()
        }
      }
    }
    Rectangle {
      color: c.divider
      height: 1
      width: parent.width
    }

    // ── Weekday labels ───────────────────────────────────────────
    Row {
      spacing: 0
      width: parent.width

      Repeater {
        model: ["S", "M", "T", "W", "T", "F", "S"]

        delegate: Text {
          color: c.muted
          font.pixelSize: 8
          horizontalAlignment: Text.AlignHCenter
          text: modelData
          width: col.width / 7
        }
      }
    }

    // ── Day grid ──────────────────────────────────────────────────
    Grid {
      columns: 7
      rowSpacing: 3
      width: parent.width

      Repeater {
        model: root.firstWeekday(root.viewYear, root.viewMonth)

        delegate: Item {
          height: 24
          width: col.width / 7
        }
      }
      Repeater {
        model: root.daysInMonth(root.viewYear, root.viewMonth)

        delegate: Item {
          id: dayCell

          readonly property int dayNum: index + 1
          readonly property bool hasTimer: root.timerRow.hasTimerOnDate(root.viewYear, root.viewMonth, dayNum)
          readonly property bool isSelected: root.selectedDay === dayNum
          readonly property bool isToday: {
            const n = new Date()
            return n.getFullYear() === root.viewYear && (n.getMonth() + 1) === root.viewMonth && n.getDate() === dayNum
          }

          height: 24
          width: col.width / 7

          GlitchEffect {
            id: dayGlitch

            // Days with a timer glitch noticeably harder so they pop out
            // of the grid at a glance; plain days stay very subtle.
            aberration: dayCell.hasTimer ? 0.02 : 0.0025
            anchors.centerIn: parent
            glitchAmount: dayCell.hasTimer ? 0.09 : 0.015
            glitchRate: dayCell.hasTimer ? 1.8 : 1.0

            Rectangle {
              border.color: dayCell.isSelected ? c.selectedBorder : dayCell.hasTimer ? c.markedBorder : "transparent"
              border.width: 1
              color: dayCell.isSelected ? c.hovered : dayCell.hasTimer ? c.markedBg : "transparent"
              height: 20
              radius: 4
              width: 20

              Text {
                anchors.centerIn: parent
                color: dayCell.isToday ? c.accent : dayCell.hasTimer ? c.text : c.muted
                font.bold: dayCell.isToday || dayCell.hasTimer
                font.pixelSize: 9
                text: dayCell.dayNum
              }

              // Small dot under the number when a timer is attached
              Rectangle {
                color: c.accent
                height: 3
                radius: 1.5
                visible: dayCell.hasTimer
                width: 3

                anchors {
                  bottom: parent.bottom
                  bottomMargin: 2
                  horizontalCenter: parent.horizontalCenter
                }
              }
            }
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: root.selectDay(dayCell.dayNum)
          }
        }
      }
    }

    // ── Inline "set timer" panel ────────────────────────────────
    Column {
      spacing: 6
      visible: root.selectedDay > 0
      width: parent.width

      Rectangle {
        color: c.divider
        height: 1
        width: parent.width
      }
      Text {
        color: c.text
        font.pixelSize: 9
        text: Owo.owo("Set timer for " + root.pad(root.viewMonth) + "/" + root.pad(root.selectedDay))
      }

      // Time-of-day picker (hour/minute)
      Row {
        spacing: 6

        Text {
          anchors.verticalCenter: parent.verticalCenter
          color: c.muted
          font.pixelSize: 9
          text: Owo.owo("time")
          width: 30
        }
        Rectangle {
          color: hMinusMa.containsMouse ? c.hovered : c.bg
          height: 16
          radius: 3
          width: 16

          Text {
            anchors.centerIn: parent
            color: c.text
            font.pixelSize: 9
            text: "-"
          }
          MouseArea {
            id: hMinusMa

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: root.draft = Object.assign({}, root.draft, {
              h: (root.draft.h + 23) % 24
            })
          }
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          color: c.text
          font.pixelSize: 9
          text: root.pad(root.draft.h) + ":" + root.pad(root.draft.mi)
          width: 34
        }
        Rectangle {
          color: hPlusMa.containsMouse ? c.hovered : c.bg
          height: 16
          radius: 3
          width: 16

          Text {
            anchors.centerIn: parent
            color: c.text
            font.pixelSize: 9
            text: "+"
          }
          MouseArea {
            id: hPlusMa

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: root.draft = Object.assign({}, root.draft, {
              h: (root.draft.h + 1) % 24
            })
          }
        }
        Rectangle {
          color: mMinusMa.containsMouse ? c.hovered : c.bg
          height: 16
          radius: 3
          width: 16

          Text {
            anchors.centerIn: parent
            color: c.text
            font.pixelSize: 9
            text: "-"
          }
          MouseArea {
            id: mMinusMa

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: root.draft = Object.assign({}, root.draft, {
              mi: (root.draft.mi + 55) % 60
            })
          }
        }
        Rectangle {
          color: mPlusMa.containsMouse ? c.hovered : c.bg
          height: 16
          radius: 3
          width: 16

          Text {
            anchors.centerIn: parent
            color: c.text
            font.pixelSize: 9
            text: "+"
          }
          MouseArea {
            id: mPlusMa

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: root.draft = Object.assign({}, root.draft, {
              mi: (root.draft.mi + 5) % 60
            })
          }
        }
      }

      // Repeat-mode buttons
      Grid {
        columnSpacing: 6
        columns: 2
        rowSpacing: 6
        width: parent.width

        Repeater {
          model: [
            {
              key: "single",
              label: "Once"
            },
            {
              key: "weekly",
              label: "Weekly"
            },
            {
              key: "monthly",
              label: "Monthly"
            },
            {
              key: "yearly",
              label: "Yearly"
            }
          ]

          delegate: Rectangle {
            id: modeBtn

            color: modeMa.containsMouse ? c.hovered : c.bg
            height: 22
            radius: 4
            width: (col.width - 6) / 2

            Text {
              anchors.centerIn: parent
              color: c.accent
              font.pixelSize: 9
              text: Owo.owo(modelData.label)
            }
            MouseArea {
              id: modeMa

              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true

              onClicked: root.commit(modelData.key)
            }
          }
        }
      }
    }
  }
}

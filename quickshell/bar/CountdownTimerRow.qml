// CountdownTimerRow.qml
// A row of CountdownTimer widgets. Owns the canonical list + persistence.
// Clearing a timer removes it from the row; if it's the last one
// remaining, it's reset to "unset" instead of being removed (min 1 stays).
import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  property var c: {
    "buttonBg": "#1e1e40",
    "hovered": "#12122c",
    "text": "#c4cce8",
    "border": "#1e1e40"
  }
  property int nextId: 2

  // Canonical list: [{ id, targetTimestamp }, ...]. Always start with one
  // unset slot so there's something to click even before a file exists.
  property var timers: [
    {
      id: 1,
      targetTimestamp: 0
    }
  ]

  function addTimer() {
    const t = root.timers.slice()
    t.push({
      id: root.nextId,
      targetTimestamp: 0
    })
    root.timers = t
    root.nextId += 1
    saveTimers()
  }
  function configPath() {
    const ns = "qsbar"
    const cfghome = Quickshell.env("XDG_CONFIG_HOME")
    if (cfghome)
      return pathJoin(cfghome, ns)
    const home = Quickshell.env("HOME")
    if (home)
      return pathJoin(home, ".config", ns)
    const uname = Quickshell.env("USER")
    if (uname)
      return pathJoin("/home", uname, ".config", ns)
    console.error("NO VARS SET - CAN'T FIND CONFIG LOCATION")
    return ""
  }
  function pathJoin(...p) {
    return p.map(e => e.replace(/\/$/, '')).join("/").replace(/\/$/, '')
  }
  function removeTimer(id) {
    if (root.timers.length <= 1) {
      // min 1 remaining: reset in place instead of removing
      root.timers = root.timers.map(t => t.id === id ? {
          id: t.id,
          targetTimestamp: 0
        } : t)
    } else {
      root.timers = root.timers.filter(t => t.id !== id)
    }
    saveTimers()
  }
  function saveTimers() {
    jsonAdapter.timers = root.timers
    jsonAdapter.nextId = root.nextId
    timersFile.writeAdapter()
  }
  function updateTimer(id, ts) {
    root.timers = root.timers.map(t => t.id === id ? {
        id: t.id,
        targetTimestamp: ts
      } : t)
    saveTimers()
  }

  implicitHeight: rowLayout.implicitHeight
  implicitWidth: rowLayout.implicitWidth

  // ── Persistence ───────────────────────────────────────────────────
  FileView {
    id: timersFile

    path: root.pathJoin(root.configPath(), "countdown-timers.json")
    preload: true
    printErrors: false
    watchChanges: false

    onLoadFailed: error => {
    // no file yet: keep the default single unset timer
    }

    JsonAdapter {
      id: jsonAdapter

      property int nextId: root.nextId
      property var timers: root.timers

      onNextIdChanged: root.nextId = nextId
      onTimersChanged: root.timers = timers
    }
  }
  Row {
    id: rowLayout

    spacing: 0

    Repeater {
      model: root.timers

      delegate: CountdownTimer {
        targetTimestamp: modelData.targetTimestamp
        timerId: modelData.id

        onCleared: id => root.removeTimer(id)
        onCommitted: (id, ts) => root.updateTimer(id, ts)
      }
    }
    Rectangle {
      id: addBtn

      anchors.verticalCenter: parent.verticalCenter
      color: addArea.containsMouse ? c.hovered : c.buttonBg
      implicitHeight: 20
      implicitWidth: 20
      radius: 4

      Text {
        anchors.centerIn: parent
        color: c.text
        font.bold: true
        font.pixelSize: 12
        text: "+"
      }
      MouseArea {
        id: addArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: root.addTimer()
      }
    }
  }
}

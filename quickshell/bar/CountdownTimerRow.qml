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
  // nextId / timers live on jsonAdapter (the single source of truth);
  // these are plain aliases, not bindings, so there's no cycle.
  property alias nextId: jsonAdapter.nextId
  property alias timers: jsonAdapter.timers

  function addTimer() {
    const t = root.timers.slice()
    t.push({
      id: root.nextId,
      name: "",
      targetTimestamp: 0
    })
    root.timers = t
    root.nextId += 1
    saveTimers()
  }

  // Remove a named timer entirely (or reset it in place, per removeTimer's
  // existing min-1 rule).
  function clearByName(name) {
    const existing = root.findByName(name)
    if (!existing)
      return false
    root.removeTimer(existing.id)
    return true
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
  // Guarantees there's always exactly one trailing unset ({targetTimestamp:0})
  // slot to click on. Called after loading from disk (where every saved
  // timer may already be set) and after every commit/clear.
  function ensureUnsetSlot() {
    if (root.timers.some(t => t.targetTimestamp === 0))
      return
    const t = root.timers.slice()
    t.push({
      id: root.nextId,
      name: "",
      targetTimestamp: 0
    })
    root.timers = t
    root.nextId += 1
    saveTimers()
  }

  // ── Name-based API (used by TimerServer) ─────────────────────
  function findByName(name) {
    return root.timers.find(t => t.name === name)
  }
  function listNamed() {
    return root.timers.filter(t => t.name && t.name.length > 0).map(t => ({
          name: t.name,
          id: t.id,
          targetTimestamp: t.targetTimestamp
        }))
  }
  function pathJoin(...p) {
    return p.map(e => e.replace(/\/$/, '')).join("/").replace(/\/$/, '')
  }
  function removeTimer(id) {
    if (root.timers.length <= 1) {
      // min 1 remaining: reset in place instead of removing
      root.timers = root.timers.map(t => t.id === id ? {
          id: t.id,
          name: t.name,
          targetTimestamp: 0
        } : t)
    } else {
      root.timers = root.timers.filter(t => t.id !== id)
    }
    saveTimers()
    root.ensureUnsetSlot()
  }
  function saveTimers() {
    timersFile.writeAdapter()
  }

  // Create or update a timer by name. If it doesn't exist yet, create it.
  function setByName(name, targetTimestamp) {
    const ts = targetTimestamp || 0
    const existing = root.findByName(name)
    if (existing) {
      root.timers = root.timers.map(t => t.id === existing.id ? {
          id: t.id,
          name: t.name,
          targetTimestamp: ts
        } : t)
    } else {
      const t = root.timers.slice()
      t.push({
        id: root.nextId,
        name: name,
        targetTimestamp: ts
      })
      root.timers = t
      root.nextId += 1
    }
    saveTimers()
    root.ensureUnsetSlot()
  }
  function updateTimer(id, ts) {
    root.timers = root.timers.map(t => t.id === id ? {
        id: t.id,
        name: t.name,
        targetTimestamp: ts
      } : t)
    saveTimers()
    root.ensureUnsetSlot()
  }

  implicitHeight: rowLayout.implicitHeight
  implicitWidth: rowLayout.implicitWidth

  Component.onCompleted: root.ensureUnsetSlot()

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
    onLoaded: root.ensureUnsetSlot()

    JsonAdapter {
      id: jsonAdapter

      property int nextId: 2
      // Canonical list: [{ id, targetTimestamp }, ...]. Always start with
      // one unset slot so there's something to click even before a file
      // exists; overwritten by whatever's loaded from disk, if anything.
      property var timers: [
        {
          id: 1,
          name: "",
          targetTimestamp: 0
        }
      ]
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
        timerName: modelData.name || ""

        onCleared: id => root.removeTimer(id)
        onCommitted: (id, ts) => root.updateTimer(id, ts)
      }
    }
  }
}

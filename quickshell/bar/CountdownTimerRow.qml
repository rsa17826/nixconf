// CountdownTimerRow.qml
// A row of CountdownTimer widgets. Owns the canonical list + persistence.
// Clearing a timer removes it from the row; if it's the last one
// remaining, it's reset to "unset" instead of being removed (min 1 stays).
import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  // Heartbeat used purely to keep visibleTimers re-evaluating over time
  // (root.timers itself doesn't change just because a threshold like
  // "<12h away" gets crossed).
  property real _nowTick: Date.now()
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
  // How wide this row is allowed to grow before it must scroll instead of
  // pushing further right (e.g. bound to the space before the next bar
  // section, so timers never render underneath it). <=0 means unbounded.
  property real maxWidth: -1

  // Single/unset timers always show. Repeating timers (repeatValue > 0)
  // are hidden from the row unless they're within 12h of firing, OR
  // they're the single soonest-to-fire repeating timer overall (so
  // there's always at least one repeating timer visible as "on deck").
  readonly property var visibleTimers: {
    root._nowTick
    // dependency, so this recomputes on the heartbeat
    const now = Date.now()
    const twelveHours = 12 * 60 * 60 * 1000
    const repeating = root.timers.filter(t => t.repeatValue > 0)

    let soonestId = -1
    if (repeating.length > 0) {
      let soonest = repeating[0]
      for (const t of repeating) {
        if (t.targetTimestamp > 0 && (soonest.targetTimestamp <= 0 || t.targetTimestamp < soonest.targetTimestamp))
          soonest = t
      }
      soonestId = soonest.id
    }

    return root.timers.filter(t => {
      if (!(t.repeatValue > 0))
        return true
      if (t.id === soonestId)
        return true
      return isSameDay(t.targetTimestamp)
    }).sort((e, ee) => {
      // Unset ("set timer") slots always sort to the far right, regardless
      // of which side of the comparison they're on. Otherwise, ascending
      // by time remaining (soonest/lowest first).
      const eUnset = e.targetTimestamp === 0
      const eeUnset = ee.targetTimestamp === 0
      if (eUnset && eeUnset)
        return 0
      if (eUnset)
        return 1
      if (eeUnset)
        return -1
      return e.targetTimestamp - ee.targetTimestamp
    })
  }

  // ── Repeating timers ───────────────────────────────────────────
  // A repeating timer just has a repeatValue (ms > 0): once targetTimestamp
  // expires, it's advanced by repeatValue (possibly several times, if the
  // app wasn't running) until it's back in the future. repeatValue <= 0
  // means "don't repeat".
  //
  // targetTimestamp is the first/next occurrence and must be supplied by
  // the caller (there's no anchor to derive it from anymore).
  function addRepeatingTimer(name, targetTimestamp, repeatValue, url) {
    const u = url || ""

    // Same name + repeatValue already scheduled -> this is an edit of
    // that same timer, just refresh it in place.
    const existingIdx = root.timers.findIndex(t => t.name === name && t.repeatValue === repeatValue)
    if (existingIdx >= 0) {
      const t = root.timers.slice()
      t[existingIdx] = Object.assign({}, t[existingIdx], {
        targetTimestamp: targetTimestamp,
        startTimestamp: Date.now(),
        url: u
      })
      root.timers = t
      saveTimers()
      root.ensureUnsetSlot()
      return t[existingIdx].name
    }

    const t = root.timers.slice()
    t.push({
      id: root.nextId,
      name: name,
      targetTimestamp: targetTimestamp,
      startTimestamp: Date.now(),
      repeatValue: repeatValue,
      url: u
    })
    root.timers = t
    root.nextId += 1
    saveTimers()
    root.ensureUnsetSlot()
    return name
  }
  function addTimer() {
    const t = root.timers.slice()
    t.push({
      id: root.nextId,
      name: "",
      targetTimestamp: 0,
      startTimestamp: Date.now(),
      repeatValue: 0,
      url: ""
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
      targetTimestamp: 0,
      startTimestamp: Date.now(),
      repeatValue: 0,
      url: ""
    })
    root.timers = t
    root.nextId += 1
    saveTimers()
  }

  // ── Name-based API (used by TimerServer) ─────────────────────
  function findByName(name) {
    return root.timers.find(t => t.name === name)
  }

  // Whether any timer fires on the given calendar date (y full year, mo
  // 1-indexed, d day-of-month). Used by Calendar.qml to highlight days.
  // Non-repeating timers just check their one targetTimestamp; repeating
  // timers step forward by repeatValue from their current targetTimestamp,
  // bounded to a year's worth of occurrences.
  function hasTimerOnDate(y, mo, d) {
    const dayStart = new Date(y, mo - 1, d, 0, 0, 0).getTime()
    const dayEnd = new Date(y, mo - 1, d + 1, 0, 0, 0).getTime()
    return root.timers.some(t => {
      if (t.targetTimestamp <= 0)
        return false
      if (!(t.repeatValue > 0))
        return t.targetTimestamp >= dayStart && t.targetTimestamp < dayEnd
      let ts = t.targetTimestamp
      const cap = ts + 366 * 24 * 60 * 60 * 1000
      while (ts < dayEnd && ts < cap) {
        if (ts >= dayStart)
          return true
        ts += t.repeatValue
      }
      return false
    })
  }
  function isSameDay(t) {
    if (t <= 0)
      return false
    t = new Date(t)
    const n = clock.date
    return t.getFullYear() === n.getFullYear() && t.getMonth() === n.getMonth() && t.getDate() === n.getDate()
  }
  function listNamed() {
    return root.timers.filter(t => t.name && t.name.length > 0).map(t => ({
          name: t.name,
          id: t.id,
          targetTimestamp: t.targetTimestamp,
          url: t.url || ""
        }))
  }

  // Steps `ts` forward by `repeatValue` (ms) until it's strictly after
  // `fromMs`. repeatValue <= 0 returns `ts` unchanged (no repeat).
  function nextOccurrence(ts, repeatValue, fromMs) {
    if (!(repeatValue > 0))
      return ts
    while (ts <= fromMs)
      ts += repeatValue
    return ts
  }
  function pad(n) {
    return n < 10 ? "0" + n : "" + n
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
          targetTimestamp: 0,
          startTimestamp: Date.now(),
          repeatValue: 0,
          url: ""
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
  function setByName(name, targetTimestamp, url) {
    const ts = targetTimestamp || 0
    const u = url || ""
    const existing = root.findByName(name)
    if (existing) {
      root.timers = root.timers.map(t => t.id === existing.id ? {
          id: t.id,
          name: t.name,
          targetTimestamp: ts,
          startTimestamp: Date.now(),
          repeatValue: t.repeatValue || 0,
          url: u
        } : t)
    } else {
      const t = root.timers.slice()
      t.push({
        id: root.nextId,
        name: name,
        targetTimestamp: ts,
        url: u,
        startTimestamp: Date.now(),
        repeatValue: 0
      })
      root.timers = t
      root.nextId += 1
    }
    saveTimers()
    root.ensureUnsetSlot()
  }
  function updateTimer(id, ts, url, startTs) {
    root.timers = root.timers.map(t => t.id === id ? Object.assign({}, t, {
        targetTimestamp: ts,
        startTimestamp: Date.now(),
        url: url || ""
      }) : t)
    saveTimers()
    root.ensureUnsetSlot()
  }

  implicitHeight: rowLayout.implicitHeight
  implicitWidth: root.maxWidth > 0 ? Math.min(rowLayout.implicitWidth, root.maxWidth) : rowLayout.implicitWidth

  Component.onCompleted: root.ensureUnsetSlot()

  SystemClock {
    id: clock

    precision: SystemClock.Seconds
  }

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
      // Canonical list: [{ id, name, targetTimestamp, startTimestamp, url, repeatValue? }, ...].
      // repeatValue is ms; 0/absent means "don't repeat".
      // Always start with one unset slot so there's something to click even
      // before a file exists; overwritten by whatever's loaded from disk,
      // if anything.
      property var timers: [
        {
          id: 1,
          name: "",
          targetTimestamp: 0,
          startTimestamp: Date.now(),
          repeatValue: 0,
          url: ""
        }
      ]
    }
  }
  // Rolls repeating timers (repeatValue > 0) forward to their next
  // occurrence once the current target has passed. Non-repeating timers
  // are left alone — they just show "expired" like before.
  Timer {
    interval: 15000
    repeat: true
    running: true

    onTriggered: {
      const now = Date.now()
      let changed = false
      const updated = root.timers.map(t => {
        if (t.repeatValue > 0 && t.targetTimestamp > 0 && t.targetTimestamp <= now) {
          changed = true
          return Object.assign({}, t, {
            targetTimestamp: root.nextOccurrence(t.targetTimestamp, t.repeatValue, now),
            startTimestamp: Date.now()
          })
        }
        return t
      })
      if (changed) {
        root.timers = updated
        root.saveTimers()
      }
    }
  }
  Timer {
    interval: 60000
    repeat: true
    running: true

    onTriggered: root._nowTick = Date.now()
  }
  Flickable {
    id: scrollArea

    clip: true
    contentHeight: rowLayout.implicitHeight
    contentWidth: rowLayout.implicitWidth
    flickableDirection: Flickable.HorizontalFlick
    height: rowLayout.implicitHeight
    width: root.implicitWidth

    WheelHandler {
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

      onWheel: event => {
        const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
        scrollArea.contentX = Math.max(0, Math.min(scrollArea.contentWidth - scrollArea.width, scrollArea.contentX - delta))
      }
    }
    Row {
      id: rowLayout

      spacing: 0

      Repeater {
        model: root.visibleTimers

        delegate: CountdownTimer {
          repeatValue: modelData.repeatValue || 0
          startTimestamp: modelData.startTimestamp || 0
          targetTimestamp: modelData.targetTimestamp
          timerId: modelData.id
          timerName: modelData.name || ""
          url: modelData.url || ""

          onCleared: id => root.removeTimer(id)
          onCommitted: (id, ts, url, startTs) => root.updateTimer(id, ts, url, startTs)
        }
      }
    }
  }
}

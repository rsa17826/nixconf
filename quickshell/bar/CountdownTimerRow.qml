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

  // Single/unset timers always show. Repeating timers (weekly/monthly/
  // yearly) are hidden from the row unless they're within 12h of firing,
  // OR they're the single soonest-to-fire repeating timer overall (so
  // there's always at least one repeating timer visible as "on deck").
  readonly property var visibleTimers: {
    root._nowTick
    // dependency, so this recomputes on the heartbeat
    const now = Date.now()
    const twelveHours = 12 * 60 * 60 * 1000
    const repeating = root.timers.filter(t => t.repeatType && t.repeatType !== "none" && t.repeatType !== "single")

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
      if (!t.repeatType || t.repeatType === "none" || t.repeatType === "single")
        return true
      if (t.id === soonestId)
        return true
      return isSameDay(t.targetTimestamp)
    })
  }

  // ── Calendar-driven repeating timers ─────────────────────────
  // repeatType: "single" | "weekly" | "monthly" | "yearly"
  // anchor shape:
  //   single:  { y, mo, d, h, mi }
  //   weekly:  { weekday (0-6, Sun=0), h, mi }
  //   monthly: { d, h, mi }
  //   yearly:  { mo, d, h, mi }
  function addRepeatingTimer(repeatType, anchor) {
    const key = root.anchorKey(repeatType, anchor)
    const base = root.autoName(repeatType, anchor)
    const ts = root.nextOccurrence(repeatType, anchor, Date.now());

    // Exact same repeatType + day/time already scheduled -> this is an
    // edit of that same timer, just refresh it in place.
    const existingIdx = root.timers.findIndex(t => t.repeatType === repeatType && t.anchor && root.anchorKey(t.repeatType, t.anchor) === key)
    if (existingIdx >= 0) {
      const t = root.timers.slice()
      t[existingIdx] = Object.assign({}, t[existingIdx], {
        targetTimestamp: ts,
        anchor: anchor
      })
      root.timers = t
      saveTimers()
      root.ensureUnsetSlot()
      return t[existingIdx].name
    }

    // New timer. If another timer already has the same base name (e.g.
    // two separate "Mondays" timers at different times of day), give both
    // a time-of-day suffix so they don't collide/overwrite each other.
    const collisionIdx = root.timers.findIndex(t => t.repeatType === repeatType && t.name === base)
    let name = base
    let t = root.timers.slice()
    if (collisionIdx >= 0 && t[collisionIdx].anchor) {
      const collision = t[collisionIdx]
      name = base + " " + root.pad(anchor.h) + ":" + root.pad(anchor.mi)
      t[collisionIdx] = Object.assign({}, collision, {
        name: base + " " + root.pad(collision.anchor.h) + ":" + root.pad(collision.anchor.mi)
      })
    }

    t.push({
      id: root.nextId,
      name: name,
      targetTimestamp: ts,
      repeatType: repeatType,
      anchor: anchor
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
      targetTimestamp: 0
    })
    root.timers = t
    root.nextId += 1
    saveTimers()
  }

  // Identity key for a repeat rule + anchor — two timers are "the same"
  // (an edit, not a new one) only if repeatType and every anchor field,
  // including time-of-day, match exactly.
  function anchorKey(repeatType, anchor) {
    if (repeatType === "weekly")
      return "w-" + anchor.weekday + "-" + anchor.h + "-" + anchor.mi
    if (repeatType === "monthly")
      return "m-" + anchor.d + "-" + anchor.h + "-" + anchor.mi
    if (repeatType === "yearly")
      return "y-" + anchor.mo + "-" + anchor.d + "-" + anchor.h + "-" + anchor.mi
    return "s-" + anchor.y + "-" + anchor.mo + "-" + anchor.d + "-" + anchor.h + "-" + anchor.mi
  }

  // Builds the display/name string per the requested convention:
  //   single  -> "12/26"
  //   weekly  -> "Mondays"
  //   monthly -> "the 15th"
  //   yearly  -> "12/26 (yearly)"
  function autoName(repeatType, anchor) {
    if (repeatType === "weekly") {
      const names = ["Sundays", "Mondays", "Tuesdays", "Wednesdays", "Thursdays", "Fridays", "Saturdays"]
      return names[anchor.weekday] || "Weekly"
    } else if (repeatType === "monthly") {
      const d = anchor.d
      const suffix = (d % 10 === 1 && d !== 11) ? "st" : (d % 10 === 2 && d !== 12) ? "nd" : (d % 10 === 3 && d !== 13) ? "rd" : "th"
      return "the " + d + suffix
    } else if (repeatType === "yearly") {
      return root.pad(anchor.mo) + "/" + root.pad(anchor.d) + " (yearly)"
    }
    // single
    return root.pad(anchor.mo) + "/" + root.pad(anchor.d)
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

  // Whether any repeating/single timer fires on the given calendar date
  // (y full year, mo 1-indexed, d day-of-month). Used by Calendar.qml to
  // highlight days.
  function hasTimerOnDate(y, mo, d) {
    return root.timers.some(t => {
      if (!t.repeatType || t.repeatType === "none" || !t.anchor)
        return false
      if (t.repeatType === "weekly") {
        return new Date(y, mo - 1, d).getDay() === t.anchor.weekday
      } else if (t.repeatType === "monthly") {
        return d === Math.min(t.anchor.d, root.daysInMonth(y, mo))
      } else if (t.repeatType === "yearly") {
        return mo === t.anchor.mo && d === t.anchor.d
      } else if (t.repeatType === "single") {
        return y === t.anchor.y && mo === t.anchor.mo && d === t.anchor.d
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
          targetTimestamp: t.targetTimestamp
        }))
  }

  // Given a repeatType + anchor, returns the timestamp (ms) of the next
  // occurrence strictly after `fromMs`.
  function nextOccurrence(repeatType, anchor, fromMs) {
    const from = new Date(fromMs)
    if (repeatType === "weekly") {
      let d = new Date(from.getFullYear(), from.getMonth(), from.getDate(), anchor.h, anchor.mi, 0)
      const diff = (anchor.weekday - d.getDay() + 7) % 7
      d = new Date(d.getFullYear(), d.getMonth(), d.getDate() + diff, anchor.h, anchor.mi, 0)
      if (d.getTime() <= fromMs)
        d = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 7, anchor.h, anchor.mi, 0)
      return d.getTime()
    } else if (repeatType === "monthly") {
      let y = from.getFullYear(), mo = from.getMonth()
      let day = Math.min(anchor.d, root.daysInMonth(y, mo + 1))
      let d = new Date(y, mo, day, anchor.h, anchor.mi, 0)
      if (d.getTime() <= fromMs) {
        mo += 1
        if (mo > 11) {
          mo = 0
          y += 1
        }
        day = Math.min(anchor.d, root.daysInMonth(y, mo + 1))
        d = new Date(y, mo, day, anchor.h, anchor.mi, 0)
      }
      return d.getTime()
    } else if (repeatType === "yearly") {
      let y = from.getFullYear()
      let d = new Date(y, anchor.mo - 1, anchor.d, anchor.h, anchor.mi, 0)
      if (d.getTime() <= fromMs) {
        y += 1
        d = new Date(y, anchor.mo - 1, anchor.d, anchor.h, anchor.mi, 0)
      }
      return d.getTime()
    }
    // single
    return new Date(anchor.y, anchor.mo - 1, anchor.d, anchor.h, anchor.mi, 0).getTime()
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
  // Rolls repeating timers (weekly/monthly/yearly) forward to their next
  // occurrence once the current target has passed. Single timers are left
  // alone — they just show "expired" like before.
  Timer {
    interval: 15000
    repeat: true
    running: true

    onTriggered: {
      const now = Date.now()
      let changed = false
      const updated = root.timers.map(t => {
        if (t.repeatType && t.repeatType !== "none" && t.repeatType !== "single" && t.anchor && t.targetTimestamp > 0 && t.targetTimestamp <= now) {
          changed = true
          return Object.assign({}, t, {
            targetTimestamp: root.nextOccurrence(t.repeatType, t.anchor, now)
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
  Row {
    id: rowLayout

    spacing: 0

    Repeater {
      model: root.visibleTimers

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

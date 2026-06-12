pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
  id: root

  // Guard: don't save before the initial load has finished.
  property bool _historyLoaded: false
  readonly property int activeCount: activeNotifs.length

  // ── Derived views ────────────────────────────────────────────
  readonly property var activeNotifs: notifs.filter(n => !n.expired && !n.dismissed)

  // ── State ────────────────────────────────────────────────────
  property bool centerOpen: false

  // History — last 50 display-only entries, persisted to disk.
  // Shape matches notifs but _invoke/_expire are absent; actions: [].
  property var history: []

  // ── History file path ────────────────────────────────────────
  readonly property string historyFilePath: pathJoin(configPath(), "notif-history.json")

  // History with active/stored IDs excluded — avoids duplicates in the history section
  readonly property var historyFiltered: {
    const skip = new Set(notifs.filter(n => !n.dismissed).map(n => n.id))
    return history.filter(h => !skip.has(h.id))
  }
  property var loadTime: Date.now()

  // Live notification entries (active + stored).
  // Shape: { id, summary, body, appName, appIcon, urgency, transient,
  //          addedAt, stayVisibleFor, expired, dismissed,
  //          actions:[{id,text,_invoke}], _expire }
  property var notifs: []
  readonly property int storedCount: storedNotifs.length

  // Non-transient expired notifications — shown in center top section
  readonly property var storedNotifs: notifs.filter(n => n.expired && !n.dismissed && !n.transient)

  // ── History helpers ──────────────────────────────────────────
  function addToHistory(entry) {
    // Prepend, deduplicate by id, cap at 50
    root.history = [Object.assign({}, entry, {
        expired: true,
        dismissed: false
      })].concat(root.history.filter(x => x.id !== entry.id)).slice(0, 50)
  }
  function clearHistory() {
    root.history = []
  }

  // ── Public API ───────────────────────────────────────────────
  function clearStored() {
    root.notifs.forEach(n => {
      if (n.expired && !n.transient && n._expire)
        n._expire()
    })
    root.notifs = root.notifs.filter(n => !(n.expired && !n.transient))
  }
  function configPath() {
    // Quickshell.env provides access to system environment variables
    const ns = "qsbar"
    var place = ''
    const cfghome = Quickshell.env("XDG_CONFIG_HOME")
    if (cfghome) {
      place = pathJoin(cfghome, ns)
    } else {
      const home = Quickshell.env("HOME")
      if (home) {
        place = pathJoin(home, ".config", ns)
      } else {
        const uname = Quickshell.env("USER")
        if (uname) {
          place = pathJoin("/home", user, ".config", ns)
        } else {
          console.error("NO VARS SET - CAN'T FIND CONFIG LOCATION")
        }
      }
    }
    return place
  }
  function dismiss(id, hasClickedButton) {
    const entry = root.notifs.find(n => n.id === id)
    if (entry) {
      if (!hasClickedButton && entry._expire)
        entry._expire()
      addToHistory(entry)
    }
    root.notifs = root.notifs.map(n => n.id === id ? Object.assign({}, n, {
        dismissed: true
      }) : n)
  }
  function invokeAction(id, actionId) {
    const entry = root.notifs.find(n => n.id === id)
    if (entry) {
      const action = entry.actions.find(a => a.id === actionId)
      if (action && action._invoke) {
        action._invoke()
        dismiss(id, true)
      } else {
        dismiss(id, false)
      }
    } else {
      dismiss(id, false)
    }
  }
  function pathJoin(...p) {
    return p.map(e => e.replace(/\/$/)).join("/").replace(/\/$/, '')
  }
  function toggleCenter() {
    root.centerOpen = !root.centerOpen
    if (root.centerOpen) {
      let changed = false
      const updated = root.notifs.map(n => {
        if (!n.expired && !n.dismissed) {
          changed = true
          return Object.assign({}, n, {
            expired: true
          })
        }
        return n
      })
      if (changed)
        root.notifs = updated
    }
  }

  onHistoryChanged: {
    if (root._historyLoaded) {
      jsonAdapter.history = root.history
      historyFile.writeAdapter()
    }
  }

  // ── File reader ──────────────────────────────────────────────
  FileView {
    id: historyFile

    path: root.historyFilePath
    preload: true
    printErrors: false
    watchChanges: false

    onAdapterUpdated: writeAdapter()
    onFileChanged: reload()
    onLoadFailed: error => {
      jsonAdapter.history = []
      historyFile.writeAdapter()
      root._historyLoaded = true
    }

    JsonAdapter {
      id: jsonAdapter

      // Define the expected key from the JSON object
      property var history

      onHistoryChanged: {
        if (history === undefined)
          return

        // 2. Only update NotifState if the contents actually differ
        // This breaks the infinite loop chain!
        if (JSON.stringify(NotifState.history) !== JSON.stringify(history)) {
          // console.log("History loaded:", JSON.stringify(history))
          NotifState.history = history
        }
        root._historyLoaded = true
      }
    }
  }

  // ── Expiry timer ─────────────────────────────────────────────
  Timer {
    interval: 250
    repeat: true
    running: true

    onTriggered: {
      const now = Date.now()
      let changed = false

      const updated = root.notifs.map(n => {
        if (!n.expired && !n.dismissed && (now - n.addedAt) >= n.stayVisibleFor) {
          changed = true
          root.addToHistory(n)

          if (n.transient) {
            // Transient: expire server-side immediately, skip stored section
            if (n._expire)
              n._expire()
            return Object.assign({}, n, {
              dismissed: true
            })
          } else {
            // Normal: move to stored section
            return Object.assign({}, n, {
              expired: true
            })
          }
        }
        return n
      })

      if (changed)
        root.notifs = updated
    }
  }

  // ── Notification server ──────────────────────────────────────
  NotificationServer {
    id: server

    actionsSupported: true
    bodyMarkupSupported: true
    bodySupported: true
    keepOnReload: true

    onNotification: notif => {
      const urgencyVal = notif.urgency === NotificationUrgency.Critical ? 2 : notif.urgency === NotificationUrgency.Low ? 0 : 1

      notif.tracked = true

      const actions = []
      const rawActions = notif.actions
      if (rawActions) {
        for (let i = 0; i < rawActions.length; i++) {
          const a = rawActions[i]
          actions.push({
            id: a.identifier,
            text: a.text,
            _invoke: (function (action) {
                return action.invoke.bind(action)
              })(a)
          })
        }
      }

      const expireFn = (function (n) {
          return function () {
            if (n.expire)
              n.expire()
          }
        })(notif)

      if ((Date.now() - loadTime) < 30)
        loadTime = Date.now();

      // Read transient hint — exposed as notif.transient by QuickShell,
      // but also sent in hints map as --hint=int:transient:1
      const hints = notif.hints || {}
      const isTransient = !!(notif.transient || hints.transient)

      const entry = {
        id: notif.id,
        summary: notif.summary || "",
        body: notif.body || "",
        appName: notif.appName || "",
        appIcon: notif.appIcon || "",
        urgency: urgencyVal,
        transient: isTransient,
        actions: actions,
        addedAt: Date.now(),
        // stayVisibleFor: 0,
        // TODO
        stayVisibleFor: 5000,
        // Treat as already expired if arriving within reload window or while center is open
        expired: (Date.now() - loadTime) < 30 || root.centerOpen,
        dismissed: false,
        _expire: expireFn
      }

      const idx = root.notifs.findIndex(n => n.id === entry.id)
      if (idx >= 0) {
        const copy = root.notifs.slice()
        copy[idx] = entry
        root.notifs = copy
      } else {
        root.notifs = [entry].concat(root.notifs)
      }

      // Add to history immediately — historyFiltered hides it while
      // it is still active/stored, so no duplicate appears in the UI.
      root.addToHistory(entry)
    }
  }
}

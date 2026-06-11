pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
  id: root

  readonly property int activeCount: activeNotifs.length

  // ── Active popups ────────────────────────────────────────────
  readonly property var activeNotifs: notifs.filter(n => !n.expired && !n.dismissed)
  property bool centerOpen: false

  // ── History (last 50, display-only) ─────────────────────────
  // All notifications that were ever dismissed or expired, including
  // transient ones. Shown in the bottom section of the center panel.
  property var history: []
  property var loadTime: Date.now()

  // All notification entries.
  // Shape: { id, summary, body, appName, appIcon, urgency, transient,
  //          addedAt, stayVisibleFor, expired, dismissed,
  //          actions: [{id, text, _invoke}], _expire }
  property var notifs: []
  readonly property int storedCount: storedNotifs.length

  // ── Stored notifications (non-transient, expired, not dismissed) ─
  // Shown in the top section of the center panel.
  readonly property var storedNotifs: notifs.filter(n => n.expired && !n.dismissed && !n.transient)

  // ── History management ───────────────────────────────────────
  function addToHistory(entry) {
    const h = {
      id: entry.id,
      summary: entry.summary,
      body: entry.body,
      appName: entry.appName,
      appIcon: entry.appIcon,
      urgency: entry.urgency,
      transient: entry.transient,
      addedAt: entry.addedAt,
      // fields NotifToast reads — expired=true hides the countdown bar
      expired: true,
      dismissed: false,
      actions: [],
      stayVisibleFor: entry.stayVisibleFor
    };
    // Deduplicate by id, prepend, cap at 50
    root.history = [h].concat(root.history.filter(x => x.id !== entry.id)).slice(0, 50)
  }
  function clearHistory() {
    root.history = []
  }
  function clearStored() {
    root.notifs.forEach(n => {
      if (n.expired && !n.transient && n._expire)
        n._expire()
    })
    root.notifs = root.notifs.filter(n => !(n.expired && !n.transient))
  }

  // ── Public API ───────────────────────────────────────────────
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
  function toggleCenter() {
    root.centerOpen = !root.centerOpen
    if (root.centerOpen) {
      // Move all active notifications straight to stored when opening center
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
            // Transient: expire from server immediately, don't show in stored
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
      const urgencyVal = notif.urgency === NotificationUrgency.Critical ? 2 : notif.urgency === NotificationUrgency.Low ? 0 : 1;

      // Keep QML object alive so closures remain callable
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

      // Read transient hint — sent as --hint=int:transient:1 or boolean
      const hints = notif.hints || {}
      const isTransient = !!(notif.transient || hints["transient"] || hints["transient"] === 1)

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
        stayVisibleFor: 5000,
        // Treat as already expired if arriving within 30ms of reload (replay)
        // or if center is open
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
    }
  }
}

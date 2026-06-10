pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
  id: root

  // Derived counts — bar badge and center header use these
  readonly property int activeCount: {
    let c = 0
    for (const n of notifs)
      if (!n.expired && !n.dismissed)
        c++
    return c
  }

  // Active notifications (shown as popups)
  readonly property var activeNotifs: notifs.filter(n => !n.expired && !n.dismissed)
  property bool centerOpen: false
  readonly property int historyCount: {
    let c = 0
    for (const n of notifs)
      if (n.expired && !n.dismissed)
        c++
    return c
  }

  // Expired notifications (shown in center)
  readonly property var historyNotifs: notifs.filter(n => n.expired && !n.dismissed)

  // All notification entries.
  // Shape: { id, summary, body, appName, appIcon, urgency, addedAt,
  //          expired, dismissed, actions: [{id, text}], _ref }
  property var notifs: []

  function clearHistory() {
    root.notifs = root.notifs.filter(n => !n.expired)
  }

  // ── Public API ───────────────────────────────────────────────
  function dismiss(id) {
    root.notifs = root.notifs.map(n => n.id === id ? Object.assign({}, n, {
        dismissed: true
      }) : n)
  }
  function invokeAction(id, actionId) {
    const entry = root.notifs.find(n => n.id === id)
    if (entry && entry._ref) {
      const actions = entry._ref.actions
      console.log(JSON.stringify(entry._ref))
      console.log(JSON.stringify(entry))
      for (let i = 0; i < actions.length; i++) {
        if (actions[i].identifier === actionId) {
          actions[i].invoke()
          break
        }
      }
    }
    dismiss(id)
  }
  function toggleCenter() {
    root.centerOpen = !root.centerOpen
  }

  // ── Expiry timer ─────────────────────────────────────────────
  // Polls every 250ms. Expires non-critical notifications after 20s.
  // Critical stays until manually dismissed.
  Timer {
    interval: 250
    repeat: true
    running: true

    onTriggered: {
      const now = Date.now()
      let changed = false
      const updated = root.notifs.map(n => {
        // TODO
        if (!n.expired && !n.dismissed && n.urgency !== 20 && (now - n.addedAt) >= 2000) {
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

  // ── Notification server ──────────────────────────────────────
  NotificationServer {
    id: server

    actionsSupported: true
    bodyMarkupSupported: true
    bodySupported: true
    keepOnReload: true

    // iconSupported: true

    onNotification: notif => {
      const urgencyVal = notif.urgency === NotificationUrgency.Critical ? 2 : notif.urgency === NotificationUrgency.Low ? 0 : 1

      const actions = []
      for (let i = 0; i < notif.actions.length; i++) {
        const a = notif.actions[i]
        actions.push({
          id: a.identifier,
          text: a.text
        })
      }

      const entry = {
        id: notif.id,
        summary: notif.summary || "",
        body: notif.body || "",
        appName: notif.appName || "",
        appIcon: notif.appIcon || "",
        urgency: urgencyVal,
        actions: actions,
        addedAt: Date.now(),
        expired: false,
        dismissed: false,
        _ref: notif          // keep reference for action invocation
      };

      // Replace existing notification with same id (updated notification)
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

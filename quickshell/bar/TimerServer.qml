// TimerServer.qml
// Bridges CountdownTimerRow to a local HTTP API via a Python subprocess
// (webserver.py). Binds to 127.0.0.1 only — no auth, so keep it that way
// unless you add a shared-secret header check below.
//
// API:
//   GET    /timers            -> list named timers [{name,id,targetTimestamp,url}]
//   POST   /timers            body: {name, targetTimestamp, url?}  -> create/update by name
//   PUT    /timers/<name>     body: {targetTimestamp, url?}         -> update by name
//   DELETE /timers/<name>                                           -> clear/remove by name
import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root

  required property var timerRow   // pass in your CountdownTimerRow instance

  function handleRequest(msg) {
    const path = msg.path || ""
    const method = msg.method || "GET"
    const body = msg.body || {}

    let status = 200
    let respBody = {}

    if (method === "GET" && path === "/timers") {
      respBody = timerRow.listNamed()
    } else if (method === "POST" && path === "/timers") {
      if (!body.name) {
        status = 400
        respBody = {
          error: "name required"
        }
      } else {
        timerRow.setByName(body.name, body.targetTimestamp || Date.now(), body.url || "")
        respBody = {
          ok: true
        }
      }
    } else if (method === "PUT" && path.startsWith("/timers/")) {
      const name = decodeURIComponent(path.substring("/timers/".length))
      timerRow.setByName(name, body.targetTimestamp || Date.now(), body.url || "")
      respBody = {
        ok: true
      }
    } else if (method === "DELETE" && path.startsWith("/timers/")) {
      const name = decodeURIComponent(path.substring("/timers/".length))
      const removed = timerRow.clearByName(name)
      status = removed ? 200 : 404
      respBody = {
        ok: removed
      }
    } else {
      status = 404
      respBody = {
        error: "not found"
      }
    }

    return {
      reqId: msg.reqId,
      status: status,
      body: respBody
    }
  }

  Process {
    id: serverProc

    command: ["python3", Quickshell.env("HOME") + "/nixconf/quickshell/bar/webserver.py"]
    running: true

    stdout: SplitParser {
      splitMarker: "\n"

      onRead: line => {
        if (!line.trim())
          return
        let msg
        try {
          msg = JSON.parse(line)
        } catch (e) {
          console.error("TimerServer: bad JSON from webserver.py:", line)
          return
        }
        const resp = root.handleRequest(msg)
        serverProc.write(JSON.stringify(resp) + "\n")
      }
    }
  }
}

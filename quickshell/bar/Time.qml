// Time.qml
pragma Singleton

import Quickshell
import QtQuick
import "utils.js" as Utils

Singleton {
  id: root

  // an expression can be broken across multiple lines using {}
  readonly property string time: {
    // The passed format string matches the default output of
    // the `date` command.
    console.log(JSON.stringify(Object.getOwnPropertyNames(Utils)))
    Utils.owowify(Qt.formatDateTime(clock.date, "dddd MMM d HH:mm:ss t yyyy"))
  }

  SystemClock {
    id: clock

    precision: SystemClock.Seconds
  }
}

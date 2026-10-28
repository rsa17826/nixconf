// Time.qml
pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  // an expression can be broken across multiple lines using {}
  readonly property string time: {
    // The passed format string matches the default output of
    // the `date` command.
    clock.date ? Qt.formatDateTime(clock.date, "dddd MMM d HH:mm:ss t yyyy") : ''
  }

  SystemClock {
    id: clock

    precision: SystemClock.Seconds
  }
}

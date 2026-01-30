// ClockWidget.qml
import QtQuick

Text {
  color: "#6D0507"
  // we no longer need time as an input

  // directly access the time property from the Time singleton
  text: Time.time

  font {
    // family:
    pointSize: 10
  }
}

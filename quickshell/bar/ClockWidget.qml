// ClockWidget.qml
import QtQuick

Text {
  color: '#d40105'
  // we no longer need time as an input

  // directly access the time property from the Time singleton
  text: Time.time

  font {
    // family:
    pointSize: 10
  }
}

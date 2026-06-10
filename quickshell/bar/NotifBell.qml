import QtQuick

Rectangle {
  id: root

  color: "transparent"
  implicitHeight: bellRow.implicitHeight + 8
  implicitWidth: bellRow.implicitWidth + 14

  Row {
    id: bellRow

    anchors.centerIn: parent
    spacing: 5

    // Bell icon — lights up when there are stored notifications
    Text {
      anchors.verticalCenter: parent.verticalCenter
      color: NotifState.centerOpen ? "#c4cce8" : NotifState.historyCount > 0 ? "#4d6fff" : "#30324a"
      font.family: "monospace"
      font.pointSize: 11
      text: NotifState.historyCount > 0 ? "󰂚" : "󰂜"

      Behavior on color {
        ColorAnimation {
          duration: 150
        }
      }
    }

    // Badge — only visible when history has items
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      border.color: NotifState.centerOpen ? "#4d6fff" : "#2a3a8a"
      border.width: 1
      color: NotifState.centerOpen ? "#12122c" : "#0d0d1e"
      height: 13
      radius: 6
      visible: NotifState.historyCount > 0
      width: Math.max(13, badgeText.implicitWidth + 6)

      Text {
        id: badgeText

        anchors.centerIn: parent
        color: "#4d6fff"
        font.bold: true
        font.family: "monospace"
        font.pointSize: 7
        text: NotifState.historyCount > 99 ? "99+" : NotifState.historyCount
      }
    }
  }
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true

    onClicked: NotifState.toggleCenter()
  }
}

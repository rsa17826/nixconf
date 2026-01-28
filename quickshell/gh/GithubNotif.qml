import QtQuick
Rectangle {
  id: ghBadge

  color: ghNotifCount > 0 ? '#d31f31' : "#888888"
  height: 10
  radius: 20
  // Width grows/shrinks based on number of digits
  width: Math.max(height, textItem.width + 8)

  anchors {
    right: parent.right
    rightMargin: 10
    verticalCenter: parent.verticalCenter
  }

  // Text showing number of notifications
  Text {
    id: textItem

    anchors.centerIn: parent
    color: "white"
    font.bold: true
    font.pixelSize: 8
    text: ghNotifCount > 0 ? ghNotifCount : ""
  }
}

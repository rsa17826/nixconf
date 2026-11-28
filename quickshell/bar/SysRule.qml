// SysRule.qml - horizontal rule with bright ends and a diamond in the middle
import QtQuick

Item {
  id: root

  property color accent: "#40d9ff"

  implicitHeight: 9
  implicitWidth: 100

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45)
    height: 1
    width: parent.width
  }
  Rectangle {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    color: "#f2faff"
    height: 2
    width: 40
  }
  Rectangle {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    color: "#f2faff"
    height: 2
    width: 40
  }
  Rectangle {
    anchors.centerIn: parent
    color: "#d9faff"
    height: 6
    rotation: 45
    width: 6
  }
}

import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

Row {
  Repeater {
    model: SystemTray.items

    delegate: Item {
      id: delegateItem

      height: 24
      width: 24

      QsMenuAnchor {
        id: menuAnchor

        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.item: delegateItem          // anchors to the icon's position
        menu: modelData.menu
      }
      MouseArea {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        anchors.fill: parent

        onClicked: mouse => {
          if (mouse.button === Qt.RightButton) {
            if (modelData.hasMenu)
              menuAnchor.open()
          } else {
            if (!modelData.onlyMenu) {
              modelData.activate()
            } else if (modelData.hasMenu) {
              menuAnchor.open()
            }
          }
        }
      }
      IconImage {
        anchors.fill: parent
        source: modelData.icon
      }
    }
  }
}

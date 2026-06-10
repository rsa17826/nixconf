import QtQuick
import Quickshell
import Quickshell.Wayland

// One popup stack per screen so notifications appear on the active monitor.
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: root

    required property var modelData

    WlrLayershell.anchors: WlrAnchors.Top | WlrAnchors.Right
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notif-popups"
    color: "transparent"

    // Height grows with the stack; minimum 1 so the window exists
    implicitHeight: Math.max(1, barSpacer.height + popupCol.implicitHeight + 16)

    // Width = toast width + right padding
    implicitWidth: 380 + 16
    screen: modelData

    // Clear the bar height
    Item {
      id: barSpacer

      height: 36
      width: 1
    }
    Column {
      id: popupCol

      anchors.right: parent.right
      anchors.rightMargin: 16
      anchors.top: barSpacer.bottom
      spacing: 8
      width: 380

      Repeater {
        model: NotifState.activeNotifs

        delegate: NotifToast {
          required property var modelData

          entry: modelData
          width: 380
        }
      }
    }
  }
}

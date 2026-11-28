// SysFrame.qml
// LitRPG "system window" frame, ported from system_ui.gd's SystemFrame:
// glassy blue gradient octagon (big cuts TL + BR, small elsewhere), faint grid,
// glowing double outline, heavy edges on the big cuts, "===" ornament bottom-left,
// dot-line ornament top-right, and a light that runs along the top edge.
//
// glass: false -> draws only outline + ornaments (use as an overlay on content).
// `inset` leaves room for the glow inside the item's bounds (popup windows clip it);
// keep content at least inset + ~8px away from the edges.
import QtQuick
import QtQuick.Shapes

Item {
  id: root

  property color accent: "#40d9ff"
  property real breathe: 0
  property real cut: 12
  property bool glass: true
  property real inset: 4
  readonly property var outer: root.outline(root.inset, root.cut, root.small)
  property real scanP: 0
  property real small: 4
  readonly property color white: "#d9faff"
  readonly property bool _running: root.Window.visibility !== Window.Hidden

  function a(c, alpha) {
    return Qt.rgba(c.r, c.g, c.b, alpha)
  }
  // octagon with big cuts at top-left and bottom-right, small ones at the other corners
  function outline(i, cut, small) {
    const x0 = i
    const y0 = i
    const x1 = root.width - i
    const y1 = root.height - i
    return [Qt.point(x0 + cut, y0), Qt.point(x1 - small, y0), Qt.point(x1, y0 + small), Qt.point(x1, y1 - cut), Qt.point(x1 - cut, y1), Qt.point(x0 + small, y1), Qt.point(x0, y1 - small), Qt.point(x0, y0 + cut), Qt.point(x0 + cut, y0)]
  }

  SequentialAnimation on breathe {
    loops: Animation.Infinite
    running: root._running

    NumberAnimation {
      duration: 1571
      easing.type: Easing.InOutSine
      from: 0
      to: 1
    }
    NumberAnimation {
      duration: 1571
      easing.type: Easing.InOutSine
      from: 1
      to: 0
    }
  }
  NumberAnimation on scanP {
    duration: 2800
    from: 0
    loops: Animation.Infinite
    running: root._running && root.glass
    to: 1
  }

  // glass: lighter blue at the top fading to deep blue
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    visible: root.glass

    ShapePath {
      strokeColor: "transparent"

      fillGradient: LinearGradient {
        x1: 0
        x2: 0
        y1: 0
        y2: root.height

        GradientStop {
          color: "#8c0d52ad"
          position: 0
        }
        GradientStop {
          color: "#d100194d"
          position: 1
        }
      }

      PathPolyline {
        path: root.outer
      }
    }
  }

  // faint grid
  Repeater {
    model: root.glass ? Math.max(0, Math.ceil((root.width - 30) / 24)) : 0

    Rectangle {
      color: root.a(root.accent, 0.07)
      height: root.height - root.inset * 2 - 6
      width: 1
      x: 24 + index * 24
      y: root.inset + 3
    }
  }
  Repeater {
    model: root.glass ? Math.max(0, Math.ceil((root.height - 30) / 24)) : 0

    Rectangle {
      color: root.a(root.accent, 0.07)
      height: 1
      width: root.width - root.inset * 2 - 6
      x: root.inset + 3
      y: 24 + index * 24
    }
  }

  // outline: soft glow layers + bright core, inner line, heavy edges on the big cuts
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: "transparent"
      strokeColor: root.a(root.accent, 0.10 + 0.08 * root.breathe)
      strokeWidth: 8

      PathPolyline {
        path: root.outer
      }
    }
    ShapePath {
      fillColor: "transparent"
      strokeColor: root.a(root.accent, 0.28 + 0.12 * root.breathe)
      strokeWidth: 4

      PathPolyline {
        path: root.outer
      }
    }
    ShapePath {
      fillColor: "transparent"
      strokeColor: root.a(root.white, 0.95)
      strokeWidth: 1.5

      PathPolyline {
        path: root.outer
      }
    }
    ShapePath {
      fillColor: "transparent"
      strokeColor: root.a(root.accent, 0.4)
      strokeWidth: 1

      PathPolyline {
        path: root.outline(root.inset + 5, 8, 2)
      }
    }
    ShapePath {
      fillColor: "transparent"
      strokeColor: root.white
      strokeWidth: 3

      PathPolyline {
        path: [root.outer[7], root.outer[0]]
      }
    }
    ShapePath {
      fillColor: "transparent"
      strokeColor: root.white
      strokeWidth: 3

      PathPolyline {
        path: [root.outer[3], root.outer[4]]
      }
    }
  }

  // light running along the top edge
  Rectangle {
    height: 2
    visible: root.glass
    width: 70
    x: root.inset + root.cut + root.scanP * Math.max(0, root.width - root.inset * 2 - root.cut - 70)
    y: root.inset - 1

    gradient: Gradient {
      orientation: Gradient.Horizontal

      GradientStop {
        color: "#0040d9ff"
        position: 0
      }
      GradientStop {
        color: "#e6d9faff"
        position: 0.5
      }
      GradientStop {
        color: "#0040d9ff"
        position: 1
      }
    }
  }

  // "===" bottom-left
  Repeater {
    model: 3

    Rectangle {
      color: root.a(root.white, 0.9)
      height: 3
      width: 11
      x: 18 + index * 16
      y: root.height - root.inset - 1.5
    }
  }
  // dot-line top-right
  Item {
    x: root.width - root.inset - 56
    y: root.inset

    Rectangle {
      color: root.white
      height: 5
      radius: 2.5
      width: 5
      x: -2.5
      y: -2.5
    }
    Rectangle {
      color: root.a(root.white, 0.9)
      height: 2
      width: 36
      y: -1
    }
    Rectangle {
      color: root.white
      height: 5
      radius: 2.5
      width: 5
      x: 33.5
      y: -2.5
    }
  }
}

// GlitchEffect.qml
// Reusable wrapper: put any content inside it, and it gets rendered
// offscreen + run through shaders/recglitch.frag+vert for chromatic
// aberration, slice-glitch, and bloom.
//
// Usage:
//
//   GlitchEffect {
//     anchors.verticalCenter: parent.verticalCenter
//     active: someCondition        // pause the shader clock when hidden
//
//     Text { text: "hello" ... }   // put whatever you want inside
//   }
//
// `active` only controls the iTime-driving timer (so idle elements don't
// burn a 30fps timer for nothing) — it does NOT hide the content; use the
// normal `visible` property for that, same as any Item.
//
// IMPORTANT — sizing rule for content you put inside:
//   GlitchEffect expects exactly one top-level child (a Row, Column, Item,
//   or Text — anything with its own implicitWidth/implicitHeight). Its
//   size is read directly from that child's implicit size — deliberately
//   NOT from childrenRect, because childrenRect combined with
//   layer.enabled (needed for the shader's texture source) causes a real
//   "Binding loop detected for property height" — the layer's internal
//   texture-provider child gets counted in childrenRect too, so the
//   item's height ends up depending on itself.
//   Also: don't anchor that child to `parent` (position or size) — same
//   family of circular-binding bug. Let it size itself intrinsically.
//
// Tuning knobs (override per-instance if a widget wants a different feel):
//   aberration    — per-channel sample offset, default 0.0035
//   glitchAmount  — how far a "torn" slice shoves sideways, default 0.03
//   glitchRate    — multiplier on how often slices reseed, default 1.0
//   fadeDuration  — ms to ease out to a clean frame when active -> false,
//                   default 250
import QtQuick

Item {
  id: root

  // Internal: keeps the iTime timer alive through the fade-out so slices
  // keep animating back to rest instead of freezing mid-tear the instant
  // `active` flips false.
  property bool _fading: false

  // The single wrapped child (see file header) — read its own implicit
  // size directly instead of childrenRect, to avoid the layer.enabled +
  // childrenRect binding loop.
  readonly property Item _firstChild: contentItem.children.length > 0 ? contentItem.children[0] : null
  property real aberration: 0.0035
  property bool active: true
  default property alias content: contentItem.data
  property int fadeDuration: 250
  property real glitchAmount: 0.03
  property real glitchRate: 1.0

  implicitHeight: root._firstChild ? root._firstChild.implicitHeight : 0
  implicitWidth: root._firstChild ? root._firstChild.implicitWidth : 0

  onActiveChanged: {
    if (!active) {
      root._fading = true
      fadeOutTimer.restart()
    } else {
      root._fading = false
      fadeOutTimer.stop()
    }
  }

  // Stops the iTime timer only once the eased-out values have actually
  // reached zero, instead of cutting the animation off immediately.
  Timer {
    id: fadeOutTimer

    interval: root.fadeDuration
    running: false

    onTriggered: root._fading = false
  }
  Timer {
    interval: 33
    repeat: true
    running: root.active || root._fading

    onTriggered: shaderEffect.iTime += 0.033 * root.glitchRate
  }

  // Plain content, rendered offscreen into a texture for the shader
  // below. Sized explicitly from _firstChild's implicit size (not its own
  // childrenRect — see file header for why that loops with layer.enabled).
  Item {
    id: contentItem

    height: root._firstChild ? root._firstChild.implicitHeight : 0
    layer.enabled: true
    layer.smooth: true
    visible: false
    width: root._firstChild ? root._firstChild.implicitWidth : 0
  }
  ShaderEffect {
    id: shaderEffect

    // Eased toward 0 whenever `active` is false, instead of snapping —
    // so disabling mid-glitch settles to a clean frame over fadeDuration
    // rather than freezing on a torn one.
    property real aberration: root.active ? root.aberration : 0
    property real glitchAmount: root.active ? root.glitchAmount : 0
    property real iTime: 0.0
    property variant source: contentItem

    anchors.fill: contentItem
    fragmentShader: "shaders/recglitch.frag.qsb"
    vertexShader: "shaders/recglitch.vert.qsb"

    Behavior on aberration {
      NumberAnimation {
        duration: root.fadeDuration
      }
    }
    Behavior on glitchAmount {
      NumberAnimation {
        duration: root.fadeDuration
      }
    }
  }
}

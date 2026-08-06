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

  property bool active: true
  property real aberration: 0.0035
  property int fadeDuration: 250
  property real glitchAmount: 0.03
  property real glitchRate: 1.0

  default property alias content: contentItem.data

  // The single wrapped child (see file header) — read its own implicit
  // size directly instead of childrenRect, to avoid the layer.enabled +
  // childrenRect binding loop.
  readonly property Item _firstChild: contentItem.children.length > 0 ? contentItem.children[0] : null

  // Internal: keeps the iTime timer alive through the fade-out so slices
  // keep animating back to rest instead of freezing mid-tear the instant
  // `active` flips false.
  property bool _fading: false

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

    onTriggered: {
      shaderEffect.iTime += 0.033 * root.glitchRate
      // Re-roll amplitude jitter every tick — this is what actually makes
      // it vary over time. A plain `property real x: Math.random()`
      // binding only fires once at creation since QML has nothing to
      // trigger a re-evaluation off of.
      shaderEffect.randOffset = Math.random() * 0.5 + 0.75
    }
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
    property real aberration: root.active ? root.aberration * randOffset : 0
    property real glitchAmount: root.active ? root.glitchAmount * randOffset : 0
    // Random phase offset, picked once per instance — this is what
    // actually desyncs instances, since the shader's slice-reseed
    // timing (floor(iTime * 6.0)) is deterministic given iTime. Without
    // this every GlitchEffect starts iTime at 0 and ticks identically,
    // so they all glitch on the same frames regardless of amplitude.
    property real iTime: Math.random() * 100
    // Re-rolled on a timer (see below), NOT a static binding — Math.random()
    // inside a plain property binding only evaluates once, at creation,
    // since QML has no dependency to know it should re-run.
    property real randOffset: 1.0
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

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
// Tuning knobs (override per-instance if a widget wants a different feel):
//   aberration    — per-channel sample offset, default 0.0035
//   glitchAmount  — how far a "torn" slice shoves sideways, default 0.03
//   glitchRate    — multiplier on how often slices reseed, default 1.0
import QtQuick

Item {
  id: root

  property real aberration: 0.0035
  property bool active: true
  default property alias content: contentItem.data
  property real glitchAmount: 0.03
  property real glitchRate: 1.0

  implicitHeight: contentItem.childrenRect.height
  implicitWidth: contentItem.childrenRect.width

  Timer {
    interval: 33
    repeat: true
    running: root.active

    onTriggered: shaderEffect.iTime += 0.033 * root.glitchRate
  }
  Item {
    id: contentItem

    height: childrenRect.height
    layer.enabled: true
    layer.smooth: true
    visible: false
    width: childrenRect.width
  }
  ShaderEffect {
    id: shaderEffect

    property real aberration: root.aberration
    property real glitchAmount: root.glitchAmount
    property real iTime: 0.0
    property variant source: contentItem

    anchors.fill: contentItem
    fragmentShader: "shaders/recglitch.frag.qsb"
    vertexShader: "shaders/recglitch.vert.qsb"
  }
}

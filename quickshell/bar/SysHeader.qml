// SysHeader.qml - "[ TITLE ]" centred, with a SysRule under it
import QtQuick
import "owoify.js" as Owo

Column {
  required property string title

  spacing: 3

  Text {
    color: "#e6fcff"
    font.bold: true
    font.family: "monospace"
    font.pixelSize: 12
    horizontalAlignment: Text.AlignHCenter
    style: Text.Outline
    styleColor: "#6640d9ff"
    text: Owo.owo("[ " + title.toUpperCase() + " ]")
    width: parent.width
  }
  SysRule {
    width: parent.width
  }
}

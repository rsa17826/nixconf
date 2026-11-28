// SysShear.qml - slanted HUD-tab shear for buttons (x' = x - 0.12*y)
import QtQuick

Matrix4x4 {
  matrix: Qt.matrix4x4(1, -0.12, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
}

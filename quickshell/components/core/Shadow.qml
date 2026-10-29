import QtQuick
import QtQuick.Effects

// adapted from minflair (github.com/t4lentles5/minflair, GPL-3.0),
// config/quickshell/Core/Components/ThemedShadow.qml: the approach of wrapping
// Qt's RectangularShadow in one themed component instead of stacking
// translucent rects. Token wiring, geometry and defaults below are ours.
RectangularShadow {
    id: root
    property real strength: Theme.shadowOpacity

    visible: Theme.shadowOn && root.strength > 0
    blur: Theme.shadowBlur
    spread: Theme.shadowSpread
    offset: Qt.vector2d(Theme.shadowOffsetX, Theme.shadowOffsetY)
    color: Qt.rgba(Theme.shadowColor.r, Theme.shadowColor.g, Theme.shadowColor.b, root.strength)
    cached: true
    z: -1
}

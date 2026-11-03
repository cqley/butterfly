// shadow rendering adapted from minflair (github.com/t4lentles5/minflair), GPLv3, reused with permission
import QtQuick
import QtQuick.Effects

RectangularShadow {
    visible: Theme.shadowOn
    color: Qt.rgba(Theme.shadowColor.r, Theme.shadowColor.g, Theme.shadowColor.b, Theme.shadowOpacity)
    blur: Theme.shadowBlur
    spread: Theme.shadowSpread
    offset: Qt.vector2d(0, Theme.shadowOffsetY)
}

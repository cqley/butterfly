// shadow rendering adapted from minflair (github.com/t4lentles5/minflair), GPLv3, reused with permission
import QtQuick
import QtQuick.Effects

Item {
    id: root
    property real radius: 0
    property bool cached: false

    visible: Theme.shadowOn

    RectangularShadow {
        anchors.fill: parent
        radius: root.radius
        cached: root.cached
        color: Qt.rgba(Theme.shadowColor.r, Theme.shadowColor.g, Theme.shadowColor.b, Theme.shadowOpacity)
        blur: Theme.shadowBlur
        spread: Theme.shadowSpread
        offset: Qt.vector2d(0, Theme.shadowOffsetY)
    }

    RectangularShadow {
        anchors.fill: parent
        radius: root.radius
        cached: root.cached
        visible: Theme.shadowContact > 0
        color: Qt.rgba(Theme.shadowColor.r, Theme.shadowColor.g, Theme.shadowColor.b, Theme.shadowOpacity * Theme.shadowContact)
        blur: Theme.shadowContactBlur
        offset: Qt.vector2d(0, Theme.shadowContactOffsetY)
    }
}

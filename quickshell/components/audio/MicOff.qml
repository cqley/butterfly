import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    readonly property real u: Theme.micS / 12
    anchors.fill: parent

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.u - 1
        width: 5 * parent.u
        height: 7 * parent.u
        radius: width / 2
        color: Theme.red
        antialiasing: true
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 7 * parent.u - 1
        width: 7 * parent.u
        height: 3 * parent.u
        radius: parent.u
        color: "transparent"
        border.width: 1.2 * parent.u
        border.color: Theme.red
        antialiasing: true
    }

    Shape {
        width: 12
        height: 12
        scale: parent.u
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: Theme.red

            PathSvg { path: "M4.5 9H6.5V11H4.5Z" }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: 1.5 * parent.u
        radius: height / 2
        rotation: 45
        color: Theme.red
        antialiasing: true
    }
}

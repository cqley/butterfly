import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    readonly property real u: Theme.micS / 12
    anchors.fill: parent

    readonly property real drop: 0.5 * u

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.u - 1 + parent.drop
        width: 5 * parent.u
        height: 7 * parent.u
        radius: width / 2
        color: Theme.red
        antialiasing: true
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 7 * parent.u - 1 + parent.drop
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

            PathSvg { path: "M4.5 9.5H6.5V11.5H4.5Z" }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: (parent.height - height) / 2 + parent.drop
        width: parent.width
        height: 1.5 * parent.u
        radius: height / 2
        rotation: 45
        color: Theme.red
        antialiasing: true
    }
}

import QtQuick
import QtQuick.Shapes

Rectangle {
    id: root
    required property Item pick
    required property int at
    property string path: ""
    property real dx: 0
    property color tone: Theme.accent
    property color rest: Theme.fg
    readonly property bool on: pick.sel === at
    property color ink: on ? Theme.bg : rest
    readonly property alias glyph: glyph
    property alias under: base.data
    default property alias over: top.data
    signal clicked

    width: Theme.pwW
    height: Theme.pwH
    radius: Theme.inner(Theme.radius, Theme.pwPad)
    antialiasing: true
    color: on ? tone : Theme.chip
    border.width: Theme.launchIconBorderWidth
    border.color: on ? tone : Theme.launchIconBorder
    transformOrigin: Item.Center
    scale: scaleMotion.shaped

    ScaleSpring {
        id: scaleMotion
        size: Theme.pwW
        target: mouse.pressed ? Theme.feedbackPressScale : mouse.containsMouse ? Theme.feedbackHoverScale : 1
    }

    Behavior on color {
        ColorAnimation { duration: root.pick.snap ? 0 : Theme.glide; easing.type: Theme.ease }
    }
    Behavior on border.color {
        ColorAnimation { duration: root.pick.snap ? 0 : Theme.glide; easing.type: Theme.ease }
    }
    Behavior on ink {
        ColorAnimation { duration: root.pick.snap ? 0 : Theme.glide; easing.type: Theme.ease }
    }

    Item {
        id: base
        anchors.fill: parent
    }

    Shape {
        id: glyph
        x: Theme.mid(root.width, width) + root.dx
        y: Theme.mid(root.height, height)
        width: Theme.iconGrid
        height: Theme.iconGrid
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: Theme.iconStroke
            strokeColor: root.ink
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: root.path }
        }
    }

    Item {
        id: top
        anchors.fill: parent
    }

    PickArea {
        id: mouse
        pick: root.pick
        at: root.at
        onClicked: root.clicked()
    }
}

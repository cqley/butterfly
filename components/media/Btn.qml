import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property string path
    property bool solid: false
    property int dx: 0
    readonly property color ink: solid ? Theme.bg : Theme.fg
    signal clicked

    width: solid ? Theme.playS : Theme.ctlS
    height: width
    transformOrigin: Item.Center
    scale: !enabled ? 1 : area.pressed ? Theme.feedbackPressScale : area.containsMouse ? Theme.feedbackHoverScale : 1
    opacity: !enabled ? Theme.btnDisabled : solid || area.containsMouse ? 1 : Theme.btnIdle

    Behavior on scale { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
    Behavior on opacity { NumberAnimation { duration: Theme.fade; easing.type: Theme.ease } }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.accent
        visible: root.solid
        opacity: area.pressed ? Theme.btnPressed : 1
        antialiasing: true

        Behavior on opacity { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.fg
        opacity: !root.solid && area.containsMouse ? (area.pressed ? Theme.feedbackPressFill : Theme.feedbackHoverFill) : 0
        antialiasing: true

        Behavior on opacity { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
    }

    Shape {
        x: Math.round((root.width - width) / 2) + root.dx
        y: Math.round((root.height - height) / 2)
        width: Theme.iconGrid
        height: Theme.iconGrid
        scale: (root.solid ? Theme.playGlyph : Theme.glyphS) / Theme.iconGrid
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: Theme.btnStroke
            strokeColor: root.ink
            fillColor: root.solid ? root.ink : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: root.path }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property string path
    property bool solid: false
    property int dir: 0
    property int dx: 0
    property string shown: ""
    property string prev: ""
    property real morph: 1
    property real bump: 0
    readonly property color ink: solid ? Theme.bg : Theme.fg
    signal clicked

    onPathChanged: {
        if (shown === "") {
            shown = path
            return
        }
        prev = shown
        shown = path
        morph = 0
        morphAnim.restart()
    }

    width: solid ? Theme.playS : Theme.ctlS
    height: width
    transformOrigin: Item.Center
    scale: !enabled ? 1 : area.pressed ? Theme.feedbackPressScale : area.containsMouse ? Theme.feedbackHoverScale : 1
    opacity: !enabled ? Theme.btnDisabled : solid || area.containsMouse ? 1 : Theme.btnIdle

    Behavior on scale { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
    Behavior on opacity { NumberAnimation { duration: Theme.fade; easing.type: Theme.ease } }

    NumberAnimation {
        id: morphAnim
        target: root
        property: "morph"
        from: 0
        to: 1
        duration: Theme.mediaMorph
        easing.type: Theme.ease
    }

    SequentialAnimation {
        id: bumpAnim

        NumberAnimation {
            target: root
            property: "bump"
            to: root.dir * Theme.mediaNudge
            duration: Theme.mediaNudgeDuration / 2
            easing.type: Theme.ease
        }

        NumberAnimation {
            target: root
            property: "bump"
            to: 0
            duration: Theme.mediaNudgeDuration
            easing.type: Theme.ease
        }
    }

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
        anchors.margins: Theme.ctlFillInset
        radius: height / 2
        color: Theme.fg
        opacity: !root.solid && area.containsMouse ? (area.pressed ? Theme.feedbackPressFill : Theme.feedbackHoverFill) : 0
        antialiasing: true

        Behavior on opacity { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
    }

    Item {
        anchors.fill: parent

        transform: Translate { x: root.bump + root.dx }

        Shape {
            x: Math.round((root.width - width) / 2)
            y: Math.round((root.height - height) / 2)
            width: Theme.iconGrid
            height: Theme.iconGrid
            visible: root.morph < 1
            opacity: 1 - root.morph
            scale: (root.solid ? Theme.playGlyph : Theme.glyphS) / Theme.iconGrid * (1 + (1 - Theme.mediaMorphScale) * (1 - root.morph))
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: Theme.btnStroke
                strokeColor: root.ink
                fillColor: root.solid ? root.ink : "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg { path: root.prev }
            }
        }

        Shape {
            x: Math.round((root.width - width) / 2)
            y: Math.round((root.height - height) / 2)
            width: Theme.iconGrid
            height: Theme.iconGrid
            opacity: root.morph
            scale: (root.solid ? Theme.playGlyph : Theme.glyphS) / Theme.iconGrid * (Theme.mediaMorphScale + (1 - Theme.mediaMorphScale) * root.morph)
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: Theme.btnStroke
                strokeColor: root.ink
                fillColor: root.solid ? root.ink : "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg { path: root.shown }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.dir !== 0)
                bumpAnim.restart()
            root.clicked()
        }
    }
}

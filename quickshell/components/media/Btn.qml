import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property string path
    property var player: null
    property bool can: false
    property bool seen: false
    property bool primary: false
    property int dir: 0
    property int dx: 0
    property string shown: ""
    property string prev: ""
    property real morph: 1
    property real bump: 0
    readonly property bool live: player !== null && (can || seen)
    readonly property real glyph: primary ? Theme.playGlyph : Theme.glyphS
    signal clicked

    onCanChanged: if (can) seen = true
    onPlayerChanged: seen = false

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

    width: primary ? Theme.playS : Theme.ctlS
    height: width
    transformOrigin: Item.Center
    scale: !live ? 1 : area.pressed ? Theme.btnPressScale : area.containsMouse ? Theme.btnHoverScale : 1
    opacity: live ? 1 : Theme.btnDisabled

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

    Item {
        anchors.fill: parent

        transform: Translate { x: root.bump + root.dx }

        Shape {
            x: Math.round((root.width - width) / 2)
            y: Math.round((root.height - height) / 2)
            width: Theme.iconGrid
            height: Theme.iconGrid
            scale: root.glyph / Theme.iconGrid
            visible: root.morph < 1
            opacity: 1 - root.morph
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: Theme.btnStroke
                strokeColor: Theme.fg
                fillColor: Theme.fg
                fillRule: ShapePath.WindingFill
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
            scale: root.glyph / Theme.iconGrid
            opacity: root.morph
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: Theme.btnStroke
                strokeColor: Theme.fg
                fillColor: Theme.fg
                fillRule: ShapePath.WindingFill
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg { path: root.shown }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.live
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.dir !== 0)
                bumpAnim.restart()
            root.clicked()
        }
    }
}

import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    required property real value
    required property real peak
    required property bool ready
    required property bool muted
    required property bool focused
    required property string bodyPath
    property string strokePath: ""
    property bool dragging: false
    readonly property real span: Math.max(1, rail.width)
    readonly property real glow: Math.pow(root.peak, Theme.audioMeterGamma) * root.value
    signal moved(real v)
    signal stepped(int d)
    signal picked
    signal toggled

    width: parent.width
    height: Theme.audioBtn
    opacity: ready ? (muted ? Theme.dimSoft : 1) : Theme.dimEmpty

    Behavior on opacity {
        NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
    }

    Rectangle {
        id: btn
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.audioBtn
        height: Theme.audioBtn
        radius: height / 2
        color: mute.containsMouse ? Theme.tile : Theme.chip
        border.width: Theme.surfaceBorderWidth
        border.color: root.focused ? Theme.accent : Theme.surfaceBorder
        antialiasing: true
        scale: mute.pressed ? Theme.feedbackPressScale : mute.containsMouse ? Theme.feedbackHoverScale : 1

        Behavior on color {
            ColorAnimation { duration: Theme.feedbackDuration }
        }

        Behavior on border.color {
            ColorAnimation { duration: Theme.feedbackDuration }
        }

        Behavior on scale {
            NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
        }

        Shape {
            x: Math.round((Theme.audioBtn - Theme.audioIcon) / 2)
            y: x
            width: Theme.iconGrid
            height: Theme.iconGrid
            scale: Theme.audioIcon / Theme.iconGrid
            transformOrigin: Item.TopLeft
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: -1
                fillColor: Theme.fg
                fillRule: ShapePath.WindingFill

                PathSvg { path: root.bodyPath }
            }

            ShapePath {
                strokeWidth: Theme.audioIconStroke
                strokeColor: Theme.fg
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg { path: root.strokePath }
            }

            ShapePath {
                strokeWidth: root.muted ? Theme.audioSlashStroke : -1
                strokeColor: btn.color
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathSvg { path: Theme.audioSlashPath }
            }
        }

        MouseArea {
            id: mute
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.ready
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.picked()
                root.toggled()
            }
        }
    }

    Item {
        id: rail
        x: Theme.audioBtn + Theme.audioBtnGap
        width: root.width - x
        height: root.height

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: Theme.audioRailH
            radius: height / 2
            color: Theme.chip
            border.width: Theme.surfaceBorderWidth
            border.color: Theme.surfaceBorder
            antialiasing: true
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: root.value * root.span
            height: Theme.audioRailH
            radius: Math.min(height / 2, width / 2)
            color: Theme.audioFill
            antialiasing: true

            Behavior on width {
                enabled: !root.dragging

                SmoothedAnimation {
                    duration: Theme.audioGlide
                    maximumEasingTime: Theme.audioEasing
                }
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: root.glow * root.span
            height: Theme.audioRailH
            radius: Math.min(height / 2, width / 2)
            color: Theme.accent
            antialiasing: true

            Behavior on width {
                NumberAnimation { duration: Theme.audioMeterDecay }
            }
        }

        MouseArea {
            id: slide
            property real pressX: 0
            anchors.fill: parent
            enabled: root.ready
            cursorShape: Qt.PointingHandCursor
            onPressed: m => {
                pressX = m.x
                root.picked()
                root.moved(m.x / root.span)
            }
            onPositionChanged: m => {
                if (!pressed || (!root.dragging && Math.abs(m.x - pressX) < Theme.audioSlop))
                    return
                root.dragging = true
                root.moved(m.x / root.span)
            }
            onReleased: root.dragging = false
            onCanceled: root.dragging = false
        }
    }

    Wheel {
        anchors.fill: parent
        enabled: root.ready
        onStep: n => root.stepped(-n * Theme.audioStep)
    }
}

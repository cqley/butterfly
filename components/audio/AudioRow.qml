import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    required property real value
    required property real peak
    required property bool ready
    required property bool muted
    required property bool switchable
    required property bool focused
    required property string name
    required property string bodyPath
    property string strokePath: ""
    property bool dragging: false
    readonly property real travel: Math.max(1, rail.width - Theme.audioKnob)
    readonly property real glow: Math.pow(root.peak, Theme.audioMeterGamma) * root.value
    signal moved(real v)
    signal stepped(int d)
    signal picked
    signal toggled
    signal cycled

    width: parent.width
    height: stack.height
    opacity: ready ? (muted ? Theme.dimSoft : 1) : Theme.dimEmpty

    function at(x) {
        return (x - Theme.audioKnob / 2) / root.travel
    }

    Behavior on opacity {
        NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
    }

    Rectangle {
        id: btn
        y: Math.round((root.height - height) / 2)
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
        id: stack
        x: Theme.audioBtn + Theme.audioBtnGap
        width: root.width - x
        height: rail.y + rail.height

        Txt {
            id: label
            width: Math.max(0, parent.width - Theme.audioPctW - Theme.audioNameGap)
            height: Theme.audioCapH
            verticalAlignment: Text.AlignVCenter
            text: root.name
            elide: Text.ElideRight
            font.pixelSize: Theme.fsS
            opacity: dev.containsMouse ? 1 : Theme.dimMuted
            color: dev.containsMouse ? Theme.accent : Theme.fg

            Behavior on opacity {
                NumberAnimation { duration: Theme.feedbackDuration }
            }

            Behavior on color {
                ColorAnimation { duration: Theme.feedbackDuration }
            }

            MouseArea {
                id: dev
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.switchable
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.picked()
                    root.cycled()
                }
            }
        }

        Txt {
            anchors.right: parent.right
            width: Theme.audioPctW
            height: Theme.audioCapH
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            text: root.ready ? Math.round(root.value * 100) + Theme.audioPctChar : Theme.audioEmptyChar
            font.pixelSize: Theme.fsS
        }

        Item {
            id: rail
            y: Theme.audioCapH + Theme.audioCapGap
            width: parent.width
            height: Theme.audioKnob

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
                width: knob.x + Theme.audioKnob / 2
                height: Theme.audioRailH
                radius: height / 2
                color: Theme.audioFill
                antialiasing: true
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: root.glow > 0 ? Theme.audioKnob / 2 + root.glow * root.travel : 0
                height: Theme.audioRailH
                radius: height / 2
                color: Theme.accent
                antialiasing: true

                Behavior on width {
                    NumberAnimation { duration: Theme.audioMeterDecay }
                }
            }

            Rectangle {
                id: knob
                x: root.value * root.travel
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.audioKnob
                height: Theme.audioKnob
                radius: height / 2
                color: Theme.fg
                antialiasing: true
                scale: root.dragging ? Theme.audioKnobGrab : slide.containsMouse ? Theme.feedbackHoverScale : 1

                Behavior on x {
                    enabled: !root.dragging

                    SmoothedAnimation {
                        duration: Theme.audioGlide
                        maximumEasingTime: Theme.audioEasing
                    }
                }

                Behavior on scale {
                    NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                }
            }

            MouseArea {
                id: slide
                property real pressX: 0
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.ready
                cursorShape: Qt.PointingHandCursor
                onPressed: m => {
                    pressX = m.x
                    root.picked()
                    root.moved(root.at(m.x))
                }
                onPositionChanged: m => {
                    if (!pressed || (!root.dragging && Math.abs(m.x - pressX) < Theme.audioSlop))
                        return
                    root.dragging = true
                    root.moved(root.at(m.x))
                }
                onReleased: root.dragging = false
                onCanceled: root.dragging = false
            }
        }
    }

    Wheel {
        anchors.fill: parent
        enabled: root.ready
        onStep: n => root.stepped(-n * Theme.audioStep)
    }
}

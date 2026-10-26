import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    required property real value
    required property bool ready
    required property string label
    property bool labeled: false
    property bool dragging: false
    readonly property real span: Math.max(1, width - height)
    signal moved(real v)
    signal stepped(int d)
    signal picked

    width: parent.width
    height: Theme.brightTrackH
    opacity: ready ? 1 : Theme.dimEmpty

    Behavior on opacity {
        NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.chip
        border.width: Theme.launchIconBorderWidth
        border.color: Theme.launchIconBorder
        antialiasing: true
    }

    Txt {
        x: root.width - width - Theme.brightGap
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        visible: root.labeled
        color: Theme.fg
        opacity: Theme.dimMuted
        font.pixelSize: Theme.fsS
    }

    Rectangle {
        width: root.height + root.value * root.span
        height: parent.height
        radius: height / 2
        color: Theme.accent
        antialiasing: true
        clip: true

        Behavior on width {
            SmoothedAnimation {
                duration: Theme.brightGlide
                maximumEasingTime: Theme.brightEasing
            }
        }

        Txt {
            x: root.width - width - Theme.brightGap
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            visible: root.labeled
            color: Theme.bg
            font.pixelSize: Theme.fsS
        }

        Shape {
            x: Math.round((Theme.brightTrackH - Theme.brightIcon) / 2)
            y: x
            width: Theme.iconGrid
            height: Theme.iconGrid
            scale: Theme.brightIcon / Theme.iconGrid
            transformOrigin: Item.TopLeft
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: Theme.glyphStroke(Theme.brightIcon)
                strokeColor: Theme.bg
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg { path: Theme.brightSunPath }
            }
        }
    }

    MouseArea {
        property real pressX: 0
        anchors.fill: parent
        enabled: root.ready
        cursorShape: Qt.PointingHandCursor
        onPressed: m => {
            pressX = m.x
            root.picked()
            root.moved((m.x - root.height / 2) / root.span)
        }
        onPositionChanged: m => {
            if (!pressed || (!root.dragging && Math.abs(m.x - pressX) < Theme.brightSlop))
                return
            root.dragging = true
            root.moved((m.x - root.height / 2) / root.span)
        }
        onReleased: root.dragging = false
        onCanceled: root.dragging = false
    }

    Wheel {
        anchors.fill: parent
        enabled: root.ready
        onStep: n => root.stepped(-n * Theme.brightStep)
    }
}

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
                strokeWidth: Theme.iconStroke * Theme.iconGrid / Theme.brightIcon
                strokeColor: Theme.bg
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg { path: "M12 7A5 5 0 1 1 12 17A5 5 0 1 1 12 7ZM12 1V3M12 21V23M4.22 4.22L5.64 5.64M18.36 18.36L19.78 19.78M1 12H3M21 12H23M4.22 19.78L5.64 18.36M18.36 5.64L19.78 4.22" }
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

import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property bool shown: true
    property bool available: false
    property real pct: 0
    property color tone: Theme.batGreen
    property bool pluggedIn: false
    property int leadingGap: Theme.batGap
    readonly property bool active: root.shown && root.available
    readonly property real targetWidth: root.active ? root.leadingGap + Theme.batW + Theme.batNubGap + Theme.batNubW : 0
    property real enter: root.active ? 1 : 0
    property real boltEnter: root.pluggedIn ? 1 : 0

    width: (root.leadingGap + Theme.batW + Theme.batNubGap + Theme.batNubW) * root.enter
    height: Theme.h
    visible: root.enter > 0
    clip: true

    Behavior on enter {
        NumberAnimation {
            duration: Theme.idlePopDuration
            easing.type: Theme.ease
        }
    }

    Behavior on boltEnter {
        NumberAnimation {
            duration: Theme.batBoltDuration
            easing.type: Theme.ease
        }
    }

    Item {
        id: holder
        width: root.leadingGap + Theme.batW + Theme.batNubGap + Theme.batNubW
        height: Theme.batRowH
        anchors.verticalCenter: parent.verticalCenter
        scale: Theme.batPopScale + (1 - Theme.batPopScale) * root.enter
        opacity: root.enter

        Rectangle {
            id: body
            x: root.leadingGap
            width: Theme.batW
            height: Theme.batH
            anchors.verticalCenter: parent.verticalCenter
            radius: Theme.batRadius
            color: Theme.bg
            antialiasing: true

            Rectangle {
                x: Theme.batBorder
                y: Theme.batBorder
                width: root.pct > 0 ? Math.max(1, Math.round((body.width - Theme.batBorder * 2) * root.pct)) : 0
                height: body.height - Theme.batBorder * 2
                radius: Theme.batFillRadius
                color: root.tone
                antialiasing: true
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: body.radius
                border.color: Theme.fg
                border.width: Theme.batBorder
                antialiasing: true

                Shape {
                    anchors.centerIn: parent
                    width: Theme.batBoltW
                    height: Theme.batBoltH
                    visible: root.boltEnter > 0
                    opacity: root.boltEnter
                    scale: Theme.batBoltScale + (1 - Theme.batBoltScale) * root.boltEnter
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: Theme.fg
                        strokeColor: "transparent"
                        strokeWidth: 0

                        PathSvg {
                            path: "M2.8 0L0.55 3.1H2.1L1.72 7L4.35 3.3H2.75L2.8 0Z"
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.left: body.right
            anchors.leftMargin: Theme.batNubGap
            anchors.verticalCenter: body.verticalCenter
            width: Theme.batNubW
            height: Theme.batNubH
            radius: Theme.batNubW / 2
            color: Theme.batNubColor
            antialiasing: true
        }
    }
}

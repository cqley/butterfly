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
    property bool charged: false
    property real leadingGap: Theme.batGap
    property int settledGap: Math.round(leadingGap)
    readonly property bool active: root.shown && root.available
    readonly property real targetWidth: root.active ? root.settledGap + Theme.batW + Theme.batNubGap + Theme.batNubW : 0
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
            x: Math.round(root.leadingGap)
            width: Theme.batW
            height: Theme.batH
            anchors.verticalCenter: parent.verticalCenter
            radius: Theme.batRadius
            color: Theme.bg
            antialiasing: true

            Rectangle {
                id: fill
                readonly property real span: body.width - Theme.batBorder * 2
                readonly property real cornerRadius: Math.min(Theme.batFillRadius, width / 2)
                x: Theme.batBorder
                y: Theme.batBorder
                width: root.pct > 0 ? Math.max(Theme.batFillMin, fill.span * root.pct) : 0
                height: body.height - Theme.batBorder * 2
                visible: width > 0
                color: root.tone
                antialiasing: true
                topLeftRadius: fill.cornerRadius
                bottomLeftRadius: fill.cornerRadius
                topRightRadius: fill.cornerRadius
                bottomRightRadius: fill.cornerRadius
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: body.radius
                border.color: Theme.fg
                border.width: Theme.batBorder
                antialiasing: true
            }

            Shape {
                id: glyph
                width: root.charged ? Theme.batBoltW : Theme.batChargeW
                height: root.charged ? Theme.batBoltH : Theme.batChargeH
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2 + Theme.batBoltYOffset
                visible: root.boltEnter > 0
                opacity: root.boltEnter
                scale: Theme.batBoltScale + (1 - Theme.batBoltScale) * root.boltEnter
                preferredRendererType: Shape.CurveRenderer

                readonly property real softenW: root.charged ? Theme.batGlyphSoften : Theme.batChargeGlyphSoften
                readonly property real strokeW: root.charged ? Theme.batGlyphStroke : Theme.batChargeGlyphStroke

                ShapePath {
                    fillColor: Theme.bg
                    strokeColor: Theme.bg
                    strokeWidth: glyph.softenW + glyph.strokeW * 2
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap
                    fillRule: ShapePath.WindingFill

                    PathSvg {
                        path: root.charged ? Theme.batBoltPath : Theme.batChargePath
                    }
                }

                ShapePath {
                    fillColor: Theme.fg
                    strokeColor: Theme.fg
                    strokeWidth: glyph.softenW
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap
                    fillRule: ShapePath.WindingFill

                    PathSvg {
                        path: root.charged ? Theme.batBoltPath : Theme.batChargePath
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

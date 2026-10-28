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
    property real leadingGap: Theme.batGap
    property int settledGap: Math.round(leadingGap)
    readonly property bool active: root.shown && root.available
    readonly property real targetWidth: root.active ? root.settledGap + Theme.batW + Theme.batNubGap + Theme.batNubW : 0
    readonly property real enter: enterMotion.value
    readonly property real boltEnter: boltMotion.value

    width: (root.leadingGap + Theme.batW + Theme.batNubGap + Theme.batNubW) * root.enter
    height: Theme.h
    visible: root.enter > 0
    clip: true

    Spring {
        id: enterMotion
        target: root.active ? 1 : 0
        response: Theme.idlePopResponse
        damping: Theme.idlePopDamping
        duration: Theme.idlePopDuration
        easing: Theme.ease
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    Spring {
        id: boltMotion
        target: root.pluggedIn ? 1 : 0
        response: Theme.batBoltResponse
        damping: Theme.batBoltDamping
        duration: Theme.batBoltDuration
        easing: Theme.ease
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
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
            y: Math.round((parent.height - height) / 2)
            width: Theme.batW
            height: Theme.batH
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
                border.color: Theme.batOutline
                border.width: Theme.batBorder
                antialiasing: true
            }

            Item {
                id: glyphClip
                anchors.fill: parent
                clip: true

                Shape {
                    id: glyph
                    width: Theme.batBoltW
                    height: Theme.batBoltH
                    x: (parent.width - width) / 2
                    y: (parent.height - height) / 2 + Theme.batBoltYOffset
                    visible: root.boltEnter > 0
                    opacity: root.boltEnter
                    scale: Theme.batBoltScale + (1 - Theme.batBoltScale) * root.boltEnter
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: Theme.batBoltOutline
                        strokeColor: Theme.batBoltOutline
                        strokeWidth: Theme.batGlyphSoften + Theme.batGlyphStroke * 2
                        joinStyle: ShapePath.RoundJoin
                        capStyle: ShapePath.RoundCap
                        fillRule: ShapePath.WindingFill

                        PathSvg {
                            path: Theme.batBoltPath
                        }
                    }

                    ShapePath {
                        fillColor: Theme.batBoltColor
                        strokeColor: Theme.batBoltColor
                        strokeWidth: Theme.batGlyphSoften
                        joinStyle: ShapePath.RoundJoin
                        capStyle: ShapePath.RoundCap
                        fillRule: ShapePath.WindingFill

                        PathSvg {
                            path: Theme.batBoltPath
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

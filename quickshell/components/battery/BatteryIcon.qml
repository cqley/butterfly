import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real pct: 0
    property color tone: Theme.batOk
    property bool pluggedIn: false
    readonly property int cutAt: {
        if (root.pct <= 0)
            return 0
        return Math.min(Theme.batW, Math.max(Theme.batFillMin, Math.round(Theme.batW * root.pct)))
    }
    readonly property color dim: Qt.rgba(root.tone.r, root.tone.g, root.tone.b, root.tone.a * Theme.batTrack)

    width: Theme.batW + Theme.batNubGap + Theme.batNubW
    height: Theme.h

    Spring {
        id: boltMotion
        target: root.pluggedIn ? 1 : 0
        response: Theme.batBoltResponse
        damping: Theme.batBoltDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
        hold: Theme.springHold
    }

    Item {
        id: body
        x: 0
        y: (root.height - height) / 2
        width: Theme.batW
        height: Theme.batH

        Item {
            width: root.cutAt
            height: body.height
            clip: true

            Rectangle {
                width: body.width
                height: body.height
                radius: Theme.batRadius
                color: root.tone
                antialiasing: true
            }
        }

        Item {
            x: root.cutAt
            width: body.width - root.cutAt
            height: body.height
            clip: true

            Rectangle {
                x: -root.cutAt
                width: body.width
                height: body.height
                radius: Theme.batRadius
                color: root.dim
                antialiasing: true
            }
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
                visible: boltMotion.shaped > 0
                opacity: boltMotion.shaped
                scale: Theme.batBoltScale + (1 - Theme.batBoltScale) * boltMotion.shaped
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
        x: Theme.batW + Theme.batNubGap
        y: (root.height - height) / 2
        width: Theme.batNubW
        height: Theme.batNubH
        topRightRadius: Theme.batNubW / 2
        bottomRightRadius: Theme.batNubW / 2
        color: root.dim
        antialiasing: true
    }
}

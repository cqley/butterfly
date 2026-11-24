import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property bool shown: true
    property bool open: false
    property bool instant: false
    property color ink: Theme.clockInk
    property color ground: Theme.bg
    property real lit: 0
    readonly property real lift: Theme.lockerShackleLift * leg.shaped
    readonly property color tint: Theme.mix(root.ground, root.ink, root.lit)
    readonly property bool settled: Math.abs(root.lit - (root.shown ? 1 : 0)) < Theme.lockerGlyphNear && Math.abs(leg.shaped - leg.target) < Theme.lockerSettle

    width: Theme.lockerGlyph
    height: Theme.lockerGlyph
    visible: root.lit > 0.001

    Component.onCompleted: root.lit = root.shown ? 1 : 0
    onShownChanged: root.relight()

    onInstantChanged: {
        if (!root.instant)
            return
        leg.land(leg.target)
        root.relight()
    }

    function follow(o) {
        fade.stop()
        root.lit = o.lit
        leg.land(o.legSpring.shaped)
        leg.kick(o.legSpring.moving ? o.legSpring.velocity : 0)
        if (root.lit !== (root.shown ? 1 : 0))
            root.relight()
    }

    readonly property alias legSpring: leg

    function relight() {
        fade.stop()
        if (root.instant) {
            root.lit = root.shown ? 1 : 0
            return
        }
        fade.to = root.shown ? 1 : 0
        fade.duration = root.shown ? Theme.lockerGlyphRise : Theme.lockerGlyphFall
        fade.start()
    }

    NumberAnimation {
        id: fade
        target: root
        property: "lit"
        easing.type: Theme.lockerGlyphEase
    }

    Spring {
        id: leg
        target: root.open ? 1 : 0
        response: Theme.lockerShackleResponse
        damping: Theme.lockerGlyphDamping
        hold: Theme.springHold
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
        snap: root.instant
    }

    Shape {
        x: (root.width - Theme.iconGrid) / 2
        y: (root.height - Theme.iconGrid) / 2
        width: Theme.iconGrid
        height: Theme.iconGrid
        transformOrigin: Item.Center
        scale: root.width / Theme.iconGrid
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: Theme.glyphStroke(root.width)
            strokeColor: root.tint
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: Theme.authBodyPath }
        }

        ShapePath {
            strokeWidth: Theme.glyphStroke(root.width)
            strokeColor: root.tint
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: "M7 " + Theme.authLockShut + "V" + (7 - root.lift).toFixed(2) + "A5 5 0 0 1 17 " + (7 - root.lift).toFixed(2)
                    + "V" + (Theme.authLockShut - (Theme.authLockShut - Theme.authLockOpen + root.lift) * leg.shaped).toFixed(2)
            }
        }
    }
}

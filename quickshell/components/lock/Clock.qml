import "../core"
import QtQuick
import QtQuick.Effects

Item {
    id: root
    property real t: 1
    property real move: root.t
    property point from: Qt.point(0, 0)
    property point to: Qt.point(0, 0)
    property bool fromInk: true
    property Item wall: null
    property string text: ""
    readonly property real dip: Theme.lockerDip / Math.max(1, Math.abs(root.endY - root.from.y))
    readonly property real reach: root.move >= 0 ? root.move : -root.dip * Math.tanh(-root.move / root.dip)
    readonly property real size: Theme.clockPx + (Theme.lockerClockPx - Theme.clockPx) * root.reach
    readonly property real endX: Math.round(root.to.x - big.width / 2) + big.width / 2
    readonly property real endY: Math.round(root.to.y - big.height / 2) + big.height / 2
    readonly property real cx: root.from.x + (root.endX - root.from.x) * root.reach
    readonly property real cy: root.from.y + (root.endY - root.from.y) * root.reach
    readonly property real swap: root.ease(0, Theme.lockerInkSwap, root.t)
    readonly property real glass: root.wall && root.wall.ready ? root.ease(Theme.lockerGlassFrom, Theme.lockerGlassTo, root.t) : 0

    function ease(a, b, v) {
        const u = Math.max(0, Math.min(1, (v - a) / (b - a)))
        return u * u * (3 - 2 * u)
    }

    opacity: root.fromInk ? 1 : root.ease(0, Theme.lockerGlassFrom, root.t)

    Item {
        id: small
        readonly property real k: root.size / Theme.clockPx
        width: smallInk.implicitWidth
        height: Theme.h
        x: root.cx - width / 2
        y: root.cy - height / 2
        scale: small.k
        visible: root.fromInk && root.swap < 1
        opacity: 1 - root.swap

        RollTxt {
            id: smallInk
            anchors.fill: parent
            text: root.text
            color: Theme.clockInk
            font.pixelSize: Theme.clockPx
            font.features: Theme.tabular
            dx: Theme.clockOffsetX
        }
    }

    Item {
        id: big
        readonly property real k: root.size / Theme.lockerClockPx
        width: bigInk.implicitWidth
        height: 2 * Theme.lockerClockPx
        x: root.cx - width / 2
        y: root.cy - height / 2
        scale: big.k
        opacity: root.fromInk ? root.swap : 1

        RollTxt {
            id: bigInk
            anchors.fill: parent
            text: root.text
            color: Theme.clockInk
            font.pixelSize: Theme.lockerClockPx
            font.weight: Theme.lockerClockWeight
            renderType: Text.CurveRendering
            font.features: Theme.tabular
            dx: Theme.clockOffsetX
            opacity: 1 - root.glass
            visible: opacity > 0
        }

        Item {
            id: mask
            anchors.fill: parent

            RollTxt {
                anchors.fill: parent
                text: root.text
                color: Theme.white
                font.pixelSize: Theme.lockerClockPx
                font.weight: Theme.lockerClockWeight
                renderType: Text.CurveRendering
                font.features: Theme.tabular
                dx: Theme.clockOffsetX
            }
        }

        ShaderEffectSource {
            id: ink
            anchors.fill: parent
            visible: false
            live: true
            hideSource: true
            sourceItem: mask
            smooth: true
            mipmap: true
        }

        ShaderEffectSource {
            id: sample
            visible: false
            live: true
            hideSource: true
            sourceItem: root.wall
            mipmap: true
            sourceRect: Qt.rect((big.x + big.width * (1 - big.k) / 2) / Theme.lockerGlassScale,
                (big.y + big.height * (1 - big.k) / 2) / Theme.lockerGlassScale,
                big.width * big.k / Theme.lockerGlassScale, big.height * big.k / Theme.lockerGlassScale)
        }

        MultiEffect {
            anchors.fill: parent
            visible: root.glass > 0
            opacity: root.glass
            source: sample
            maskEnabled: true
            maskSource: ink
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }
}

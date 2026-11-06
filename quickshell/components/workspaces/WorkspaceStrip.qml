import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property int index: 0
    property int count: Theme.wsCount
    property int total: Theme.wsCount
    property var filled: []
    property bool live: true
    property bool vert: false
    property real layoutFade: 0
    property real veil: 1
    readonly property real position: slide.value

    property int markIndex: 0
    property real travel: 0

    // dots
    readonly property int dotW: Theme.wsDot
    readonly property int dotH: Theme.wsDot
    readonly property int dotActW: Math.max(Theme.wsActiveW, root.dotW)
    readonly property int dotActH: Math.max(Theme.wsActiveH, root.dotH)
    readonly property int dotPitch: root.dotW + Theme.wsGap

    // bars
    readonly property int barW: Theme.wsBarW
    readonly property int barH: Theme.wsBarH
    readonly property int barActW: Math.max(Theme.wsBarActiveW, root.barW)
    readonly property int barActH: Math.max(Theme.wsBarActiveH, root.barH)
    readonly property int barPitch: root.barW + Theme.wsBarGap

    // mode
    readonly property int pipW: root.vert ? root.barW : root.dotW
    readonly property int pipH: root.vert ? root.barH : root.dotH
    readonly property int actW: root.vert ? root.barActW : root.dotActW
    readonly property int actH: root.vert ? root.barActH : root.dotActH
    readonly property int pitch: root.vert ? root.barPitch : root.dotPitch
    readonly property int span: (root.count - 1) * root.pitch + root.actW

    // carousel
    readonly property int bias: Math.floor((root.count - 1) / 2)
    readonly property int reachWant: Math.max(0, root.total - root.count)
    property real reach: 0
    readonly property real limit: Math.max(root.reach, slide.value - (root.count - 1))
    readonly property real scroll: Math.max(0, Math.min(root.limit, slide.value - root.bias))
    readonly property int rendered: Math.max(root.total, Math.ceil(slide.value) + 2)

    readonly property color dimInk: Theme.mix(Theme.bg, Theme.fg, Theme.wsDotDim)
    readonly property color liveInk: Theme.mix(Theme.bg, Theme.fg, Theme.wsDotLive)
    readonly property color activeInk: Theme.wsAccent ? Theme.accent : Theme.fg
    readonly property int grid: 20
    readonly property string pipPath: Theme.capsulePath(root.pipW * root.grid, root.pipH * root.grid)
    readonly property string actPath: Theme.capsulePath(root.actW * root.grid, root.actH * root.grid)

    width: root.span
    height: Theme.h
    clip: true

    function settle() {
        reachRun.stop()
        root.reach = root.reachWant
        root.markIndex = root.index
        root.travel = 0
        slide.land(root.index)
    }

    function sync() {
        if (!root.live) {
            root.settle()
            return
        }
        if (root.markIndex === root.index)
            return
        reachRun.stop()
        root.reach = root.reachWant
        root.travel = Math.abs(root.index - slide.value)
        root.markIndex = root.index
    }

    onIndexChanged: gate.restart()
    onTotalChanged: gate.restart()
    onLiveChanged: if (!root.live) root.settle()

    onReachWantChanged: {
        reachRun.stop()
        if (!root.live) {
            root.reach = root.reachWant
            return
        }
        reachRun.to = root.reachWant
        reachRun.start()
    }

    Component.onCompleted: root.settle()

    Timer {
        id: gate
        interval: 0
        onTriggered: root.sync()
    }

    SmoothedAnimation {
        id: reachRun
        target: root
        property: "reach"
        velocity: 1000 / Theme.wsSwap
    }

    Spring {
        id: slide
        target: root.markIndex
        response: Theme.wsResponse * (1 + Theme.wsSpread * Math.max(0, Math.min(root.travel, Theme.wsSpreadCap) - 1))
        damping: Theme.wsDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    Fade {
        id: reveal
        anchors.fill: parent
        shown: root.live

        Item {
            id: track
            x: -root.scroll * root.pitch
            width: root.rendered * root.pitch
            height: parent.height
            opacity: (1 - root.layoutFade) * root.veil

            Repeater {
                model: root.rendered

                Shape {
                    id: pip
                    preferredRendererType: Shape.CurveRenderer
                    required property int index
                    readonly property real weight: Math.max(0, 1 - Math.abs(pip.index - slide.value))
                    readonly property real lead: Math.max(0, Math.min(1, pip.index - slide.value))
                    readonly property real seen: pip.x + track.x + root.pipW / 2
                    readonly property real past: Math.max(0, -pip.seen) + Math.max(0, pip.seen - root.span)
                    readonly property real edge: Math.max(0, 1 - pip.past / (root.pitch / 2))

                    x: root.vert
                        ? pip.index * root.pitch + (root.actW - root.pipW) / 2
                        : pip.index * root.pitch + (root.actW - root.pipW) * pip.lead
                    y: (track.height - root.pipH) / 2
                    width: root.pipW
                    height: root.pipH
                    opacity: (1 - pip.weight) * pip.edge
                    transformOrigin: Item.TopLeft
                    transform: Scale { xScale: 1 / root.grid; yScale: 1 / root.grid }

                    ShapePath {
                        strokeWidth: -1
                        fillColor: root.filled[pip.index] ? root.liveInk : root.dimInk

                        PathSvg { path: root.pipPath }
                    }
                }
            }

            Shape {
                id: mark
                preferredRendererType: Shape.CurveRenderer
                x: slide.value * root.pitch
                y: (track.height - root.actH) / 2
                width: root.actW
                height: root.actH
                transformOrigin: Item.TopLeft
                transform: Scale { xScale: 1 / root.grid; yScale: 1 / root.grid }

                ShapePath {
                    strokeWidth: -1
                    fillColor: root.activeInk

                    PathSvg { path: root.actPath }
                }
            }
        }
    }
}

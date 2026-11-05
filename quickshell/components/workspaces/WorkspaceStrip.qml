import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property int index: 0
    property int count: Theme.wsCount
    property int page: 0
    property var filled: []
    property bool churn: false
    property int lastPage: 0
    property int dir: 1
    property real travel: 0
    readonly property real position: slide.value

    readonly property bool vert: Theme.wsVertical
    readonly property int pipW: root.vert ? Theme.wsBarW : Theme.wsDot
    readonly property int pipH: root.vert ? Theme.wsBarH : Theme.wsDot
    readonly property int actW: Math.max(root.vert ? Theme.wsBarActiveW : Theme.wsActiveW, root.pipW)
    readonly property int actH: Math.max(root.vert ? Theme.wsBarActiveH : Theme.wsActiveH, root.pipH)
    readonly property int pitch: root.pipW + (root.vert ? Theme.wsBarGap : Theme.wsGap)
    readonly property int span: (root.count - 1) * root.pitch + root.actW
    readonly property int bleed: root.pitch

    readonly property color dimInk: Theme.mix(Theme.bg, Theme.fg, Theme.wsDotDim)
    readonly property color liveInk: Theme.mix(Theme.bg, Theme.fg, Theme.wsDotLive)
    readonly property color activeInk: Theme.wsAccent ? Theme.accent : Theme.fg
    readonly property int grid: 20
    readonly property string pipPath: Theme.capsulePath(root.pipW * root.grid, root.pipH * root.grid)
    readonly property string actPath: Theme.capsulePath(root.actW * root.grid, root.actH * root.grid)

    width: root.span
    height: Theme.h
    opacity: root.churn ? 0 : 1

    onIndexChanged: root.travel = Math.abs(root.index - slide.value)

    onPageChanged: {
        root.dir = root.page > root.lastPage ? 1 : -1
        root.lastPage = root.page
        slide.land(slide.value)
        drift.land(0)
        drift.target = -root.dir * root.pitch
        root.churn = true
        swap.restart()
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.wsSwap
            easing.type: Theme.ease
        }
    }

    Timer {
        id: swap
        interval: Theme.wsSwap
        onTriggered: {
            slide.land(root.index)
            drift.land(root.dir * root.pitch)
            drift.target = 0
            root.churn = false
        }
    }

    Spring {
        id: drift
        response: Theme.wsResponse
        damping: Theme.wsDamping
        epsilon: Theme.springEps
        rest: Theme.springStop
    }

    Spring {
        id: slide
        target: root.index
        response: Theme.wsResponse * (1 + Theme.wsSpread * Math.max(0, root.travel - 1))
        damping: Theme.wsDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    Item {
        id: window
        x: -root.bleed
        width: root.width + 2 * root.bleed
        height: root.height
        clip: true

        Item {
            id: track
            x: root.bleed + drift.value
            width: root.span
            height: parent.height

            Repeater {
                model: root.count

                Shape {
                    id: pip
                    preferredRendererType: Shape.CurveRenderer
                    required property int index
                    readonly property real weight: Math.max(0, 1 - Math.abs(pip.index - slide.value))
                    readonly property real lead: Math.max(0, Math.min(1, pip.index - slide.value))

                    x: root.vert
                        ? pip.index * root.pitch + (root.actW - root.pipW) / 2
                        : pip.index * root.pitch + (root.actW - root.pipW) * pip.lead
                    y: (track.height - root.pipH) / 2
                    width: root.pipW
                    height: root.pipH
                    opacity: 1 - pip.weight
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

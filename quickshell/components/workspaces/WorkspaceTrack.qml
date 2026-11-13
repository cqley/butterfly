import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property int pipW: Theme.wsDot
    property int pipH: Theme.wsDot
    property int actW: Theme.wsActiveW
    property int actH: Theme.wsActiveH
    property int gap: Theme.wsGap
    property bool reflow: true
    property int count: Theme.wsCount
    property int rendered: Theme.wsCount
    property real position: 0
    property real scroll: 0
    property var filled: []
    property color dimInk: Theme.fg
    property color liveInk: Theme.fg
    property color activeInk: Theme.fg
    property int hot: -1

    readonly property int act: Math.max(root.actW, root.pipW)
    readonly property int actTall: Math.max(root.actH, root.pipH)
    readonly property int pitch: root.pipW + root.gap
    readonly property int span: (root.count - 1) * root.pitch + root.act
    readonly property int grid: 20
    readonly property string pipPath: Theme.capsulePath(root.pipW * root.grid, root.pipH * root.grid)
    readonly property string actPath: Theme.capsulePath(root.act * root.grid, root.actTall * root.grid)

    function centre(i) {
        if (Math.abs(i - root.position) < 0.5)
            return root.position * root.pitch + root.act / 2
        const lead = Math.max(0, Math.min(1, i - root.position))
        return root.reflow
            ? i * root.pitch + (root.act - root.pipW) * lead + root.pipW / 2
            : i * root.pitch + root.act / 2
    }

    function slotAt(x) {
        const at = root.mapToItem(track, x, 0).x
        let best = -1
        let gap = Infinity
        for (let i = 0; i < root.rendered; i++) {
            const d = Math.abs(root.centre(i) - at)
            if (d < gap) {
                gap = d
                best = i
            }
        }
        return best
    }

    width: root.span
    height: Theme.h
    visible: root.opacity > 0.004

    Item {
        x: -Theme.wsBleed
        width: root.span + 2 * Theme.wsBleed
        height: parent.height
        clip: true

        Item {
            id: track
            x: Theme.wsBleed - root.scroll * root.pitch
            width: root.rendered * root.pitch
            height: parent.height

            Repeater {
                model: root.rendered

                Shape {
                    id: pip
                    preferredRendererType: Shape.CurveRenderer
                    required property int index
                    readonly property real weight: Math.max(0, 1 - Math.abs(pip.index - root.position))
                    readonly property real lead: Math.max(0, Math.min(1, pip.index - root.position))
                    readonly property real seen: pip.x - root.scroll * root.pitch + root.pipW / 2
                    readonly property real past: Math.max(0, -pip.seen) + Math.max(0, pip.seen - root.span)
                    readonly property real edge: Math.max(0, 1 - pip.past / (root.pitch / 2))
                    readonly property color base: root.filled[pip.index] ? root.liveInk : root.dimInk

                    x: root.reflow
                        ? pip.index * root.pitch + (root.act - root.pipW) * pip.lead
                        : pip.index * root.pitch + (root.act - root.pipW) / 2
                    y: (track.height - root.pipH) / 2
                    width: root.pipW
                    height: root.pipH
                    opacity: (1 - pip.weight) * pip.edge
                    transformOrigin: Item.TopLeft
                    transform: Scale { xScale: 1 / root.grid; yScale: 1 / root.grid }

                    ShapePath {
                        strokeWidth: -1
                        fillColor: pip.index === root.hot
                            ? Theme.mix(pip.base, root.activeInk, Theme.wsHotLift)
                            : pip.base

                        Behavior on fillColor {
                            ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                        }

                        PathSvg { path: root.pipPath }
                    }
                }
            }

            Shape {
                preferredRendererType: Shape.CurveRenderer
                x: root.position * root.pitch
                y: (track.height - root.actTall) / 2
                width: root.act
                height: root.actTall
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

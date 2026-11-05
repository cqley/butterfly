import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property int index: 0
    property int count: Theme.wsCount
    property int page: 0
    property var filled: []
    property bool live: true
    readonly property real position: slide.value

    property int shownPage: 0
    property int markIndex: 0
    property var shownFilled: []
    property int dir: 1
    property real travel: 0
    property real churn: 0

    readonly property bool vert: Theme.wsVertical
    readonly property int pipW: root.vert ? Theme.wsBarW : Theme.wsDot
    readonly property int pipH: root.vert ? Theme.wsBarH : Theme.wsDot
    readonly property int actW: Math.max(root.vert ? Theme.wsBarActiveW : Theme.wsActiveW, root.pipW)
    readonly property int actH: Math.max(root.vert ? Theme.wsBarActiveH : Theme.wsActiveH, root.pipH)
    readonly property int pitch: root.pipW + (root.vert ? Theme.wsBarGap : Theme.wsGap)
    readonly property int span: (root.count - 1) * root.pitch + root.actW

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
        swapRun.stop()
        root.churn = 0
        root.shownPage = root.page
        root.shownFilled = root.filled
        root.markIndex = root.index
        root.travel = 0
        slide.land(root.index)
    }

    function sync() {
        if (!root.live) {
            root.settle()
            return
        }
        if (swapRun.running)
            return
        if (root.page !== root.shownPage) {
            root.dir = root.page > root.shownPage ? 1 : -1
            swapRun.start()
            return
        }
        if (root.markIndex === root.index)
            return
        root.travel = Math.abs(root.index - slide.value)
        root.markIndex = root.index
    }

    onIndexChanged: gate.restart()
    onPageChanged: gate.restart()
    onFilledChanged: if (!swapRun.running) root.shownFilled = root.filled

    onLiveChanged: {
        hide.stop()
        if (root.live) {
            root.opacity = 1
            return
        }
        root.settle()
        hide.start()
    }

    Component.onCompleted: {
        root.opacity = root.live ? 1 : 0
        root.settle()
    }

    NumberAnimation {
        id: hide
        target: root
        property: "opacity"
        to: 0
        duration: Theme.fall
        easing.type: Theme.ease
    }

    Timer {
        id: gate
        interval: 0
        onTriggered: root.sync()
    }

    SequentialAnimation {
        id: swapRun

        NumberAnimation {
            target: root
            property: "churn"
            to: 1
            duration: Theme.wsSwap
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: {
                root.shownPage = root.page
                root.shownFilled = root.filled
                root.markIndex = root.index
                root.travel = 0
                slide.land(root.index)
                root.dir = -root.dir
            }
        }

        NumberAnimation {
            target: root
            property: "churn"
            to: 0
            duration: Theme.wsSwap
            easing.type: Easing.OutCubic
        }

        ScriptAction {
            script: gate.restart()
        }
    }

    Spring {
        id: slide
        target: root.markIndex
        response: Theme.wsResponse * (1 + Theme.wsSpread * Math.max(0, root.travel - 1))
        damping: Theme.wsDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    Item {
        id: track
        x: -root.dir * root.pitch * root.churn
        width: root.span
        height: parent.height
        opacity: 1 - root.churn

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
                    fillColor: root.shownFilled[pip.index] ? root.liveInk : root.dimInk

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

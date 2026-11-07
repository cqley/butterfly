import "../core"
import QtQuick

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
    property int hot: -1
    readonly property real position: slide.value

    property int markIndex: 0
    property bool viewVert: false
    property int viewCount: 1
    property real travel: 0

    readonly property int span: root.viewVert ? bars.span : dots.span
    readonly property bool hidden: reveal.opacity <= 0
    readonly property real style: styleMotion.value
    readonly property real dotsInk: 1 - root.ease(root.style / 0.6)
    readonly property real barsInk: root.ease((root.style - 0.4) / 0.6)

    function ease(x) {
        const c = Math.max(0, Math.min(1, x))
        return c * c * (3 - 2 * c)
    }

    // carousel
    readonly property int bias: Math.floor((root.viewCount - 1) / 2)
    readonly property int reachWant: Math.max(0, root.total - root.viewCount)
    property real reach: 0
    readonly property real limit: Math.max(root.reach, slide.value - (root.viewCount - 1))
    readonly property real scroll: Math.max(0, Math.min(root.limit, slide.value - root.bias))
    readonly property int rendered: Math.max(root.total, Math.ceil(slide.value) + 2)

    readonly property color dimInk: Theme.mix(Theme.bg, Theme.fg, Theme.wsDotDim)
    readonly property color liveInk: Theme.mix(Theme.bg, Theme.fg, Theme.wsDotLive)
    readonly property color activeInk: Theme.wsAccent ? Theme.accent : Theme.fg

    width: spanMotion.value
    height: Theme.h
    clip: true

    function settle() {
        reachRun.stop()
        root.reach = root.reachWant
        root.markIndex = root.index
        root.travel = 0
        slide.land(root.index)
        styleMotion.land(root.viewVert ? 1 : 0)
        spanMotion.land(root.span)
    }

    function slotAt(x) {
        const tr = root.viewVert ? bars : dots
        const p = root.mapToItem(tr, x, root.height / 2)
        return tr.slotAt(p.x)
    }

    function adopt() {
        if (!root.live && !root.hidden)
            return
        root.viewVert = root.vert
        root.viewCount = root.count
        if (root.hidden)
            root.settle()
    }

    function sync() {
        if (!root.live) {
            if (root.hidden)
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
    onLiveChanged: view.restart()
    onVertChanged: view.restart()
    onCountChanged: view.restart()
    onHiddenChanged: if (root.hidden) root.adopt()

    onReachWantChanged: {
        reachRun.stop()
        if (!root.live) {
            if (root.hidden)
                root.reach = root.reachWant
            return
        }
        reachRun.to = root.reachWant
        reachRun.start()
    }

    Component.onCompleted: {
        root.viewVert = root.vert
        root.viewCount = root.count
        root.settle()
    }

    Timer {
        id: view
        interval: 0
        onTriggered: root.adopt()
    }

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

    Spring {
        id: styleMotion
        target: root.viewVert ? 1 : 0
        response: Theme.idlePopResponse
        damping: Theme.idlePopDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    Spring {
        id: spanMotion
        target: root.span
        response: Theme.idlePopResponse
        damping: Theme.idlePopDamping
        epsilon: Theme.settleEps
    }

    Fade {
        id: reveal
        anchors.fill: parent
        shown: root.live

        Item {
            anchors.fill: parent
            opacity: (1 - root.layoutFade) * root.veil

            // dots
            WorkspaceTrack {
                id: dots
                x: (root.width - width) / 2
                opacity: root.dotsInk
                scale: root.width / width
                pipW: Theme.wsDot
                pipH: Theme.wsDot
                actW: Theme.wsActiveW
                actH: Theme.wsActiveH
                gap: Theme.wsGap
                reflow: true
                count: root.viewCount
                rendered: root.rendered
                position: slide.value
                scroll: root.scroll
                filled: root.filled
                dimInk: root.dimInk
                liveInk: root.liveInk
                activeInk: root.activeInk
                hot: root.hot
            }

            // bars
            WorkspaceTrack {
                id: bars
                x: (root.width - width) / 2
                opacity: root.barsInk
                scale: root.width / width
                pipW: Theme.wsBarW
                pipH: Theme.wsBarH
                actW: Theme.wsBarActiveW
                actH: Theme.wsBarActiveH
                gap: Theme.wsBarGap
                reflow: false
                count: root.viewCount
                rendered: root.rendered
                position: slide.value
                scroll: root.scroll
                filled: root.filled
                dimInk: root.dimInk
                liveInk: root.liveInk
                activeInk: root.activeInk
                hot: root.hot
            }
        }
    }
}

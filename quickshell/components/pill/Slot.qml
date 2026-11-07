import "../core"
import QtQuick

Item {
    id: root
    property bool shown: false
    property int size: Theme.micS
    property int contentWidth: size
    property real leadingGap: Theme.rowGap
    property real trailingGap: 0
    property int settledGap: Math.round(leadingGap)
    property int settledTrailingGap: Math.round(trailingGap)
    property bool pinEnd: false
    readonly property bool pinned: root.shown ? root.pinEnd : !root.pinEnd
    property int viewWidth: 0
    readonly property real contentNow: contentMotion.value
    readonly property real homeX: root.pinned
        ? root.width - root.trailingGap - root.contentNow
        : root.leadingGap
    property real veil: 1
    readonly property int targetWidth: shown ? settledGap + contentWidth + settledTrailingGap : 0
    readonly property real enter: enterMotion.value
    readonly property real exitRaw: Math.max(0, Math.min(1, (root.enter - Theme.slotExitAt) / (1 - Theme.slotExitAt)))
    readonly property real ink: root.shown ? root.enter : root.exitRaw * root.exitRaw * (3 - 2 * root.exitRaw)
    readonly property real contentX: holder.x
    readonly property bool settled: root.enter >= 1 && !contentMotion.moving
    default property alias content: holder.data

    width: (leadingGap + contentNow + trailingGap) * enter
    height: Theme.h
    visible: enter > 0
    clip: true

    function adopt() {
        if (!root.shown && root.enter > 0)
            return
        root.viewWidth = root.contentWidth
        if (root.enter <= 0)
            contentMotion.land(root.viewWidth)
    }

    onContentWidthChanged: view.restart()
    onShownChanged: view.restart()
    onVisibleChanged: if (!root.visible) root.adopt()

    Component.onCompleted: {
        root.viewWidth = root.contentWidth
        contentMotion.land(root.viewWidth)
    }

    Timer {
        id: view
        interval: 0
        onTriggered: root.adopt()
    }

    Spring {
        id: enterMotion
        target: root.shown ? 1 : 0
        response: Theme.idlePopResponse
        damping: Theme.idlePopDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    Spring {
        id: contentMotion
        target: root.viewWidth
        response: Theme.idlePopResponse
        damping: Theme.idlePopDamping
        epsilon: Theme.settleEps
    }

    Item {
        id: holder
        x: root.settled ? Math.round(root.homeX) : root.homeX
        y: Math.round((root.height - root.size) / 2)
        width: root.contentNow
        height: root.size
        transformOrigin: Item.Center
        scale: Theme.slotScale + (1 - Theme.slotScale) * root.enter
        opacity: root.ink * root.veil
    }
}

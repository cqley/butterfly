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
    readonly property real homeX: root.pinned
        ? root.width - root.trailingGap - root.contentWidth
        : root.leadingGap
    property real veil: 1
    readonly property int targetWidth: shown ? settledGap + contentWidth + settledTrailingGap : 0
    readonly property real enter: enterMotion.value
    readonly property real contentX: holder.x
    default property alias content: holder.data

    width: (leadingGap + contentWidth + trailingGap) * enter
    height: Theme.h
    visible: enter > 0
    clip: true

    Spring {
        id: enterMotion
        target: root.shown ? 1 : 0
        response: Theme.idlePopResponse
        damping: Theme.idlePopDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    Item {
        id: holder
        x: root.enter >= 1 ? Math.round(root.homeX) : root.homeX
        y: Math.round((root.height - root.size) / 2)
        width: root.contentWidth
        height: root.size
        transformOrigin: Item.Center
        scale: Theme.slotScale + (1 - Theme.slotScale) * root.enter
        opacity: root.enter * root.veil
    }
}

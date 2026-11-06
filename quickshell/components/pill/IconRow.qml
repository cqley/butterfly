import "../core"
import QtQuick

Item {
    id: root

    property var modules: []
    property bool clockEnd: false
    property real morphVeil: 1
    property real orphanVeil: 1

    width: row.width
    height: Theme.h

    readonly property real targetWidth: {
        let w = 0
        for (let i = 0; i < rowRepeater.count; i++) {
            const it = rowRepeater.itemAt(i)
            if (it)
                w += it.targetWidth
        }
        return w
    }

    function closerIndices(i) {
        const n = root.modules.length
        return root.clockEnd
            ? Array.from({ length: n - 1 - i }, (_, k) => i + 1 + k)
            : Array.from({ length: i }, (_, k) => k)
    }

    function item(i) {
        return rowRepeater.itemAt(i)
    }

    function slotCenter(key) {
        for (let i = 0; i < root.modules.length; i++) {
            if (root.modules[i].key !== key)
                continue
            const it = rowRepeater.itemAt(i)
            if (!it || !it.shown)
                return null
            return it.x + it.contentX + it.contentWidth / 2
        }
        return null
    }

    function leadGap(i, own) {
        const closer = root.closerIndices(i).map(root.item).filter(Boolean)
        const m = closer.length ? Math.max(...closer.map(it => it.enter)) : 0
        return own + (Theme.rowGap - own) * m
    }

    function settledLeadGap(i, own) {
        const closer = root.closerIndices(i).map(root.item).filter(Boolean)
        return closer.some(it => it.shown) ? Theme.rowGap : own
    }

    Row {
        id: row
        spacing: 0
        height: parent.height

        Repeater {
            id: rowRepeater
            model: root.modules

            Slot {
                id: slotRoot
                required property int index
                required property var modelData
                readonly property real ownGap: modelData.clockGapFn ? modelData.clockGapFn() : Theme.clockGap
                pinEnd: !root.clockEnd
                veil: modelData.morphsFn && modelData.morphsFn() ? root.morphVeil : root.orphanVeil
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.moduleOffsetY + (modelData.offsetYFn ? modelData.offsetYFn() : 0)
                anchors.alignWhenCentered: Theme.idleAlignWhenCentered
                size: modelData.sizeFn ? modelData.sizeFn() : Theme.h
                contentWidth: modelData.contentWidthFn ? modelData.contentWidthFn() : size
                shown: modelData.shownFn()
                leadingGap: root.clockEnd ? 0 : root.leadGap(index, slotRoot.ownGap)
                trailingGap: root.clockEnd ? root.leadGap(index, slotRoot.ownGap) : 0
                settledGap: root.clockEnd ? 0 : root.settledLeadGap(index, slotRoot.ownGap)
                settledTrailingGap: root.clockEnd ? root.settledLeadGap(index, slotRoot.ownGap) : 0

                transform: Translate {
                    x: modelData.offsetXFn ? modelData.offsetXFn() : 0
                }

                Loader {
                    anchors.fill: parent
                    sourceComponent: modelData.component
                }
            }
        }
    }
}

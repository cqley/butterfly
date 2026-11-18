import "../core"
import QtQuick

Tiles {
    id: root
    property string anchor: ""
    readonly property var items: Record.items

    n: items.length
    pad: Theme.pwPad
    width: Math.max(0, n * Theme.pwW + Math.max(0, n - 1) * Theme.pwGap)
    height: Theme.pwH
    owner: Record
    onFresh: {
        reset()
        remember()
    }

    function key(i) {
        const it = items[i]
        return it ? it.kind + ":" + it.value : ""
    }

    function ord(i) {
        let k = 0
        for (let j = 0; j <= i && j < n; j++)
            if (items[j].kind === "monitor")
                k++
        return k
    }

    function run(i) {
        if (i < 0 || i >= n)
            return
        Record.pick(items[i])
    }

    function remember() {
        anchor = key(sel)
    }

    function resync() {
        for (let i = 0; i < n; i++) {
            if (key(i) === anchor) {
                snap = true
                sel = i
                snap = false
                return
            }
        }
        snap = true
        sel = Math.min(sel, Math.max(0, n - 1))
        snap = false
        remember()
    }

    Connections {
        target: Record
        function onItemsChanged() {
            root.resync()
        }
    }

    Connections {
        target: root
        function onSelChanged() { root.remember() }
    }

    keys: ({
        cancel: () => Record.open = false,
        accept: () => root.run(root.sel)
    })

    Row {
        spacing: Theme.pwGap

        Repeater {
            model: root.items

            Tile {
                id: tile
                required property var modelData
                required property int index
                readonly property bool isStop: modelData.kind === "stop"
                readonly property bool isMonitor: modelData.kind === "monitor"

                pick: root
                at: index
                tone: isStop ? Theme.red : Theme.accent
                rest: isStop ? Theme.red : Theme.fg
                path: isMonitor ? Theme.monitorPath : isStop ? Theme.recStopPath : Theme.recPortalPath
                onClicked: root.run(index)

                Txt {
                    x: Math.round(tile.glyph.x + (tile.glyph.width - width) / 2)
                    y: Math.round(tile.glyph.y + Theme.monitorNumAxis - height / 2) + Theme.monitorNumY
                    visible: tile.isMonitor
                    text: root.ord(tile.index)
                    font.pixelSize: Theme.monitorNumPx
                    font.weight: Font.DemiBold
                    color: tile.ink
                }

                Rectangle {
                    x: tile.width - Theme.recordBadge - Theme.recordBadgeInset
                    y: Theme.recordBadgeInset
                    width: Theme.recordBadge
                    height: Theme.recordBadge
                    radius: height / 2
                    color: Theme.red
                    antialiasing: true
                    visible: !tile.isStop && Record.active && Record.targetLabel === tile.modelData.label
                }
            }
        }
    }
}

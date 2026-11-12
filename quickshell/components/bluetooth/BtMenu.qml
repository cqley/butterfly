import "../core"
import QtQuick
import Quickshell

Pick {
    id: root
    readonly property var items: Bt.items

    n: items.length
    rows: Theme.btRows
    pad: Theme.btPad
    width: Theme.btW - 2 * Theme.btPad
    height: col.height
    focus: shown

    property string selAddr: ""
    readonly property string selKey: items[sel] ? String(items[sel].address) : ""

    function run() {
        if (n)
            Bt.pick(items[sel])
    }

    function fresh() {
        reset()
        selAddr = ""
    }

    function remember() {
        if (items && items[sel])
            selAddr = items[sel].address
    }

    function syncSel() {
        if (!n) {
            selAddr = ""
            return
        }
        if (selAddr !== "") {
            for (let i = 0; i < n; i++) {
                if (items[i] && items[i].address === selAddr) {
                    if (i !== sel) {
                        hold()
                        sel = i
                    }
                    return
                }
            }
        }
        const i = Math.max(0, Math.min(n - 1, sel))
        if (i !== sel) {
            hold()
            sel = i
        }
        remember()
    }

    onVisibleChanged: {
        if (visible)
            forceActiveFocus()
        else
            fresh()
    }

    Connections {
        target: Bt
        function onOpenChanged() {
            if (!Bt.open)
                return
            root.fresh()
            root.forceActiveFocus()
        }
        function onItemsChanged() { root.syncSel() }
    }

    Connections {
        target: root
        function onSelChanged() { root.remember() }
    }

    Keys.onPressed: e => {
        const k = e.key
        if (k === Qt.Key_Escape) Bt.open = false
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) run()
        else if (!nav(e)) return
        e.accepted = true
    }

    QtObject {
        id: pulse
        property real val: 1
        property bool running: Bt.busy || Bt.powering
    }

    SequentialAnimation {
        running: pulse.running
        loops: Animation.Infinite

        NumberAnimation {
            target: pulse
            property: "val"
            from: 1
            to: 0
            duration: Theme.blink
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: pulse
            property: "val"
            from: 0
            to: 1
            duration: Theme.blink
            easing.type: Easing.InOutSine
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.listGap

        PickList {
            id: list
            pick: root
            rowH: Theme.btRowH
            values: root.items
            key: "address"
            visible: Bt.enabled && root.n > 0
            marked: true
            mark: Bt.displayName(root.items[root.sel])

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool on: !!modelData && !!modelData.connected
                readonly property string status: Bt.statusOf(modelData)
                readonly property bool busy: status !== ""
                readonly property bool selected: root.selKey !== "" && !!modelData && root.selKey === modelData.address
                readonly property bool onscreen: row.index >= root.start && row.index < root.start + root.rows

                y: row.index * Theme.btRowH
                width: list.width
                height: Theme.btRowH

                Txt {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.rowX
                    anchors.right: meta.left
                    anchors.rightMargin: Theme.rowGap
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Theme.rowTextY
                    text: Bt.displayName(row.modelData)
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fsL
                    font.weight: row.on ? Font.DemiBold : Font.Normal
                    color: row.on || row.selected ? Theme.accent : Theme.fg

                    Behavior on color {
                        ColorAnimation {
                            duration: root.snap ? 0 : Theme.glide
                            easing.type: Theme.ease
                        }
                    }
                }

                Row {
                    id: meta
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.btMetaR
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.rowGap

                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData && row.modelData.batteryAvailable ? Math.round(row.modelData.battery * 100) + "%" : ""
                        font.pixelSize: Theme.fsS
                        color: row.on ? Theme.accent : Theme.fg
                        opacity: row.busy ? Theme.dimHint : Theme.dimMuted
                        visible: text !== ""

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.glide
                                easing.type: Theme.ease
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.glide
                                easing.type: Theme.ease
                            }
                        }
                    }

                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.status
                        font.pixelSize: Theme.fsS
                        color: Theme.accent
                        opacity: row.busy ? Theme.dimMid + (1 - Theme.dimMid) * pulse.val : 0
                        visible: text !== ""
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: row.onscreen
                    hoverEnabled: row.onscreen
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: m => root.aim(mapToItem(null, m.x, m.y), row.index)
                    onClicked: {
                        root.sel = row.index
                        root.run()
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: empty.implicitHeight + Theme.emptyPad
            visible: Bt.enabled && root.n === 0

            Txt {
                id: empty
                anchors.centerIn: parent
                text: "no devices"
                opacity: Theme.dimEmpty
            }
        }

        Item {
            width: parent.width
            height: offline.implicitHeight + Theme.emptyPad
            visible: !Bt.enabled

            Txt {
                id: offline
                anchors.centerIn: parent
                text: Bt.title
                opacity: Theme.dimEmpty
            }
        }
    }
}

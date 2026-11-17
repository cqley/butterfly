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
    owner: Bt
    entries: items
    identity: it => it.address
    onFresh: {
        reset()
        anchor = ""
    }

    readonly property string selKey: items[sel] ? String(items[sel].address) : ""

    function run() {
        if (n)
            Bt.pick(items[sel])
    }

    Connections {
        target: Bt
        function onItemsChanged() { root.syncSel() }
    }

    keys: ({
        cancel: () => Bt.open = false,
        accept: () => root.run()
    })

    Pulse {
        id: pulse
        running: Bt.busy || Bt.powering
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

                PickArea {
                    pick: root
                    at: row.index
                    live: row.onscreen
                    onClicked: {
                        root.sel = row.index
                        root.run()
                    }
                }
            }
        }

        Empty {
            text: "no devices"
            visible: Bt.enabled && root.n === 0
        }

        Empty {
            text: Bt.title
            visible: !Bt.enabled
        }
    }
}

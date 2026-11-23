import "../core"
import QtQuick
import Quickshell

Pick {
    id: root
    readonly property var items: Bt.items
    property string doom: ""

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
        doom = ""
    }

    readonly property string selKey: items[sel] ? String(items[sel].address) : ""

    readonly property var current: items[sel] || null

    onSelChanged: doom = ""

    function arm(d) {
        if (!d || !d.paired || Bt.busy)
            return false
        if (doom === d.address) {
            doom = ""
            Bt.forget(d)
        } else
            doom = d.address
        return true
    }

    function run() {
        if (!n)
            return
        if (doom !== "" && current && doom === current.address)
            arm(current)
        else {
            doom = ""
            Bt.pick(current)
        }
    }

    Connections {
        target: Bt
        function onItemsChanged() { root.syncSel() }
    }

    keys: ({
        cancel: () => {
            if (root.doom !== "")
                root.doom = ""
            else
                Bt.open = false
        },
        accept: () => root.run(),
        delete: () => root.arm(root.current)
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
            alarm: root.doom !== ""

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool on: !!modelData && !!modelData.connected
                readonly property string status: Bt.statusOf(modelData)
                readonly property bool doomed: !!modelData && root.doom === modelData.address
                readonly property bool failing: !!modelData && Bt.failed === modelData.address
                readonly property bool busy: status !== "" && !failing
                property string held: ""
                property bool heldRed: false
                onStatusChanged: {
                    if (row.status === "")
                        return
                    row.held = row.status
                    row.heldRed = Bt.failed === row.modelData.address
                }
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
                    font.weight: row.on || row.busy ? Font.DemiBold : Font.Normal
                    color: row.doomed ? Theme.red : row.on || row.busy || row.selected ? Theme.accent : Theme.fg

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

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: row.status !== "" ? note.implicitWidth : 0
                        height: note.implicitHeight
                        visible: width > 0

                        Behavior on width {
                            NumberAnimation {
                                duration: root.snap ? 0 : Theme.glide
                                easing.type: Theme.ease
                            }
                        }

                        Item {
                            anchors.fill: parent
                            opacity: row.status !== "" ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: root.snap ? 0 : Theme.glide
                                    easing.type: Theme.ease
                                }
                            }

                            Txt {
                                id: note
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.held
                                font.pixelSize: Theme.fsS
                                color: row.heldRed ? Theme.red : Theme.accent
                                opacity: row.heldRed ? 1 : Theme.dimMid + (1 - Theme.dimMid) * pulse.val
                            }
                        }
                    }
                }

                PickArea {
                    pick: root
                    at: row.index
                    live: row.onscreen
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: e => {
                        root.sel = row.index
                        if (e.button === Qt.RightButton)
                            root.arm(row.modelData)
                        else
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

import "../core"
import QtQuick
import Quickshell

Pick {
    id: root
    readonly property var items: Bt.items

    n: items.length
    rows: Theme.netRows
    width: Theme.btW - 2 * Theme.netPad
    height: col.height
    focus: shown

    property string selAddr: ""

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

    Column {
        id: col
        width: parent.width
        spacing: Theme.listGap

        Item {
            width: parent.width
            height: Theme.netRowH

            Txt {
                anchors.left: parent.left
                anchors.leftMargin: Theme.netTitleX
                anchors.verticalCenter: parent.verticalCenter
                text: Bt.title
                font.weight: Font.DemiBold
                color: Bt.busy || Bt.powering ? Theme.accent : !Bt.enabled ? Theme.red : Theme.fg
                opacity: pulse.running ? Theme.dimMuted + (1 - Theme.dimMuted) * pulse.val : 1

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.glide
                        easing.type: Theme.ease
                    }
                }
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

            Rectangle {
                id: toggle
                readonly property real gap: (height - Theme.netKnob) / 2
                anchors.right: parent.right
                anchors.rightMargin: Theme.netToggleInset
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.netToggleW
                height: Theme.netToggleH
                radius: height / 2
                color: Bt.enabled ? Theme.accent : Theme.tile
                opacity: !Bt.available || Bt.blocked || Bt.busy || Bt.powering ? Theme.dimMid : 1
                transformOrigin: Item.Center
                scale: toggleArea.pressed ? Theme.feedbackPressScale : toggleArea.containsMouse ? Theme.feedbackHoverScale : 1
                antialiasing: true

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

                Rectangle {
                    x: Bt.enabled ? toggle.width - width - toggle.gap : toggle.gap
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.netKnob
                    height: Theme.netKnob
                    radius: width / 2
                    color: Theme.fg
                    antialiasing: true

                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.glide
                            easing.type: Theme.ease
                        }
                    }
                }

                MouseArea {
                    id: toggleArea
                    anchors.fill: parent
                    enabled: Bt.available && !Bt.blocked && !Bt.busy && !Bt.powering
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Bt.toggleAdapter()
                }
            }
        }

        Item {
            width: parent.width
            height: Math.min(root.n, Theme.netRows) * Theme.netRowH
            clip: true
            visible: Bt.enabled && root.n > 0

            ScriptModel {
                id: btModel
                values: root.items
                objectProp: "address"
            }

            Item {
                id: list
                width: parent.width
                height: root.n * Theme.netRowH
                y: -root.start * Theme.netRowH

                Behavior on y {
                    NumberAnimation {
                        duration: root.snap ? 0 : root.dur
                        easing.type: Theme.ease
                    }
                }

                Rectangle {
                    x: Theme.selInset
                    y: root.sel * Theme.netRowH + Theme.selGap / 2
                    width: list.width - Theme.selInset * 2
                    height: Theme.netRowH - Theme.selGap
                    radius: height / 2
                    color: Theme.selFill
                    border.width: Theme.surfaceBorderWidth
                    border.color: Theme.surfaceBorder
                    antialiasing: true

                    Mark {
                        label: Bt.displayName(root.items[root.sel])
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: root.snap ? 0 : root.dur
                            easing.type: Theme.ease
                        }
                    }
                }

                Repeater {
                    model: btModel

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool on: !!modelData && !!modelData.connected
                        readonly property string status: Bt.statusOf(modelData)
                        readonly property bool busy: status !== ""
                        readonly property bool selected: root.sel === row.index

                        y: row.index * Theme.netRowH
                        width: list.width
                        height: Theme.netRowH

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
                                    duration: Theme.glide
                                    easing.type: Theme.ease
                                }
                            }
                        }

                        Row {
                            id: meta
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.netMetaR
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
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: m => root.aim(mapToItem(null, m.x, m.y), row.index)
                            onClicked: {
                                root.sel = row.index
                                root.run()
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: empty.implicitHeight + Theme.netEmptyPad
            visible: Bt.enabled && root.n === 0

            Txt {
                id: empty
                anchors.centerIn: parent
                text: "no devices"
                opacity: Theme.dimEmpty
            }
        }
    }
}

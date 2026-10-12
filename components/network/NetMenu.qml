import "../core"
import QtQuick
import Quickshell

Pick {
    id: root
    readonly property var items: Net.list
    readonly property bool ask: Net.asking !== ""

    n: items ? items.length : 0
    rows: Theme.netRows
    width: Theme.netW - 2 * Theme.netPad
    height: col.height
    focus: shown

    function fresh() {
        reset()
        pass.text = ""
    }

    function run() {
        if (ask) {
            Net.submitPsk(pass.text)
            return
        }
        if (n && !Net.busy)
            Net.pick(items[sel])
    }

    function statusOf(item) {
        if (!item)
            return ""
        if (Net.pending === item.ssid && Net.phase !== "")
            return Net.phase
        return item.active ? "connected" : ""
    }

    onVisibleChanged: {
        if (visible)
            forceActiveFocus()
        else
            fresh()
    }

    onAskChanged: {
        if (ask) {
            pass.text = ""
            pass.forceActiveFocus()
        } else if (visible) {
            forceActiveFocus()
        }
    }

    Connections {
        target: Net
        function onOpenChanged() {
            if (!Net.open)
                return
            root.fresh()
            root.forceActiveFocus()
        }
        function onListChanged() {
            if (root.sel >= root.n)
                root.sel = Math.max(0, root.n - 1)
        }
        function onPendingChanged() {
            if (Net.pending === "")
                return
            for (let i = 0; i < root.n; i++) {
                if (root.items[i] && root.items[i].ssid === Net.pending) {
                    root.sel = i
                    break
                }
            }
        }
    }

    Keys.onPressed: e => {
        const k = e.key
        if (k === Qt.Key_Escape) {
            if (ask || Net.busy)
                Net.cancelAsk()
            else
                Net.open = false
        } else if (ask)
            return
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
            run()
        else if (!nav(e))
            return
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
                text: Net.title
                font.weight: Font.DemiBold
                color: !Net.enabled ? Theme.red : Net.phase !== "" ? Theme.accent : Theme.fg
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
                property bool running: Net.phase === "connecting" || Net.phase === "disconnecting"
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
                color: Net.enabled ? Theme.accent : Theme.tile
                opacity: Net.busy ? Theme.dimMid : 1
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
                    x: Net.enabled ? toggle.width - width - toggle.gap : toggle.gap
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
                    enabled: !Net.busy
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Net.toggleWifi()
                }
            }
        }

        Rule { visible: Net.enabled }

        Item {
            width: parent.width
            height: list.height
            visible: Net.enabled && root.n > 0

            ListView {
                id: list
                width: parent.width
                height: Math.min(root.n, Theme.netRows) * Theme.netRowH
                clip: true
                interactive: false
                ScriptModel {
                    id: netModel
                    values: root.items
                    objectProp: "ssid"
                }

                model: netModel
                cacheBuffer: Theme.netRowH * Theme.netRows * 2
                reuseItems: true
                contentY: root.start * Theme.netRowH
                highlightFollowsCurrentItem: false

                Behavior on contentY {
                    enabled: !root.snap
                    NumberAnimation {
                        duration: root.dur
                        easing.type: Theme.ease
                    }
                }

                highlight: Hi {
                    pick: root
                    row: Theme.netRowH
                    insetX: Theme.netFocusInset
                    insetY: Theme.netFocusInsetY
                    markX: Theme.netFocusMarkX
                    markW: Theme.netFocusMarkW
                    markHeight: Theme.netFocusMarkH
                    fill: Theme.netFocusFill
                    width: list.width - Theme.netFocusInset * 2
                    visible: !root.ask
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool on: !!modelData && !!modelData.active
                    readonly property bool aimed: !!modelData && Net.pending === modelData.ssid
                    readonly property bool busy: aimed && Net.phase !== ""
                    readonly property string status: root.statusOf(modelData)
                    readonly property real sig: modelData ? modelData.signal : 0
                    readonly property bool locked: !!modelData && !!modelData.locked
                    readonly property bool selected: root.sel === row.index

                    width: list.width
                    height: Theme.netRowH
                    opacity: root.ask && Net.asking !== (modelData ? modelData.ssid : "") ? Theme.dimHint : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.glide
                            easing.type: Theme.ease
                        }
                    }

                    Txt {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.rowX
                        anchors.right: meta.left
                        anchors.rightMargin: Theme.rowGap
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData ? row.modelData.ssid : ""
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fsL
                        font.weight: row.on || row.aimed || row.selected ? Font.DemiBold : Font.Normal
                        color: row.on || row.aimed || row.selected ? Theme.accent : Theme.fg

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
                            text: row.status
                            font.pixelSize: Theme.fsS
                            color: Theme.accent
                            opacity: row.busy ? Theme.dimMid + (1 - Theme.dimMid) * pulse.val : row.status === "" ? 0 : Theme.dimMuted
                            visible: text !== ""

                            Behavior on opacity {
                                enabled: row.status === "connected"
                                NumberAnimation {
                                    duration: Theme.glide
                                    easing.type: Theme.ease
                                }
                            }
                        }

                        Lock {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.locked && row.status === ""
                            opacity: Theme.dimMuted
                        }

                        Sig {
                            anchors.verticalCenter: parent.verticalCenter
                            level: Math.round(row.sig * Theme.sigBars)
                            opacity: row.busy ? Theme.dimHint : 1

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Theme.glide
                                    easing.type: Theme.ease
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: m => {
                            if (!root.ask)
                                root.aim(mapToItem(null, m.x, m.y), row.index)
                        }
                        onClicked: {
                            if (root.ask)
                                Net.cancelAsk()
                            root.sel = row.index
                            root.run()
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: empty.implicitHeight + Theme.netEmptyPad
            visible: Net.enabled && root.n === 0

            Txt {
                id: empty
                anchors.centerIn: parent
                text: "no networks"
                opacity: Theme.dimEmpty
            }
        }

        Column {
            width: parent.width
            spacing: Theme.listGap
            visible: root.ask

            Rule {}

            Txt {
                text: "password for " + Net.asking
                font.pixelSize: Theme.fsS
                opacity: Theme.dimMuted
            }

            Rectangle {
                width: parent.width
                height: Theme.netFieldH
                radius: height / 2
                color: Theme.chip
                border.color: Theme.accent
                border.width: pass.activeFocus ? Theme.feedbackFocusBorder : 0
                antialiasing: true

                Behavior on border.width { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }

                TextInput {
                    id: pass
                    anchors.fill: parent
                    anchors.leftMargin: Theme.rowR
                    anchors.rightMargin: Theme.rowR
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.bg
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    selectByMouse: true
                    font.family: Theme.font
                    font.pixelSize: Theme.fsL
                    clip: true

                    Keys.onPressed: e => {
                        const k = e.key
                        if (k === Qt.Key_Escape) {
                            Net.cancelAsk()
                            root.forceActiveFocus()
                            e.accepted = true
                        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                            root.run()
                            e.accepted = true
                        }
                    }
                }

                Txt {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.rowR
                    anchors.verticalCenter: parent.verticalCenter
                    text: "password"
                    opacity: Theme.dimHint
                    font.pixelSize: Theme.fsL
                    visible: pass.text === ""
                }
            }
        }

        Item {
            width: parent.width
            height: err.implicitHeight
            visible: Net.error !== ""

            Txt {
                id: err
                anchors.horizontalCenter: parent.horizontalCenter
                text: Net.error
                color: Theme.red
                font.pixelSize: Theme.fsS
            }
        }
    }

    Wheel {
        anchors.fill: parent
        enabled: !root.ask
        onStep: n => root.move(n, false)
    }
}

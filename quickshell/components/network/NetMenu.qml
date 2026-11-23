import "../core"
import QtQuick
import Quickshell

Pick {
    id: root
    readonly property var other: ({ ssid: "", hidden: true, signal: 0, active: false, locked: false, security: "" })
    readonly property var items: Net.available && Net.enabled ? Net.list.concat([root.other]) : Net.list
    readonly property bool ask: Net.asked
    property string doom: ""
    property string lastIdentity: ""
    property var held: []

    n: items ? items.length : 0
    rows: Theme.netRows
    pad: Theme.netPad
    width: Theme.netW - 2 * Theme.netPad
    height: col.height
    focus: shown
    owner: Net
    entries: items
    identity: it => it.ssid
    onFresh: {
        reset()
        anchor = ""
        doom = ""
    }

    readonly property var current: items && items[sel] ? items[sel] : null
    readonly property string selKey: current ? String(current.ssid) : ""

    onSelChanged: doom = ""

    function label(item) {
        return !item ? "" : item.hidden ? "hidden network…" : item.ssid
    }

    function connecting(item) {
        return !!item && !item.hidden && Net.phase === "connecting" && Net.pending === item.ssid
    }

    function forgettable(item) {
        return !!item && !item.hidden && Net.known(item.ssid)
    }

    function values() {
        const v = {}
        for (let i = 0; i < prompts.count; i++) {
            const f = prompts.itemAt(i)
            if (f)
                v[f.name] = f.text
        }
        return v
    }

    function focusField(i) {
        const f = prompts.itemAt(Math.max(0, Math.min(prompts.count - 1, i)))
        if (f)
            f.take()
    }

    function firstEmpty() {
        for (let i = 0; i < prompts.count; i++) {
            const f = prompts.itemAt(i)
            if (f && (f.text === "" || f.name === "password"))
                return i
        }
        return 0
    }

    function submit(from) {
        const v = values()
        if (from < prompts.count - 1 && prompts.itemAt(from + 1).text === "") {
            focusField(from + 1)
            return
        }
        if (v.identity !== undefined)
            root.lastIdentity = String(v.identity).trim()
        if (!Net.submit(v))
            focusField(firstEmpty())
    }

    function arm(item) {
        if (!forgettable(item) || Net.busy)
            return false
        if (doom === item.ssid) {
            doom = ""
            Net.forget(item.ssid)
        } else
            doom = item.ssid
        return true
    }

    function run() {
        if (ask || !n)
            return
        const item = current
        if (doom !== "" && item && doom === item.ssid) {
            arm(item)
            return
        }
        doom = ""
        if (connecting(item)) {
            Net.cancel()
            return
        }
        if (!Net.busy)
            Net.pick(item)
    }

    function statusOf(item) {
        if (!item || item.hidden)
            return ""
        if (Net.pending === item.ssid && Net.phase !== "")
            return Net.phase + "…"
        return ""
    }

    onAskChanged: {
        if (ask) {
            doom = ""
            Qt.callLater(() => {
                for (let i = 0; i < prompts.count; i++)
                    prompts.itemAt(i).fill()
                root.focusField(root.firstEmpty())
            })
        } else if (visible) {
            forceActiveFocus()
        }
    }

    Connections {
        target: Net
        function onListChanged() { root.syncSel() }
        function onFieldsChanged() {
            if (Net.fields.length)
                root.held = Net.fields
        }
    }

    frozen: ask
    keys: ({
        cancel: () => {
            if (root.doom !== "")
                root.doom = ""
            else if (Net.phase === "connecting")
                Net.cancel()
            else if (root.ask)
                Net.idle()
            else
                Net.open = false
        },
        accept: () => root.run(),
        delete: () => root.arm(root.current)
    })

    Pulse {
        id: pulse
        running: Net.busy
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.listGap

        Empty {
            text: "no networks"
            visible: Net.available && Net.enabled && Net.list.length === 0
        }

        PickList {
            id: list
            pick: root
            rowH: Theme.netRowH
            values: root.items
            key: "ssid"
            visible: Net.available && Net.enabled && root.n > 0
            highlightShown: !root.ask
            marked: true
            mark: root.label(root.current)
            alarm: root.doom !== ""

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool hidden: !!modelData && !!modelData.hidden
                readonly property bool on: !!modelData && !!modelData.active
                readonly property bool aimed: !!modelData && !hidden && Net.pending === modelData.ssid
                readonly property bool busy: aimed && Net.phase !== ""
                readonly property bool doomed: !!modelData && !hidden && root.doom === modelData.ssid
                readonly property string status: root.statusOf(modelData)
                readonly property real sig: modelData ? modelData.signal : 0
                readonly property bool locked: !!modelData && !!modelData.locked
                readonly property bool lockShown: row.locked && !row.on && !row.busy
                property string held: ""
                onStatusChanged: if (row.status !== "") row.held = row.status
                readonly property bool asked: root.ask && !!modelData && (hidden ? Net.kind === "hidden" : Net.kind !== "hidden" && Net.target === modelData.ssid)
                readonly property bool selected: !root.ask && root.selKey !== "" && !!modelData && root.selKey === modelData.ssid || !root.ask && hidden && !!root.current && !!root.current.hidden
                readonly property bool onscreen: row.index >= root.start && row.index < root.start + root.rows

                y: row.index * Theme.netRowH
                width: list.width
                height: Theme.netRowH
                opacity: root.ask && !row.asked ? Theme.dimHint : 1

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
                    anchors.verticalCenterOffset: Theme.rowTextY
                    text: root.label(row.modelData)
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fsL
                    font.weight: row.on || row.aimed ? Font.DemiBold : Font.Normal
                    color: row.doomed ? Theme.red : row.on || row.aimed || row.selected || row.asked ? Theme.accent : Theme.fg
                    opacity: row.hidden && !row.selected && !row.asked ? Theme.dimMuted : 1

                    Behavior on color {
                        ColorAnimation {
                            duration: root.snap ? 0 : Theme.glide
                            easing.type: Theme.ease
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: root.snap ? 0 : Theme.glide
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
                    visible: !row.hidden

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: row.busy ? note.implicitWidth : row.lockShown ? lock.width : 0
                        height: Math.max(note.implicitHeight, lock.height)
                        visible: width > 0

                        Behavior on width {
                            NumberAnimation {
                                duration: root.snap ? 0 : Theme.glide
                                easing.type: Theme.ease
                            }
                        }

                        Item {
                            anchors.fill: parent
                            opacity: row.busy ? 1 : 0

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
                                color: Theme.accent
                                opacity: Theme.dimMid + (1 - Theme.dimMid) * pulse.val
                            }
                        }

                        Lock {
                            id: lock
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: row.lockShown ? Theme.dimMuted : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: root.snap ? 0 : Theme.glide
                                    easing.type: Theme.ease
                                }
                            }
                        }
                    }

                    Sig {
                        anchors.verticalCenter: parent.verticalCenter
                        level: Math.round(row.sig * Theme.sigBars)
                        tint: row.doomed ? Theme.red : row.on || row.aimed ? Theme.accent : Theme.fg
                        opacity: row.busy ? Theme.dimHint : 1

                        Behavior on tint {
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
                }

                PickArea {
                    pick: root
                    at: row.index
                    live: row.onscreen
                    aims: !root.ask
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: e => {
                        if (root.ask) {
                            const same = row.asked
                            Net.idle()
                            if (same)
                                return
                        }
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
            text: Net.title
            visible: !root.ask && !(Net.available && Net.enabled)
        }

        Fade {
            id: prompt
            width: parent.width
            height: rule.height + Theme.netPromptGap + fields.height
            shown: root.ask

            transform: Translate {
                y: -Theme.netPromptRise * (1 - prompt.opacity)
            }

            Rectangle {
                id: rule
                x: Theme.rowR
                width: parent.width - 2 * Theme.rowR
                height: Theme.surfaceBorderWidth
                color: Theme.surfaceBorder
            }

            Column {
                id: fields
                y: rule.height + Theme.netPromptGap
                width: parent.width
                spacing: Theme.netFieldGap

                Repeater {
                    id: prompts
                    model: root.held

                    delegate: Rectangle {
                        id: field
                        required property string modelData
                        required property int index
                        readonly property string name: modelData
                        property alias text: input.text

                        function take() {
                            input.forceActiveFocus()
                            input.selectAll()
                        }

                        width: fields.width
                        height: Theme.netFieldH
                        radius: Theme.corner(height / 2)
                        color: Theme.chip
                        border.color: Theme.accent
                        border.width: input.activeFocus ? Theme.feedbackFocusBorder : 0
                        border.pixelAligned: false
                        antialiasing: true

                        Behavior on border.width { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }

                        function fill() {
                            input.text = field.name === "ssid" ? Net.target : field.name === "identity" ? root.lastIdentity : ""
                        }

                        Component.onCompleted: fill()

                        TextInput {
                            id: input
                            anchors.fill: parent
                            anchors.leftMargin: Theme.rowR
                            anchors.rightMargin: Theme.rowR
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.bg
                            echoMode: field.name === "password" ? TextInput.Password : TextInput.Normal
                            passwordCharacter: Theme.passChar
                            selectByMouse: true
                            font.family: Theme.font
                            font.pixelSize: Theme.fsL
                            clip: true

                            Keys.onPressed: e => Binds.run(e, {
                                cancel: () => {
                                    Net.idle()
                                    root.forceActiveFocus()
                                },
                                accept: () => root.submit(field.index),
                                next: () => root.focusField(field.index + 1),
                                prev: () => root.focusField(field.index - 1)
                            }, "insert")
                        }

                        Txt {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.rowR
                            anchors.verticalCenter: parent.verticalCenter
                            text: field.name === "ssid" ? "name" : field.name === "identity" ? "username" : "password"
                            opacity: Theme.dimHint
                            font.pixelSize: Theme.fsL
                            visible: input.text === ""
                        }
                    }
                }
            }
        }

        Fade {
            id: oops
            property string held: ""
            width: parent.width
            height: err.implicitHeight
            shown: Net.error !== ""

            Connections {
                target: Net
                function onErrorChanged() {
                    if (Net.error !== "")
                        oops.held = Net.error
                }
            }

            Txt {
                id: err
                anchors.horizontalCenter: parent.horizontalCenter
                text: oops.held
                color: Theme.red
                font.pixelSize: Theme.fsS
            }
        }
    }
}

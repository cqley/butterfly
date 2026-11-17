import "../core"
import QtQuick
import Quickshell

Pick {
    id: root
    readonly property var items: Net.list
    readonly property bool ask: Net.asking !== ""

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
        pass.text = ""
    }

    readonly property string selKey: items && items[sel] ? String(items[sel].ssid) : ""

    function connecting(item) {
        return !!item && Net.phase === "connecting" && Net.pending === item.ssid
    }

    function run() {
        if (ask) {
            Net.submitPsk(pass.text)
            return
        }
        if (!n)
            return
        if (connecting(items[sel])) {
            Net.stopConnect()
            return
        }
        if (!Net.busy)
            Net.pick(items[sel])
    }

    function statusOf(item) {
        if (!item)
            return ""
        if (Net.pending === item.ssid && Net.phase !== "")
            return Net.phase
        return ""
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
        function onListChanged() { root.syncSel() }
    }

    frozen: ask
    keys: ({
        cancel: () => {
            if (Net.phase === "connecting")
                Net.stopConnect()
            else if (root.ask)
                Net.cancelAsk()
            else
                Net.open = false
        },
        accept: () => {
            if (!root.ask)
                root.run()
        }
    })

    Pulse {
        id: pulse
        running: Net.phase === "connecting" || Net.phase === "disconnecting"
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.listGap

        PickList {
            id: list
            pick: root
            rowH: Theme.netRowH
            values: root.items
            key: "ssid"
            visible: Net.available && Net.enabled && root.n > 0
            highlightShown: !root.ask
            marked: true
            mark: root.items && root.items[root.sel] ? root.items[root.sel].ssid : ""

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
                readonly property bool selected: !root.ask && root.selKey !== "" && !!modelData && root.selKey === modelData.ssid
                readonly property bool onscreen: row.index >= root.start && row.index < root.start + root.rows

                y: row.index * Theme.netRowH
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
                    anchors.verticalCenterOffset: Theme.rowTextY
                    text: row.modelData ? row.modelData.ssid : ""
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fsL
                    font.weight: row.on || row.aimed ? Font.DemiBold : Font.Normal
                    color: row.on || row.aimed || row.selected ? Theme.accent : Theme.fg

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
                    anchors.rightMargin: Theme.netMetaR
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.rowGap

                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.status
                        font.pixelSize: Theme.fsS
                        color: Theme.accent
                        opacity: row.busy ? Theme.dimMid + (1 - Theme.dimMid) * pulse.val : 0
                        visible: text !== ""
                    }

                    Lock {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.locked && !row.on && row.status === ""
                        opacity: Theme.dimMuted
                    }

                    Sig {
                        anchors.verticalCenter: parent.verticalCenter
                        level: Math.round(row.sig * Theme.sigBars)
                        tint: row.on || row.aimed ? Theme.accent : Theme.fg
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
                    onClicked: {
                        if (root.ask) {
                            const same = Net.asking === row.modelData.ssid
                            Net.cancelAsk()
                            if (same)
                                return
                        }
                        root.sel = row.index
                        root.run()
                    }
                }
            }
        }

        Empty {
            text: "no networks"
            visible: Net.available && Net.enabled && root.n === 0
        }

        Empty {
            text: Net.title
            visible: !root.ask && !(Net.available && Net.enabled)
        }

        Fade {
            id: prompt
            width: parent.width
            height: rule.height + Theme.netPromptGap + Theme.netFieldH
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

            Rectangle {
                y: rule.height + Theme.netPromptGap
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
                    passwordCharacter: Theme.passChar
                    selectByMouse: true
                    font.family: Theme.font
                    font.pixelSize: Theme.fsL
                    clip: true

                    Keys.onPressed: e => Binds.run(e, {
                        cancel: () => {
                            Net.cancelAsk()
                            root.forceActiveFocus()
                        },
                        accept: () => root.run()
                    }, "insert")
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
}

import "../core"
import QtQuick
import Quickshell

Pick {
    id: root
    readonly property var items: Record.items

    n: items.length
    rows: Theme.recordRows
    width: Theme.recordW - 2 * Theme.recordPad
    height: col.height
    focus: shown

    function run() {
        if (n)
            Record.pick(items[sel])
    }

    onVisibleChanged: {
        if (visible)
            forceActiveFocus()
        else
            reset()
    }

    Connections {
        target: Record
        function onOpenChanged() {
            if (!Record.open)
                return
            root.reset()
            root.forceActiveFocus()
        }
        function onItemsChanged() {
            if (root.sel >= root.n)
                root.sel = Math.max(0, root.n - 1)
        }
    }

    Keys.onPressed: e => {
        const k = e.key
        if (k === Qt.Key_Escape)
            Record.open = false
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

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Record.active ? "recording " + Record.clock : "record"
            font.weight: Font.DemiBold
            color: Record.active ? Theme.red : Theme.fg
        }

        Rule { visible: root.n > 0 }

        Item {
            width: parent.width
            height: list.height
            visible: root.n > 0

            ListView {
                id: list
                width: parent.width
                height: Math.min(root.n, Theme.recordRows) * Theme.recordRowH
                clip: true
                interactive: false
                model: root.items
                cacheBuffer: Theme.recordRowH * Theme.recordRows * 2
                reuseItems: true
                contentY: root.start * Theme.recordRowH
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
                    row: Theme.recordRowH
                    width: list.width
                    mark: {
                        const it = root.items[root.sel]
                        return it && it.kind === "stop" ? Theme.red : Theme.accent
                    }
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool isStop: !!modelData && modelData.kind === "stop"

                    width: list.width
                    height: Theme.recordRowH

                    Txt {
                        anchors.left: parent.left
                        transformOrigin: Item.Center
                        scale: area.pressed ? Theme.feedbackPressScale : area.containsMouse ? Theme.feedbackHoverScale : 1

                        Behavior on scale { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
                        anchors.leftMargin: Theme.rowX
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.rowR
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData ? row.modelData.label : ""
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fsL
                        font.weight: Font.DemiBold
                        color: row.isStop ? Theme.red : Theme.fg
                    }

                    MouseArea {
                        id: area
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

    Wheel {
        anchors.fill: parent
        onStep: n => root.move(n, false)
    }
}

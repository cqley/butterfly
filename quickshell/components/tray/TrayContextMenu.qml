import "../core"
import QtQuick
import Quickshell

Pick {
    id: root
    property var layout: ({
            items: [],
            seps: []
        })
    property var pending: null
    property bool rewind: false

    readonly property var items: layout.items

    n: layout.items.length
    rows: Theme.trayMenuRows
    width: Theme.trayMenuW - 2 * Theme.trayMenuPad
    height: back.height + (root.n > 0 ? list.height : Theme.trayMenuRowH)
    focus: shown

    QsMenuOpener {
        id: opener
        menu: Tray.currentMenuHandle
    }

    function label(it) {
        return it && it.text ? it.text : ""
    }

    function fetch() {
        return opener.children ? [...opener.children.values] : []
    }

    function same(a, b) {
        if (a.length !== b.length)
            return false
        for (let i = 0; i < a.length; i++)
            if (a[i] !== b[i])
                return false
        return true
    }

    function build(vals) {
        let items = [];
        let seps = [];
        let gap = false
        for (const v of vals) {
            if (v.isSeparator) {
                gap = items.length > 0
                continue
            }
            items.push(v)
            seps.push(gap)
            gap = false
        }
        return {
            items: items,
            seps: seps
        }
    }

    function apply(l) {
        layout = l
        if (rewind) {
            reset()
            rewind = false
        }
        hold()
    }

    function commit(vals) {
        const l = build(vals)
        if (same(l.items, layout.items) && same(l.seps, layout.seps))
            return
        if (!shown) {
            apply(l)
            return
        }
        pending = l
        churn = true
        swap.restart()
    }

    Timer {
        id: swap
        interval: Theme.fade
        onTriggered: {
            if (root.pending)
                root.apply(root.pending)
            root.pending = null
            root.churn = false
        }
    }

    function rebuild() {
        const vals = fetch()
        if (vals.length === 0 && layout.items.length > 0) {
            settle.restart()
            return
        }
        settle.stop()
        commit(vals)
    }

    Timer {
        id: settle
        interval: Theme.trayMenuSettle
        onTriggered: root.commit(root.fetch())
    }

    Component.onCompleted: rebuild()

    Connections {
        target: opener
        function onChildrenChanged() { root.rebuild() }
    }

    function run() {
        if (!n)
            return
        const it = items[sel]
        if (!it || !it.enabled)
            return
        if (it.hasChildren)
            Tray.pushMenu(it)
        else {
            it.triggered()
            Tray.open = false
        }
    }

    function fresh() {
        swap.stop()
        settle.stop()
        churn = false
        pending = null
        rewind = false
        reset()
    }

    onVisibleChanged: {
        if (visible)
            forceActiveFocus()
        else
            fresh()
    }

    Connections {
        target: Tray
        function onCurrentMenuHandleChanged() { root.rewind = true }
    }

    Keys.onPressed: e => {
        const k = e.key
        if (k === Qt.Key_Escape) {
            Tray.popMenu()
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            run()
        } else if (k === Qt.Key_Right) {
            const it = root.items[root.sel]
            if (it && it.hasChildren)
                run()
        } else if (k === Qt.Key_Left) {
            Tray.popMenu()
        } else if (!nav(e)) {
            return
        }
        e.accepted = true
    }

    Item {
        id: back
        width: parent.width
        height: Theme.trayMenuRowH

        Txt {
            anchors.left: parent.left
            anchors.leftMargin: Theme.rowX
            anchors.verticalCenter: parent.verticalCenter
            text: "‹ back"
            opacity: backArea.containsMouse ? 1 : Theme.dimMuted
            color: Theme.accent
            transformOrigin: Item.Left
            scale: backArea.pressed ? Theme.feedbackPressScale : 1

            Behavior on opacity {
                NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
            }

            Behavior on scale {
                NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
            }
        }

        MouseArea {
            id: backArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Tray.popMenu()
        }
    }

    Item {
        id: list
        width: parent.width
        y: back.height
        height: Math.min(root.n, Theme.trayMenuRows) * Theme.trayMenuRowH
        clip: true
        visible: root.n > 0

        ScriptModel {
            id: entryModel
            values: root.layout.items
        }

        Item {
            id: inner
            width: parent.width
            height: root.n * Theme.trayMenuRowH
            y: -root.start * Theme.trayMenuRowH

            Behavior on y {
                NumberAnimation { duration: root.snap ? 0 : root.dur; easing.type: Theme.ease }
            }

            Rectangle {
                x: Theme.selInset
                y: root.sel * Theme.trayMenuRowH + Theme.selGap / 2
                width: inner.width - Theme.selInset * 2
                height: Theme.trayMenuRowH - Theme.selGap
                radius: height / 2
                color: Theme.selFill
                border.width: Theme.surfaceBorderWidth
                border.color: Theme.surfaceBorder
                antialiasing: true
                visible: !!root.items[root.sel]

                Mark {
                    label: root.label(root.items[root.sel])
                }

                Behavior on y {
                    NumberAnimation { duration: root.snap ? 0 : root.dur; easing.type: Theme.ease }
                }
            }

            Repeater {
                model: entryModel

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool selected: root.sel === row.index
                    readonly property bool live: !!row.modelData && row.modelData.enabled
                    readonly property bool onscreen: row.index >= root.start && row.index < root.start + root.rows
                    readonly property bool checked: !!row.modelData && row.modelData.buttonType !== QsMenuButtonType.None && row.modelData.checkState === Qt.Checked

                    y: row.index * Theme.trayMenuRowH
                    width: inner.width
                    height: Theme.trayMenuRowH

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Theme.trayMenuSepW
                        height: Theme.surfaceBorderWidth
                        color: Theme.surfaceBorder
                        visible: !!root.layout.seps[row.index]
                        opacity: row.index === root.sel || row.index === root.sel + 1 ? 0 : 1

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.rowX
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.trayMenuMarkD
                        height: Theme.trayMenuMarkD
                        radius: row.modelData && row.modelData.buttonType === QsMenuButtonType.RadioButton ? width / 2 : 2
                        color: Theme.accent
                        visible: row.checked
                    }

                    Txt {
                        anchors.left: parent.left
                        anchors.leftMargin: row.checked ? Theme.rowX + Theme.trayMenuMarkD + Theme.rowGap : Theme.rowX
                        anchors.right: chevron.left
                        anchors.rightMargin: Theme.rowGap
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: Theme.rowTextY
                        text: root.label(row.modelData)
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fsL
                        color: row.selected ? Theme.accent : Theme.fg
                        opacity: row.live ? 1 : Theme.dimMid

                        Behavior on color {
                            ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                        }
                    }

                    Txt {
                        id: chevron
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.trayMenuChevronGap
                        anchors.verticalCenter: parent.verticalCenter
                        text: "›"
                        visible: !!row.modelData && row.modelData.hasChildren
                        opacity: Theme.dimMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: row.live && row.onscreen
                        hoverEnabled: row.live && row.onscreen
                        cursorShape: row.live ? Qt.PointingHandCursor : Qt.ArrowCursor
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

    Txt {
        anchors.top: back.bottom
        anchors.left: parent.left
        anchors.leftMargin: Theme.rowX
        height: Theme.trayMenuRowH
        verticalAlignment: Text.AlignVCenter
        text: "loading…"
        opacity: Theme.dimEmpty
        visible: root.n === 0
    }
}

import "../core"
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Pick {
    id: root
    readonly property var items: Tray.items

    n: items.length
    rows: Theme.trayRows
    width: n > 0 ? Math.min(n, Theme.trayRows) * Theme.trayCellW : Theme.trayEmptyW
    height: n > 0 ? Theme.trayRowH : empty.implicitHeight + Theme.emptyPad
    focus: shown

    property string selId: ""

    function run() {
        if (items[sel])
            items[sel].activate()
    }

    function fresh() {
        reset()
        selId = ""
    }

    function remember() {
        if (items && items[sel])
            selId = items[sel].id
    }

    function syncSel() {
        if (!n) {
            selId = ""
            return
        }
        if (selId !== "") {
            for (let i = 0; i < n; i++) {
                if (items[i] && items[i].id === selId) {
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
        else if (!Tray.open)
            fresh()
    }

    Connections {
        target: Tray
        function onOpenChanged() {
            if (!Tray.open)
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
        if (k === Qt.Key_Escape) Tray.open = false
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) run()
        else if (k === Qt.Key_Right) move(1, true)
        else if (k === Qt.Key_Left) move(-1, true)
        else if (!nav(e)) return
        e.accepted = true
    }

    Txt {
        id: empty
        anchors.centerIn: parent
        text: "no tray icons"
        opacity: Theme.dimEmpty
        visible: root.n === 0
    }

    Item {
        id: track
        width: parent.width
        height: Theme.trayRowH
        visible: root.n > 0
        clip: true

        ScriptModel {
            id: trayModel
            values: root.items
            objectProp: "id"
        }

        Item {
            id: inner
            width: root.n * Theme.trayCellW
            height: parent.height
            x: -root.start * Theme.trayCellW

            Behavior on x {
                NumberAnimation { duration: root.snap ? 0 : root.dur; easing.type: Theme.ease }
            }

            Rectangle {
                id: selector
                x: root.sel * Theme.trayCellW + (Theme.trayCellW - Theme.traySelD) / 2
                y: (Theme.trayRowH - Theme.traySelD) / 2
                width: Theme.traySelD
                height: Theme.traySelD
                radius: width / 2
                color: Theme.selFill
                border.width: Theme.surfaceBorderWidth
                border.color: Theme.surfaceBorder
                antialiasing: true

                Behavior on x {
                    NumberAnimation { duration: root.snap ? 0 : root.dur; easing.type: Theme.ease }
                }
            }

            Repeater {
                model: trayModel

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool selected: root.sel === cell.index
                    readonly property bool onscreen: cell.index >= root.start && cell.index < root.start + root.rows
                    readonly property bool attention: cell.modelData && cell.modelData.status === Status.NeedsAttention
                    readonly property bool passive: cell.modelData && cell.modelData.status === Status.Passive

                    x: cell.index * Theme.trayCellW
                    width: Theme.trayCellW
                    height: parent.height

                    Item {
                        anchors.fill: parent
                        transformOrigin: Item.Center
                        scale: area.pressed ? Theme.feedbackPressScale : area.containsMouse ? Theme.feedbackHoverScale : 1

                        Behavior on scale {
                            NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                        }

                        ClippingRectangle {
                            id: chip
                            anchors.centerIn: parent
                            width: Theme.trayChipD
                            height: Theme.trayChipD
                            radius: width / 2
                            color: Theme.chip
                            opacity: cell.passive && !cell.selected ? Theme.dimMid : 1
                            antialiasing: true

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                            }

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: Theme.trayGlyphD
                                source: cell.modelData ? cell.modelData.icon : ""
                            }
                        }

                        Rectangle {
                            width: Theme.trayAttentionD
                            height: Theme.trayAttentionD
                            radius: width / 2
                            color: Theme.red
                            x: chip.x + chip.width - width / 2
                            y: chip.y - height / 2
                            visible: cell.attention
                            antialiasing: true
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        enabled: cell.onscreen
                        hoverEnabled: cell.onscreen
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onPositionChanged: m => root.aim(mapToItem(null, m.x, m.y), cell.index)
                        onClicked: mouse => {
                            if (!cell.modelData)
                                return
                            root.sel = cell.index
                            if (mouse.button === Qt.RightButton)
                                Tray.openMenu(cell.modelData)
                            else if (mouse.button === Qt.MiddleButton)
                                cell.modelData.secondaryActivate()
                            else
                                root.run()
                        }
                        onWheel: wheel => {
                            if (cell.modelData)
                                cell.modelData.scroll(wheel.angleDelta.y, false)
                        }
                    }
                }
            }
        }
    }
}

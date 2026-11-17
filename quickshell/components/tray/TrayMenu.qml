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
    pad: Theme.trayPad
    width: n > 0 ? Math.min(n, Theme.trayRows) * Theme.trayCellW : Theme.trayEmptyW
    height: n > 0 ? Theme.trayRowH : empty.implicitHeight + Theme.emptyPad
    focus: shown
    owner: Tray
    keepWhileOpen: true
    entries: items
    identity: it => it.id
    onFresh: {
        reset()
        anchor = ""
    }

    function run() {
        if (items[sel])
            items[sel].activate()
    }

    Connections {
        target: Tray
        function onItemsChanged() { root.syncSel() }
    }

    keys: ({
        cancel: () => Tray.open = false,
        accept: () => root.run()
    })

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
            x: scroll.shaped

            Spring {
                id: scroll
                response: Theme.glideResponse
                settle: Theme.springSettle
                snap: root.snap
                target: -root.start * Theme.trayCellW
            }

            Rectangle {
                id: selector
                x: slide.shaped
                y: (Theme.trayRowH - Theme.traySelD) / 2
                width: Theme.traySelD
                height: Theme.traySelD
                radius: width / 2
                color: Theme.selFill
                border.width: Theme.surfaceBorderWidth
                border.color: Theme.surfaceBorder
                antialiasing: true

                Spring {
                    id: slide
                    response: Theme.glideResponse
                    settle: Theme.springSettle
                    snap: root.snap
                    target: root.sel * Theme.trayCellW + (Theme.trayCellW - Theme.traySelD) / 2
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
                        scale: cellScale.shaped

                        ScaleSpring {
                            id: cellScale
                            size: Theme.trayCellW
                            target: area.pressed ? Theme.feedbackPressScale : area.containsMouse ? Theme.feedbackHoverScale : 1
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

                    PickArea {
                        id: area
                        pick: root
                        at: cell.index
                        live: cell.onscreen
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
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

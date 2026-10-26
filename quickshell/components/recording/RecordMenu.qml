import "../core"
import QtQuick
import QtQuick.Shapes

Tiles {
    id: root
    property string anchor: ""
    readonly property var items: Record.items

    n: items.length
    width: Math.max(0, n * Theme.pwW + Math.max(0, n - 1) * Theme.pwGap)
    height: Theme.pwH

    function key(i) {
        const it = items[i]
        return it ? it.kind + ":" + it.value : ""
    }

    function ord(i) {
        let k = 0
        for (let j = 0; j <= i && j < n; j++)
            if (items[j].kind === "monitor")
                k++
        return k
    }

    function run(i) {
        if (i < 0 || i >= n)
            return
        Record.pick(items[i])
    }

    function remember() {
        anchor = key(sel)
    }

    function fresh() {
        reset()
        remember()
    }

    function resync() {
        for (let i = 0; i < n; i++) {
            if (key(i) === anchor) {
                snap = true
                sel = i
                snap = false
                return
            }
        }
        snap = true
        sel = Math.min(sel, Math.max(0, n - 1))
        snap = false
        remember()
    }

    onVisibleChanged: {
        if (visible)
            forceActiveFocus()
        else
            fresh()
    }

    Connections {
        target: Record
        function onOpenChanged() {
            if (!Record.open)
                return
            root.fresh()
            root.forceActiveFocus()
        }
        function onItemsChanged() {
            root.resync()
        }
    }

    Connections {
        target: root
        function onSelChanged() { root.remember() }
    }

    Keys.onPressed: e => {
        const k = e.key
        if (k === Qt.Key_Escape) Record.open = false
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) root.run(root.sel)
        else if (!root.nav(e)) return
        e.accepted = true
    }

    Row {
        spacing: Theme.pwGap

        Repeater {
            model: root.items

            Rectangle {
                id: tile
                required property var modelData
                required property int index
                readonly property bool on: root.sel === index
                readonly property bool isStop: modelData.kind === "stop"
                readonly property bool isMonitor: modelData.kind === "monitor"
                readonly property bool live: !isStop && Record.active && Record.targetLabel === modelData.label
                readonly property color tone: isStop ? Theme.red : Theme.accent
                property color ink: on ? Theme.bg : isStop ? Theme.red : Theme.fg

                width: Theme.pwW
                height: Theme.pwH
                radius: Theme.radius - Theme.pwPad
                antialiasing: true
                color: on ? tone : Theme.chip
                border.width: Theme.launchIconBorderWidth
                border.color: on ? tone : Theme.launchIconBorder
                transformOrigin: Item.Center
                scale: mouse.pressed ? Theme.feedbackPressScale : mouse.containsMouse ? Theme.feedbackHoverScale : 1

                Behavior on scale {
                    NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                }
                Behavior on color {
                    ColorAnimation { duration: root.snap ? 0 : Theme.glide; easing.type: Theme.ease }
                }
                Behavior on border.color {
                    ColorAnimation { duration: root.snap ? 0 : Theme.glide; easing.type: Theme.ease }
                }
                Behavior on ink {
                    ColorAnimation { duration: root.snap ? 0 : Theme.glide; easing.type: Theme.ease }
                }

                Shape {
                    id: glyph
                    anchors.centerIn: parent
                    width: Theme.iconGrid
                    height: Theme.iconGrid
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: Theme.iconStroke
                        strokeColor: tile.ink
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathSvg {
                            path: tile.isMonitor ? Theme.monitorPath
                                : tile.isStop ? Theme.recStopPath
                                : Theme.recPortalPath
                        }
                    }
                }

                Txt {
                    x: Math.round(glyph.x + (glyph.width - width) / 2)
                    y: Math.round(glyph.y + Theme.monitorNumAxis - height / 2) + Theme.monitorNumY
                    visible: tile.isMonitor
                    text: root.ord(tile.index)
                    font.pixelSize: Theme.monitorNumPx
                    font.weight: Font.DemiBold
                    color: tile.ink
                }

                Rectangle {
                    x: tile.width - Theme.recordBadge - Theme.recordBadgeInset
                    y: Theme.recordBadgeInset
                    width: Theme.recordBadge
                    height: Theme.recordBadge
                    radius: height / 2
                    color: Theme.red
                    antialiasing: true
                    visible: tile.live
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: m => root.aim(mapToItem(null, m.x, m.y), tile.index)
                    onClicked: root.run(tile.index)
                }
            }
        }
    }
}

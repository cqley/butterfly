import "../core"
import QtQuick
import QtQuick.Shapes
import Quickshell

Fade {
    id: root
    property int sel: 0
    property bool snap: false
    property real px: -1
    property real py: -1
    readonly property var items: Screenshot.items
    readonly property int n: items.length

    width: Math.max(0, n * Theme.pwW + Math.max(0, n - 1) * Theme.pwGap)
    height: Theme.pwH

    function run(i) {
        if (i < 0 || i >= n)
            return
        Screenshot.pick(items[i])
    }

    function reset() {
        snap = true
        sel = 0
        px = -1
        py = -1
        snap = false
    }

    onVisibleChanged: {
        if (visible) forceActiveFocus()
        else reset()
    }

    Connections {
        target: Screenshot
        function onOpenChanged() {
            if (!Screenshot.open)
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
        const s = e.modifiers & Qt.ShiftModifier
        const n = root.n
        if (n === 0)
            return
        if (k === Qt.Key_Escape) Screenshot.open = false
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) root.run(root.sel)
        else if (k === Qt.Key_Right || k === Qt.Key_L || k === Qt.Key_J || k === Qt.Key_Tab) root.sel = (root.sel + 1) % n
        else if (k === Qt.Key_Left || k === Qt.Key_H || k === Qt.Key_K || k === Qt.Key_Backtab) root.sel = (root.sel + n - 1) % n
        else if (k === Qt.Key_End || k === Qt.Key_G && s) root.sel = n - 1
        else if (k === Qt.Key_Home || k === Qt.Key_G) root.sel = 0
        else return
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
                readonly property bool isMonitor: modelData.kind === "output"
                readonly property bool isActive: modelData.kind === "active"
                readonly property int monitorIndex: {
                    let count = 0
                    for (let i = 0; i < index; i++)
                        if (root.items[i].kind === "output")
                            count++
                    return count + 1
                }
                property color ink: on ? Theme.bg : Theme.fg

                width: Theme.pwW
                height: Theme.pwH
                radius: Theme.radius - Theme.pwPad
                antialiasing: true
                color: on ? Theme.accent : Theme.chip
                border.width: Theme.launchIconBorderWidth
                border.color: on ? Theme.accent : Theme.launchIconBorder
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
                    anchors.centerIn: parent
                    width: Theme.iconGrid
                    height: Theme.iconGrid
                    preferredRendererType: Shape.CurveRenderer
                    visible: tile.isActive

                    ShapePath {
                        strokeWidth: -1
                        fillColor: tile.ink
                        fillRule: ShapePath.WindingFill
                        PathSvg { path: tile.isActive ? Theme.shotActiveBadgePath : "" }
                    }
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
                            path: tile.isMonitor ? Theme.shotMonitorPath
                                : tile.modelData.kind === "region" ? Theme.shotRegionPath
                                : Theme.shotWindowPath
                        }
                    }
                }

                Txt {
                    visible: tile.isMonitor
                    anchors.centerIn: glyph
                    anchors.verticalCenterOffset: Theme.shotMonitorNumY
                    text: tile.monitorIndex
                    color: tile.ink
                    font.pixelSize: Theme.shotMonitorNumSize
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: m => {
                        const p = mapToItem(null, m.x, m.y)
                        if (p.x === root.px && p.y === root.py) return
                        root.px = p.x
                        root.py = p.y
                        root.sel = tile.index
                    }
                    onClicked: root.run(tile.index)
                }
            }
        }
    }
}

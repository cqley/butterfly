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
    readonly property var items: [
        { label: "lock", dx: 0, cmd: ["sh", "-c", "pidof hyprlock || exec hyprlock"], icon: "M5 11H19A2 2 0 0 1 21 13V20A2 2 0 0 1 19 22H5A2 2 0 0 1 3 20V13A2 2 0 0 1 5 11ZM7 11V7A5 5 0 0 1 17 7V11" },
        { label: "sleep", dx: 0, cmd: ["systemctl", "suspend"], icon: "M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" },
        { label: "log out", dx: 0, cmd: ["sh", "-c", "loginctl terminate-session \"$XDG_SESSION_ID\" || hyprctl dispatch exit"], icon: "M9 21H5A2 2 0 0 1 3 19V5A2 2 0 0 1 5 3H9M16 17L21 12L16 7M21 12L9 12" },
        { label: "reboot", dx: -1, cmd: ["systemctl", "reboot"], icon: "M23 4L23 10L17 10M20.49 15a9 9 0 1 1-2.12-9.36L23 10" },
        { label: "power off", dx: 0, cmd: ["systemctl", "poweroff"], icon: "M18.36 6.64a9 9 0 1 1-12.73 0M12 2L12 12" }
    ]

    width: Theme.powerW - 2 * Theme.pwPad
    height: Theme.pwH

    function run(i) {
        if (i < 0 || i >= items.length)
            return
        Quickshell.execDetached(items[i].cmd)
        Power.open = false
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
        target: Power
        function onOpenChanged() {
            if (!Power.open) return
            root.reset()
            root.forceActiveFocus()
        }
    }

    Keys.onPressed: e => {
        const k = e.key
        const n = root.items.length
        if (k === Qt.Key_Escape) Power.open = false
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) root.run(root.sel)
        else if (k === Qt.Key_Right || k === Qt.Key_L || k === Qt.Key_Tab) root.sel = (root.sel + 1) % n
        else if (k === Qt.Key_Left || k === Qt.Key_H || k === Qt.Key_Backtab) root.sel = (root.sel + n - 1) % n
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
                property color ink: on ? Theme.bg : Theme.fg

                width: Theme.pwW
                height: Theme.pwH
                radius: Theme.radius - Theme.pwPad
                antialiasing: true
                color: on ? Theme.accent : Theme.chip
                transformOrigin: Item.Center
                scale: mouse.pressed ? Theme.feedbackPressScale : mouse.containsMouse ? Theme.feedbackHoverScale : 1

                Behavior on scale {
                    NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                }

                Behavior on color {
                    enabled: !root.snap
                    ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
                }
                Behavior on ink {
                    enabled: !root.snap
                    ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
                }

                Shape {
                    x: Math.round((tile.width - width) / 2) + tile.modelData.dx
                    y: Theme.pwIconY
                    width: Theme.iconGrid
                    height: Theme.iconGrid
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: Theme.iconStroke
                        strokeColor: tile.ink
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin

                        PathSvg { path: tile.modelData.icon }
                    }
                }

                Txt {
                    x: Math.round((tile.width - width) / 2)
                    y: Theme.pwLabelY
                    text: tile.modelData.label
                    color: tile.ink
                    font.pixelSize: Theme.fsS
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

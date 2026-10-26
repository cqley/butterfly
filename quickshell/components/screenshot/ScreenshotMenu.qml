import "../core"
import QtQuick
import QtQuick.Shapes
import Quickshell

Tiles {
    id: root
    readonly property var items: Screenshot.items

    n: items.length
    width: n > 0 ? n * Theme.pwW + (n - 1) * Theme.pwGap : empty.implicitWidth
    height: Theme.pwH

    function run(i) {
        if (i < 0 || i >= n)
            return
        Screenshot.pick(items[i])
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
    }

    Keys.onPressed: e => {
        const k = e.key
        if (k === Qt.Key_Escape) Screenshot.open = false
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) root.run(root.sel)
        else if (!root.nav(e)) return
        e.accepted = true
    }

    Txt {
        id: empty
        anchors.centerIn: parent
        text: "no backend"
        visible: root.n === 0
        opacity: Theme.dimEmpty
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
                readonly property bool isMonitor: modelData.kind === "monitor"
                readonly property bool isActive: modelData.kind === "active"
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
                        PathSvg { path: Theme.shotActiveBadgePath }
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
                            path: tile.isMonitor ? Theme.monitorPath
                                : tile.modelData.kind === "region" ? Theme.shotRegionPath
                                : Theme.shotWindowPath
                        }
                    }
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

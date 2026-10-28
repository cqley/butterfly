import "../core"
import QtQuick
import QtQuick.Shapes

Tiles {
    id: root
    readonly property var items: Power.items

    n: items.length
    width: Theme.powerW - 2 * Theme.pwPad
    height: Theme.pwH

    function run(i) {
        Power.run(i)
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
        if (k === Qt.Key_Escape) Power.open = false
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
                    x: Math.round((tile.width - width) / 2) + tile.modelData.dx
                    y: Math.round((tile.height - height) / 2)
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

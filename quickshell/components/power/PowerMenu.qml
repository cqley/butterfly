import "../core"
import QtQuick
import QtQuick.Shapes

Tiles {
    id: root
    readonly property var items: Power.items

    n: items.length
    pad: Theme.pwPad
    width: Theme.powerW - 2 * Theme.pwPad
    height: Theme.pwH
    owner: Power
    onFresh: reset()

    function run(i) {
        Power.run(i)
    }

    keys: ({
        cancel: () => Power.open = false,
        accept: () => root.run(root.sel)
    })

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
                radius: Theme.inner(Theme.radius, Theme.pwPad)
                antialiasing: true
                color: on ? Theme.accent : Theme.chip
                border.width: Theme.launchIconBorderWidth
                border.color: on ? Theme.accent : Theme.launchIconBorder
                transformOrigin: Item.Center
                scale: scaleMotion.shaped

                ScaleSpring {
                    id: scaleMotion
                    size: Theme.pwW
                    target: mouse.pressed ? Theme.feedbackPressScale : mouse.containsMouse ? Theme.feedbackHoverScale : 1
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
                    x: Theme.mid(tile.width, width) + tile.modelData.dx
                    y: Theme.mid(tile.height, height)
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

                PickArea {
                    id: mouse
                    pick: root
                    at: tile.index
                    onClicked: root.run(tile.index)
                }
            }
        }
    }
}

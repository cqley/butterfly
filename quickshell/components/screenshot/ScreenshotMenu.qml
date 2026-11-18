import "../core"
import QtQuick
import QtQuick.Shapes
import Quickshell

Tiles {
    id: root
    readonly property var items: Screenshot.items

    n: items.length
    pad: Theme.pwPad
    width: n > 0 ? n * Theme.pwW + (n - 1) * Theme.pwGap : empty.implicitWidth
    height: Theme.pwH
    owner: Screenshot
    onFresh: reset()

    function run(i) {
        if (i < 0 || i >= n)
            return
        Screenshot.pick(items[i])
    }

    keys: ({
        cancel: () => Screenshot.open = false,
        accept: () => root.run(root.sel)
    })

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

            Tile {
                id: tile
                required property var modelData
                required property int index

                pick: root
                at: index
                path: modelData.kind === "monitor" ? Theme.monitorPath
                    : modelData.kind === "region" ? Theme.shotRegionPath
                    : Theme.shotWindowPath
                onClicked: root.run(index)

                under: Shape {
                    anchors.centerIn: parent
                    width: Theme.iconGrid
                    height: Theme.iconGrid
                    preferredRendererType: Shape.CurveRenderer
                    visible: tile.modelData.kind === "active"

                    ShapePath {
                        strokeWidth: -1
                        fillColor: tile.ink
                        fillRule: ShapePath.WindingFill
                        PathSvg { path: Theme.shotActiveBadgePath }
                    }
                }
            }
        }
    }
}

import "../core"
import QtQuick

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

            Tile {
                required property var modelData
                required property int index

                pick: root
                at: index
                path: modelData.icon
                dx: modelData.dx
                onClicked: root.run(index)
            }
        }
    }
}

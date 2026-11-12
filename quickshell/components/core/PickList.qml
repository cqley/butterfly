import QtQuick
import Quickshell

Item {
    id: root
    required property Item pick
    required property real rowH
    property int rows: root.pick.rows
    property var values: []
    property string key: ""
    property bool highlight: true
    property bool highlightShown: true
    property bool marked: false
    property string mark: ""
    property Component delegate

    width: parent ? parent.width : 0
    height: Math.min(root.pick.n, root.rows) * root.rowH
    clip: true

    ScriptModel {
        id: listModel
        values: root.values
        objectProp: root.key
    }

    Item {
        id: inner
        width: parent.width
        height: root.pick.n * root.rowH
        y: scroll.shaped

        Spring {
            id: scroll
            response: Theme.glideResponse
            settle: Theme.springSettle
            snap: root.pick.snap
            target: -root.pick.start * root.rowH
        }

        Rectangle {
            x: Theme.selInset
            y: slide.shaped
            width: inner.width - Theme.selInset * 2
            height: root.rowH - Theme.selGap
            radius: height / 2
            color: Theme.selFill
            border.width: Theme.surfaceBorderWidth
            border.color: Theme.surfaceBorder
            antialiasing: true
            visible: root.highlight && root.highlightShown

            Mark {
                visible: root.marked
                label: root.mark
            }

            Spring {
                id: slide
                response: Theme.glideResponse
                settle: Theme.springSettle
                snap: root.pick.snap
                target: root.pick.sel * root.rowH + Theme.selGap / 2
            }
        }

        Repeater {
            model: listModel
            delegate: root.delegate
        }
    }
}

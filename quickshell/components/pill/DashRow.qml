import "../core"
import QtQuick

Row {
    id: row

    readonly property real t: parent && parent.t !== undefined ? parent.t : 1
    readonly property real reveal: parent && parent.reveal !== undefined ? parent.reveal : 1
    readonly property real originY: parent && parent.originY !== undefined ? parent.originY : 0
    readonly property bool live: parent && parent.live !== undefined ? parent.live : true
    readonly property real rowCy: row.y + row.height / 2

    spacing: 0
}

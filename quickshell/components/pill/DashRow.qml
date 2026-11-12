import "../core"
import QtQuick

Row {
    id: row

    readonly property real t: parent && parent.t !== undefined ? parent.t : 1
    readonly property real tFlat: parent && parent.tFlat !== undefined ? parent.tFlat : 1
    readonly property real reveal: parent && parent.reveal !== undefined ? parent.reveal : 1
    readonly property real late: parent && parent.late !== undefined ? parent.late : 1
    readonly property real originY: parent && parent.originY !== undefined ? parent.originY : 0
    readonly property bool live: parent && parent.live !== undefined ? parent.live : true
    readonly property real calm: parent && parent.calm !== undefined ? parent.calm : 1
    readonly property real rowCy: row.y + row.height / 2

    spacing: 0
}

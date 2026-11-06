import QtQuick

Txt {
    id: root
    property real dx: 0
    property real dy: 0
    readonly property real inkShift: optical.shift

    verticalAlignment: Text.AlignVCenter

    OpticalCenter {
        id: optical
        targetFont: root.font
        text: root.text
    }

    transform: Translate {
        x: root.dx
        y: root.dy + optical.shift
    }
}

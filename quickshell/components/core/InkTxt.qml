import QtQuick

Txt {
    id: root
    property real dx: 0

    verticalAlignment: Text.AlignVCenter

    OpticalCenter {
        id: optical
        targetFont: root.font
        text: root.text
    }

    transform: Translate {
        x: root.dx
        y: optical.shift
    }
}

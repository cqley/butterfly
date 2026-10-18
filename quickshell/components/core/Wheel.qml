import QtQuick

MouseArea {
    signal step(int n)
    property real acc: 0

    acceptedButtons: Qt.NoButton

    onVisibleChanged: acc = 0
    onEnabledChanged: if (!enabled) acc = 0

    onWheel: wheel => {
        acc += wheel.angleDelta.y
        const n = Math.trunc(acc / 120)
        acc -= n * 120
        if (n) step(-n)
    }
}


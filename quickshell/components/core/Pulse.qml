import QtQuick

QtObject {
    id: root
    property bool running: false
    property real val: 1

    property SequentialAnimation loop: SequentialAnimation {
        running: root.running
        loops: Animation.Infinite

        NumberAnimation {
            target: root
            property: "val"
            from: 1
            to: 0
            duration: Theme.blink
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: root
            property: "val"
            from: 0
            to: 1
            duration: Theme.blink
            easing.type: Easing.InOutSine
        }
    }
}

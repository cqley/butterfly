import "../core"
import QtQuick

Rectangle {
    property real pulse: 1
    anchors.fill: parent
    radius: width / 2
    color: Theme.red
    antialiasing: true
    opacity: Theme.dotLow + (1 - Theme.dotLow) * pulse

    SequentialAnimation on pulse {
        running: Record.active
        loops: Animation.Infinite

        NumberAnimation {
            from: 1
            to: 0
            duration: Theme.pulse
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            from: 0
            to: 1
            duration: Theme.pulse
            easing.type: Easing.InOutSine
        }
    }
}

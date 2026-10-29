import "../core"
import QtQuick

Item {
    id: root
    property real from: 0
    property real to: 1
    property real value: 0
    signal moved(real value)

    readonly property real ratio: root.to > root.from ? (root.value - root.from) / (root.to - root.from) : 0

    width: 120
    height: Theme.settingsSliderKnobD

    function setFromX(x) {
        const r = Math.max(0, Math.min(1, x / root.width))
        root.value = root.from + r * (root.to - root.from)
        root.moved(root.value)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Theme.settingsSliderH
        radius: height / 2
        color: Theme.settingsCardAlt
        antialiasing: true

        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: height / 2
            color: Theme.accent
            antialiasing: true
        }
    }

    Rectangle {
        x: root.ratio * (root.width - width)
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.settingsSliderKnobD
        height: Theme.settingsSliderKnobD
        radius: width / 2
        color: Theme.fg
        antialiasing: true
        scale: drag.pressed ? Theme.feedbackPressScale : 1

        Behavior on scale {
            NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        onPressed: mouse => root.setFromX(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.setFromX(mouse.x) }
    }
}

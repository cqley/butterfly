import QtQuick

Rectangle {
    id: root
    required property var pick
    required property int row
    property color mark: Theme.accent
    property color fill: Theme.chip
    property int insetX: 0
    property int insetY: 0
    property int markX: Theme.markX
    property int markW: Theme.markW
    property real markHeight: root.height / 2 - 1

    x: root.insetX
    y: pick.sel * row + root.insetY
    height: row - root.insetY * 2
    radius: height / 2
    color: root.fill
    antialiasing: true

    Behavior on y {
        enabled: !root.pick.snap
        NumberAnimation {
            duration: root.pick.dur
            easing.type: Theme.ease
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.feedbackDuration
            easing.type: Theme.ease
        }
    }

    Rectangle {
        x: root.markX
        anchors.verticalCenter: parent.verticalCenter
        width: root.markW
        height: root.markHeight
        radius: width / 2
        color: root.mark
        antialiasing: true
    }
}

import "../core"
import QtQuick

Item {
    readonly property real u: Theme.micS / 12
    anchors.fill: parent

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.u - 1
        width: 5 * parent.u
        height: 7 * parent.u
        radius: width / 2
        color: Theme.red
        antialiasing: true
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 7 * parent.u - 1
        width: 7 * parent.u
        height: 3 * parent.u
        radius: parent.u
        color: "transparent"
        border.width: 1.2 * parent.u
        border.color: Theme.red
        antialiasing: true
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10 * parent.u - 1
        width: 1.5 * parent.u
        height: 2 * parent.u
        color: Theme.red
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: 1.5 * parent.u
        radius: height / 2
        rotation: 45
        color: Theme.red
        antialiasing: true
    }
}

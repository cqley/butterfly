import "../core"
import QtQuick

Item {
    width: Theme.lockW
    height: Theme.lockH

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Theme.lockArcW
        height: Theme.lockArcH
        radius: Theme.lockArcR
        color: "transparent"
        border.width: Theme.lockBorder
        border.color: Theme.fg
        antialiasing: true
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.lockBodyY
        width: Theme.lockBodyW
        height: Theme.lockBodyH
        radius: Theme.lockBodyR
        color: Theme.fg
        antialiasing: true
    }
}

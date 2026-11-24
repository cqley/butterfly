import "../core"
import QtQuick
import Quickshell

Item {
    id: root
    property string text: Theme.clockText(clock.date)
    property bool sealed: false

    anchors.fill: parent

    Component.onCompleted: if (root.sealed) Locker.stages++
    Component.onDestruction: if (root.sealed) Locker.stages--

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onPressed: keys.forceActiveFocus()
    }

    LockWall {
        id: wall
        async: false
    }

    Clock {
        t: 1
        to: Qt.point(root.width / 2, root.height / 2 + Theme.lockerClockOffsetY)
        from: to
        wall: wall.glass
        text: root.text
    }

    LockPill {}

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            Locker.key(event)
            event.accepted = true
        }
        Component.onCompleted: keys.forceActiveFocus()
    }
}

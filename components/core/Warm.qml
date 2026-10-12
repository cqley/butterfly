pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property bool on: true
    property bool settled: false

    Timer {
        running: true
        interval: Theme.warmTime
        onTriggered: {
            root.on = false
            land.start()
        }
    }

    Timer {
        id: land
        interval: Theme.fast
        onTriggered: root.settled = true
    }
}

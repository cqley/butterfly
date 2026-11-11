pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    Component.onCompleted: Modal.register("osd", root)
    property bool open: false
    property string kind: "volume"
    property real bright: 0

    onOpenChanged: {
        if (root.open)
            Modal.claim("osd")
        else
            linger.stop()
    }

    function flash(k) {
        root.kind = k
        root.open = true
        linger.restart()
    }

    function flashBright(v) {
        root.bright = v
        root.flash("brightness")
    }

    Timer {
        id: linger
        interval: Theme.osdLinger
        onTriggered: root.open = false
    }
}

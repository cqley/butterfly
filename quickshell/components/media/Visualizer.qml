pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool on: false

    function toggle() {
        root.on = !root.on
    }

    Connections {
        target: Media
        function onPlayingChanged() {
            if (!Media.playing)
                root.on = false
        }
    }

    IpcHandler {
        target: "visualizer"
        function toggle(): void { root.toggle() }
        function status(): string { return root.on ? "on" : "off" }
    }
}

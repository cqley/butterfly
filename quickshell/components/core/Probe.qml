pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool on: false
    property int seq: 0

    FrameAnimation {
        running: root.on
        onTriggered: console.log("PROBE", root.seq++, Math.round(frameTime * 1e6))
    }

    IpcHandler {
        target: "probe"
        function start(): void {
            root.seq = 0
            root.on = true
        }
        function stop(): void { root.on = false }
        function status(): string { return root.on ? "on " + root.seq : "off" }
    }
}

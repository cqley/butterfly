pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property var node: Audio.source
    readonly property bool muted: Audio.inMuted

    function toggle() {
        Audio.toggleMute(1)
    }

    IpcHandler {
        target: "mic"
        function toggle(): void { root.toggle() }
        function status(): string {
            if (!root.node)
                return "no source"
            return root.muted ? "muted" : "live"
        }
    }
}

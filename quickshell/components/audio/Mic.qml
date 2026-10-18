pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root
    readonly property var node: Pipewire.defaultAudioSource
    readonly property bool muted: node && node.audio ? node.audio.muted : false

    function toggle() {
        if (!node || !node.audio)
            return
        node.audio.muted = !node.audio.muted
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSource]
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

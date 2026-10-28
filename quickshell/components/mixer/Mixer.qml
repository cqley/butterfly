pragma Singleton
import "../core"
import "../brightness"
import "../audio"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false

    onOpenChanged: {
        Audio.watch = root.open
        if (root.open)
            Modal.claim("mixer")
    }

    IpcHandler {
        target: "mixer"
        function toggle(): void { root.open = !root.open }
        function status(): string {
            const parts = []
            for (let i = 0; i < Brightness.count; i++) {
                const d = Brightness.devices.get(i)
                parts.push(d.label + " " + Theme.pctOrUnavailable(d.ready, d.value))
            }
            for (let i = 0; i < Audio.count; i++) {
                const name = i === 0 ? "volume" : "mic"
                parts.push(name + " " + Theme.pctOrUnavailable(Audio.node(i) !== null, Audio.level(i), Audio.muted(i) ? " muted" : ""))
            }
            return parts.join(", ")
        }
    }
}

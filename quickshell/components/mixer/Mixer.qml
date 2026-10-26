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
                parts.push(d.label + " " + (d.ready ? Math.round(d.value * 100) + "%" : "unavailable"))
            }
            for (let i = 0; i < Audio.count; i++) {
                const name = i === 0 ? "volume" : "mic"
                parts.push(Audio.node(i)
                    ? name + " " + Math.round(Audio.level(i) * 100) + "%" + (Audio.muted(i) ? " muted" : "")
                    : name + " unavailable")
            }
            return parts.join(", ")
        }
    }
}

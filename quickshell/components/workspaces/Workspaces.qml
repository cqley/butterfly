pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property bool available: Compositor.isHyprland && Hyprland.workspaces.values.length > 0 && Cfg.ready
    readonly property int count: Math.max(1, Theme.wsCount)

    readonly property var monitor: {
        if (!root.available)
            return null
        const want = Theme.shellScreen
        const list = Hyprland.monitors.values
        for (let i = 0; i < list.length; i++)
            if (list[i].name === want)
                return list[i]
        return null
    }

    readonly property int liveId: {
        if (!root.available)
            return 0
        const ws = Hyprland.focusedWorkspace
        if (ws)
            return ws.id
        const m = root.monitor
        return m && m.activeWorkspace ? m.activeWorkspace.id : 0
    }

    property int current: 1
    readonly property int page: Math.floor((root.current - 1) / root.count)
    readonly property int first: root.page * root.count + 1
    readonly property int index: Math.max(0, Math.min(root.count - 1, root.current - root.first))

    readonly property int span: {
        const vert = Theme.wsVertical
        const pipW = vert ? Theme.wsBarW : Theme.wsDot
        const actW = Math.max(vert ? Theme.wsBarActiveW : Theme.wsActiveW, pipW)
        const pitch = pipW + (vert ? Theme.wsBarGap : Theme.wsGap)
        return (root.count - 1) * pitch + actW
    }

    readonly property var filled: {
        const out = []
        for (let i = 0; i < root.count; i++)
            out.push(false)
        if (!root.available)
            return out
        const list = Hyprland.workspaces.values
        for (let i = 0; i < list.length; i++) {
            const ws = list[i]
            const slot = ws.id - root.first
            if (slot < 0 || slot >= root.count)
                continue
            const raw = ws.lastIpcObject
            const n = raw && raw.windows !== undefined ? raw.windows : ws.toplevels.values.length
            out[slot] = n > 0
        }
        return out
    }

    function adopt() {
        if (root.liveId >= 1)
            root.current = root.liveId
    }

    onLiveIdChanged: root.adopt()

    Component.onCompleted: root.adopt()

    readonly property var placements: ["left", "right", "only"]

    function store(key, value) {
        Cfg.set(key, value)
        Cfg.flush()
    }

    IpcHandler {
        target: "workspaces"

        function toggle(): string {
            root.store("wsOn", !Theme.wsOn)
            return Theme.wsOn ? "shown" : "hidden"
        }

        function place(where: string): string {
            if (root.placements.indexOf(where) < 0)
                return "expected one of " + root.placements.join("|")
            root.store("wsPlace", where)
            return where
        }

        function style(kind: string): string {
            if (kind !== "dots" && kind !== "bars")
                return "expected dots|bars"
            root.store("wsVertical", kind === "bars")
            return kind
        }

        function status(): string {
            if (!root.available)
                return "unavailable"
            const ws = Hyprland.focusedWorkspace
            const where = ws && ws.monitor ? ws.monitor.name : "?"
            return (Theme.wsOn ? "shown" : "hidden")
                 + " · " + Theme.wsPlace + " · " + (Theme.wsVertical ? "bars" : "dots")
                 + " · ws " + root.current + " on " + where
                 + " · page " + root.first + "-" + (root.first + root.count - 1)
                 + " · slot " + (root.index + 1)
                 + " · filled [" + root.filled + "]"
        }
    }
}

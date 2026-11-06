pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property bool wired: Compositor.isHyprland && Hyprland.workspaces.values.length > 0 && Cfg.ready
    property bool synced: false
    readonly property bool available: root.wired && root.synced

    readonly property var monitor: {
        if (!root.wired)
            return null
        const want = Theme.shellScreen
        const list = Hyprland.monitors.values
        for (let i = 0; i < list.length; i++)
            if (list[i].name === want)
                return list[i]
        return null
    }

    readonly property int liveId: {
        if (!root.wired)
            return 0
        const ws = Hyprland.focusedWorkspace
        if (ws)
            return ws.id
        const m = root.monitor
        return m && m.activeWorkspace ? m.activeWorkspace.id : 0
    }

    property int current: 1

    readonly property int top: {
        if (!root.wired)
            return root.count
        let high = root.current
        const list = Hyprland.workspaces.values
        for (let i = 0; i < list.length; i++)
            if (list[i].id > high)
                high = list[i].id
        return high
    }

    readonly property int total: Math.max(root.count, Math.min(root.top, Theme.wsMax))
    readonly property int index: Math.max(0, Math.min(root.total - 1, root.current - 1))

    readonly property int span: {
        const vert = root.vertical
        const pipW = vert ? Theme.wsBarW : Theme.wsDot
        const actW = Math.max(vert ? Theme.wsBarActiveW : Theme.wsActiveW, pipW)
        const pitch = pipW + (vert ? Theme.wsBarGap : Theme.wsGap)
        return (root.count - 1) * pitch + actW
    }

    readonly property var filled: {
        const out = []
        for (let i = 0; i < root.total; i++)
            out.push(false)
        if (!root.wired)
            return out
        const list = Hyprland.workspaces.values
        const tracked = Hyprland.toplevels.values.length > 0
        for (let i = 0; i < list.length; i++) {
            const ws = list[i]
            const slot = ws.id - 1
            if (slot < 0 || slot >= root.total)
                continue
            const raw = ws.lastIpcObject
            const n = tracked ? ws.toplevels.values.length
                              : (raw && raw.windows !== undefined ? raw.windows : 0)
            out[slot] = n > 0
        }
        return out
    }

    // layout
    readonly property bool wantVertical: Theme.wsVertical
    readonly property int wantCount: Math.max(1, Theme.wsCount)
    readonly property string wantPlace: Theme.wsPlace
    property bool vertical: false
    property int count: 1
    property string place: "left"
    property real layoutFade: 0

    function applyLayout() {
        root.vertical = root.wantVertical
        root.count = root.wantCount
        root.place = root.wantPlace
    }

    function relayout() {
        if (Theme.wsOn && root.available) {
            layoutRun.restart()
            return
        }
        layoutRun.stop()
        root.layoutFade = 0
        root.applyLayout()
    }

    onWantVerticalChanged: root.relayout()
    onWantCountChanged: root.relayout()
    onWantPlaceChanged: root.relayout()

    SequentialAnimation {
        id: layoutRun

        NumberAnimation {
            target: root
            property: "layoutFade"
            to: 1
            duration: Theme.wsSwap
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: root.applyLayout()
        }

        NumberAnimation {
            target: root
            property: "layoutFade"
            to: 0
            duration: Theme.wsSwap
            easing.type: Easing.OutCubic
        }
    }

    function adopt() {
        if (root.liveId < 1)
            return
        root.current = root.liveId
        root.synced = true
    }

    onLiveIdChanged: root.adopt()

    onWiredChanged: if (root.wired) reveal.restart()

    Timer {
        id: reveal
        interval: 0
        onTriggered: root.synced = true
    }

    Component.onCompleted: {
        root.applyLayout()
        root.adopt()
    }

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
                 + " · slot " + (root.index + 1) + " of " + root.total + ", " + root.count + " shown"
                 + " · filled [" + root.filled + "]"
        }
    }
}

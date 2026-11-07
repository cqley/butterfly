pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.I3

Singleton {
    id: root

    readonly property var spaces: {
        if (Compositor.isHyprland) {
            const tracked = Hyprland.toplevels.values.length > 0
            return Hyprland.workspaces.values.map(ws => {
                const raw = ws.lastIpcObject
                const n = tracked ? ws.toplevels.values.length
                                  : (raw && raw.windows !== undefined ? raw.windows : 0)
                return { id: ws.id, filled: n > 0 }
            })
        }
        if (Compositor.isSway) {
            const list = I3.workspaces.values
            let next = list.reduce((m, ws) => Math.max(m, ws.number), root.count)
            return list.map(ws => {
                const raw = ws.lastIpcObject
                return { id: ws.number >= 1 ? ws.number : ++next, name: ws.name, named: ws.number < 1,
                         filled: !!(raw && raw.focus && raw.focus.length > 0) }
            })
        }
        if (Compositor.isNiri) {
            const f = Niri.focused
            if (!f)
                return []
            return Niri.workspaces.filter(w => w.output === f.output && (w.is_active || w.active_window_id !== null))
                                  .map(w => ({ id: w.idx, filled: w.active_window_id !== null }))
        }
        return []
    }

    readonly property bool wired: root.spaces.length > 0 && Cfg.ready
    property bool synced: false
    readonly property bool available: root.wired && root.synced

    readonly property string output: {
        if (Compositor.isHyprland) {
            const ws = Hyprland.focusedWorkspace
            return ws && ws.monitor ? ws.monitor.name : ""
        }
        if (Compositor.isSway)
            return I3.focusedMonitor ? I3.focusedMonitor.name : ""
        if (Compositor.isNiri)
            return Niri.focused ? Niri.focused.output || "" : ""
        return ""
    }

    readonly property int liveId: {
        if (!root.wired)
            return 0
        if (Compositor.isHyprland) {
            const ws = Hyprland.focusedWorkspace
            if (ws)
                return ws.id
            const want = Theme.shellScreen
            const m = Hyprland.monitors.values.find(m => m.name === want)
            return m && m.activeWorkspace ? m.activeWorkspace.id : 0
        }
        if (Compositor.isSway) {
            const ws = I3.focusedWorkspace
            const hit = ws ? root.spaces.find(s => s.name === ws.name) : null
            return hit ? hit.id : 0
        }
        if (Compositor.isNiri)
            return Niri.focused ? Niri.focused.idx : 0
        return 0
    }

    property int current: 1

    readonly property int top: {
        if (!root.wired)
            return root.count
        let high = root.current
        for (const s of root.spaces)
            if (s.id > high)
                high = s.id
        return high
    }

    readonly property int total: Math.max(root.count, Math.min(root.top, Theme.wsMax))
    readonly property int index: Math.max(0, Math.min(root.total - 1, root.current - 1))

    readonly property int span: {
        const vert = Theme.wsVertical
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
        for (const s of root.spaces) {
            const slot = s.id - 1
            if (slot >= 0 && slot < root.total)
                out[slot] = out[slot] || s.filled
        }
        return out
    }

    I3IpcListener {
        subscriptions: Compositor.isSway ? ["window"] : []
        onIpcEvent: I3.refreshWorkspaces()
    }

    // layout
    readonly property int wantCount: Math.max(1, Theme.wsCount)
    readonly property string wantPlace: Theme.wsPlace
    property int count: 1
    property string place: "left"
    property real layoutFade: 0

    function applyLayout() {
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

    function focus(id) {
        const n = Math.round(Number(id))
        if (!root.available || !(n >= 1) || n === root.current || switcher.running)
            return
        const hit = root.spaces.find(s => s.id === n)
        const cmd = Compositor.focusWorkspaceCmd(n, hit && hit.named ? hit.name : "")
        if (cmd.length === 0)
            return
        switcher.command = cmd
        switcher.running = true
    }

    Process {
        id: switcher
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

        function go(id: int): string {
            root.focus(id)
            return "ws " + id
        }

        function status(): string {
            if (!root.available)
                return "unavailable"
            return (Theme.wsOn ? "shown" : "hidden")
                 + " · " + Theme.wsPlace + " · " + (Theme.wsVertical ? "bars" : "dots")
                 + " · ws " + root.current + " on " + (root.output || "?") + " · " + Compositor.backend
                 + " · slot " + (root.index + 1) + " of " + root.total + ", " + root.count + " shown"
                 + " · filled [" + root.filled + "]"
        }
    }
}

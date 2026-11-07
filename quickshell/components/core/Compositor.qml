pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool isHyprland: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    readonly property bool isNiri: !isHyprland && !!Quickshell.env("NIRI_SOCKET")
    readonly property bool isSway: !isHyprland && !isNiri && !!Quickshell.env("SWAYSOCK")
    readonly property string backend: isHyprland ? "hyprland" : isNiri ? "niri" : isSway ? "sway" : ""

    readonly property bool supportsWindowTargets: isHyprland || isSway
    readonly property bool supportsNativeWindowShot: isNiri
    readonly property bool supportsCursorSeed: isHyprland

    readonly property var activeWindowCmd: isHyprland ? ["hyprctl", "-j", "activewindow"]
        : isSway ? ["swaymsg", "-r", "-t", "get_tree"]
        : []
    readonly property var cursorPosCmd: isHyprland ? ["hyprctl", "cursorpos"] : []
    readonly property var windowListCmd: isHyprland
        ? ["sh", "-c", "hyprctl -j monitors; echo '@@split@@'; hyprctl -j clients"]
        : isSway ? ["swaymsg", "-r", "-t", "get_tree"]
        : []
    readonly property var pickWindowCmd: isNiri ? ["niri", "msg", "--json", "pick-window"] : []

    function nativeWindowShotCmd(file, id) {
        if (!root.isNiri)
            return []
        const cmd = ["niri", "msg", "action", "screenshot-window", "--path", file]
        if (id !== undefined && id !== null)
            cmd.push("--id", String(id))
        return cmd
    }

    function focusWorkspaceCmd(id, name) {
        const n = Math.max(1, Math.round(Number(id)))
        if (root.isHyprland)
            return ["sh", "-c", "hyprctl dispatch \"hl.dsp.focus({ workspace = $1 })\" | grep -q '^ok' || hyprctl dispatch workspace \"$1\"", "sh", String(n)]
        if (root.isNiri)
            return ["niri", "msg", "action", "focus-workspace", String(n)]
        if (root.isSway)
            return name ? ["swaymsg", "workspace", name] : ["swaymsg", "workspace", "number", String(n)]
        return []
    }

    readonly property var logoutCmd: ["sh", "-c",
        "loginctl terminate-session \"$XDG_SESSION_ID\" || " + (
            isHyprland ? "hyprctl dispatch exit"
            : isNiri ? "niri msg action quit --skip-confirmation"
            : isSway ? "swaymsg exit"
            : "true")]

    function parseCursorPos(text) {
        const parts = text.trim().split(",")
        if (parts.length !== 2)
            return null
        const x = parseFloat(parts[0])
        const y = parseFloat(parts[1])
        if (!isFinite(x) || !isFinite(y))
            return null
        return { x, y }
    }

    function parseJson(text) {
        try {
            return JSON.parse(text)
        } catch (e) {
            return null
        }
    }

    function swayViews(node, out) {
        if (!node)
            return out
        if (node.window_rect && (node.app_id || node.window_properties || node.pid) && node.type !== "workspace" && node.type !== "output")
            out.push(node)
        for (const c of (node.nodes || []))
            root.swayViews(c, out)
        for (const c of (node.floating_nodes || []))
            root.swayViews(c, out)
        return out
    }

    function swayBox(v) {
        return { x: v.rect.x + v.window_rect.x, y: v.rect.y + v.window_rect.y, w: v.window_rect.width, h: v.window_rect.height }
    }

    function parseActiveWindow(text) {
        const d = root.parseJson(text)
        if (!d)
            return null
        if (root.isSway) {
            const v = root.swayViews(d, []).find(n => n.focused)
            return v ? root.swayBox(v) : null
        }
        if (!d.at || !d.size)
            return null
        return { x: d.at[0], y: d.at[1], w: d.size[0], h: d.size[1] }
    }

    function parseWindowList(text) {
        if (root.isSway) {
            const d = root.parseJson(text)
            return d ? root.swayViews(d, []).filter(v => v.visible).map(root.swayBox) : []
        }
        const parts = text.split("@@split@@")
        if (parts.length !== 2)
            return []
        const monitors = root.parseJson(parts[0])
        const clients = root.parseJson(parts[1])
        if (!monitors || !clients)
            return []
        const visibleWs = new Set()
        for (const m of monitors) {
            if (m.activeWorkspace)
                visibleWs.add(m.activeWorkspace.id)
            if (m.specialWorkspace && m.specialWorkspace.id !== 0)
                visibleWs.add(m.specialWorkspace.id)
        }
        const list = []
        for (const c of clients) {
            if (!c.mapped || c.hidden)
                continue
            if (!c.workspace || !visibleWs.has(c.workspace.id))
                continue
            list.push({ x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1] })
        }
        return list
    }

    function parsePickedWindow(text) {
        const d = root.parseJson(text)
        return d && d.id !== undefined ? d.id : null
    }
}

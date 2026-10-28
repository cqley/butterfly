pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool isHyprland: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== ""
    readonly property bool isNiri: !isHyprland && Quickshell.env("NIRI_SOCKET") !== ""
    readonly property string backend: isHyprland ? "hyprland" : isNiri ? "niri" : ""

    readonly property bool supportsWindowTargets: isHyprland
    readonly property bool supportsCursorSeed: isHyprland

    readonly property var activeWindowCmd: isHyprland ? ["hyprctl", "-j", "activewindow"] : []
    readonly property var cursorPosCmd: isHyprland ? ["hyprctl", "cursorpos"] : []
    readonly property var windowListCmd: isHyprland
        ? ["sh", "-c", "hyprctl -j monitors; echo '@@split@@'; hyprctl -j clients"]
        : []

    readonly property var logoutCmd: ["sh", "-c",
        "loginctl terminate-session \"$XDG_SESSION_ID\" || " + (
            isHyprland ? "hyprctl dispatch exit"
            : isNiri ? "niri msg action quit --skip-confirmation"
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

    function parseActiveWindow(text) {
        let d = null
        try {
            d = JSON.parse(text)
        } catch (e) {
            return null
        }
        if (!d || !d.at || !d.size)
            return null
        return { x: d.at[0], y: d.at[1], w: d.size[0], h: d.size[1] }
    }

    function parseWindowList(text) {
        const parts = text.split("@@split@@")
        if (parts.length !== 2)
            return []
        let monitors = []
        let clients = []
        try {
            monitors = JSON.parse(parts[0])
            clients = JSON.parse(parts[1])
        } catch (e) {
            return []
        }
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
}

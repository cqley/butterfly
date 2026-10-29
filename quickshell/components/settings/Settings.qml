pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root
    property bool open: false
    property string screenName: ""
    property int selected: 0

    readonly property var categories: [
        {
            id: "general",
            label: "general",
            icon: "M5 7H19M5 12H19M5 17H19",
            title: "general",
            subtitle: "placeholder page — 1B fills this in with real categories."
        },
        {
            id: "style",
            label: "style",
            icon: "M4,12 A8,8 0 1,0 20,12 A8,8 0 1,0 4,12",
            title: "style",
            subtitle: "theme, accent and type — reference mock for look and feel."
        },
        {
            id: "motion",
            label: "motion",
            icon: "M6 18L18 6M18 6H10M18 6V14",
            title: "motion",
            subtitle: "segmented control and slider demo."
        }
    ]

    readonly property int n: categories.length

    function move(d) {
        if (n <= 0)
            return
        selected = ((selected + d) % n + n) % n
    }

    onOpenChanged: {
        if (open) {
            Modal.claim("settings")
            screenName = Compositor.isHyprland && Hyprland.focusedMonitor
                ? Hyprland.focusedMonitor.name
                : (Quickshell.screens.length ? Quickshell.screens[0].name : "")
        }
    }

    Component.onCompleted: Modal.register("settings", root)

    IpcHandler {
        target: "settings"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
        function status(): string { return root.open ? "open " + root.screenName : "closed" }
    }
}

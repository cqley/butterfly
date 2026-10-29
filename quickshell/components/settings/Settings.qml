pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false
    property string screenName: ""
    property int selected: 0

    readonly property var categories: [
        {
            id: "general",
            label: "general",
            icon: Theme.settingsGeneralPath,
            title: "general",
            subtitle: "placeholder page — 1B fills this in with real categories."
        },
        {
            id: "style",
            label: "style",
            icon: Theme.settingsStylePath,
            title: "style",
            subtitle: "theme, accent and type — reference mock for look and feel."
        },
        {
            id: "motion",
            label: "motion",
            icon: Theme.settingsMotionPath,
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
            screenName = Compositor.focusedScreenName()
        }
    }

    Component.onCompleted: Modal.register("settings", root)

    Connections {
        target: Quickshell

        function onScreensChanged() {
            if (root.screenName !== "" && !Compositor.hasScreen(root.screenName)) {
                root.open = false
                root.screenName = ""
            }
        }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
        function status(): string { return root.open ? "open " + root.screenName : "closed" }
    }
}

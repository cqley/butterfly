pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false

    onOpenChanged: if (open)
        Modal.claim("wallpaper")

    function set(path) {
        if (!path)
            return
        Quickshell.execDetached(Theme.wallCmd.concat([path]))
        root.open = false
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.open = !root.open }
    }
}

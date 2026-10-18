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

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.open = !root.open }
    }
}

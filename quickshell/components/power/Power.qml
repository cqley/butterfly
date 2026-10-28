pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false
    readonly property var items: [
        { dx: 0, cmd: ["sh", "-c", "pidof hyprlock || exec hyprlock"], icon: Theme.lockGlyphPath },
        { dx: 0, cmd: ["systemctl", "suspend"], icon: Theme.pwSuspendPath },
        { dx: 0, cmd: Compositor.logoutCmd, icon: Theme.pwLogoutPath },
        { dx: -1, cmd: ["systemctl", "reboot"], icon: Theme.pwRebootPath },
        { dx: 0, cmd: ["systemctl", "poweroff"], icon: Theme.pwOffPath }
    ]

    onOpenChanged: if (open)
        Modal.claim("power")

    function run(i) {
        if (i < 0 || i >= items.length)
            return
        Quickshell.execDetached(items[i].cmd)
        root.open = false
    }

    IpcHandler {
        target: "power"
        function toggle(): void { root.open = !root.open }
    }
}

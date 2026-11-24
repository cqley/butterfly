pragma Singleton
import "../core"
import "../lock"
import QtQuick
import Quickshell

Menu {
    id: root
    name: "power"
    readonly property var items: [
        { dx: 0, act: () => Locker.lock(false), icon: Theme.lockGlyphPath },
        { dx: 0, cmd: ["systemctl", "suspend"], icon: Theme.pwSuspendPath },
        { dx: 0, cmd: Compositor.logoutCmd, icon: Theme.pwLogoutPath },
        { dx: -1, cmd: ["systemctl", "reboot"], icon: Theme.pwRebootPath },
        { dx: 0, cmd: ["systemctl", "poweroff"], icon: Theme.pwOffPath }
    ]

    function run(i) {
        if (i < 0 || i >= items.length)
            return
        root.open = false
        if (items[i].act)
            items[i].act()
        else
            Quickshell.execDetached(items[i].cmd)
    }
}

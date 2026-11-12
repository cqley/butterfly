pragma Singleton
import "../core"
import QtQuick
import Quickshell

Menu {
    id: root
    name: "wallpaper"

    function set(path) {
        if (!path)
            return
        Quickshell.execDetached(Theme.wallCmd.concat([path]))
        root.open = false
    }
}

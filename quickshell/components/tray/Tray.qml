pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

Singleton {
    id: root
    property bool open: false

    property var order: []
    property var items: []

    property var menuItem: null
    property var menuPath: []
    readonly property var currentMenuHandle: menuItem ? (menuPath.length ? menuPath[menuPath.length - 1] : menuItem.menu) : null

    function openMenu(item) {
        if (!item || !item.hasMenu)
            return
        menuItem = item
        menuPath = []
    }

    function closeMenu() {
        menuItem = null
        menuPath = []
    }

    function pushMenu(entry) {
        if (!entry || !entry.hasChildren)
            return
        menuPath = menuPath.concat([entry])
    }

    function popMenu() {
        if (menuPath.length > 0)
            menuPath = menuPath.slice(0, -1)
        else
            closeMenu()
    }

    function cmp(a, b) {
        return (a.title || a.id).localeCompare(b.title || b.id)
    }

    function rebuild() {
        const result = Theme.stableReorder([...SystemTray.items.values], order, i => i.id, cmp)
        order = result.order
        items = result.items
        if (menuItem && items.indexOf(menuItem) < 0)
            closeMenu()
    }

    Component.onCompleted: {
        Modal.register("tray", root)
        rebuild()
    }

    Connections {
        target: SystemTray.items
        function onValuesChanged() { root.rebuild() }
    }

    function toggle(): void {
        if (!open && !items.length)
            return
        open = !open
    }

    onOpenChanged: {
        if (open) {
            Modal.claim("tray")
            order = []
            rebuild()
        } else {
            closeMenu()
        }
    }

    IpcHandler {
        target: "tray"
        function toggle(): void { root.toggle() }
        function status(): string { return (root.open ? "open" : "closed") + " · " + root.items.length + " icons" }
    }
}

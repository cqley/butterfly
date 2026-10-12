pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false
    property var counts: Object.create(null)

    onOpenChanged: if (open)
        Modal.claim("launcher")

    function bump(id) {
        if (!id)
            return
        const c = Object.assign(Object.create(null), counts)
        c[id] = (Number(c[id]) || 0) + 1
        counts = c
        store.setText(JSON.stringify(c))
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Quickshell.stateDir])
        try {
            const parsed = JSON.parse(store.text())
            counts = parsed && typeof parsed === "object" && !Array.isArray(parsed)
                ? Object.assign(Object.create(null), parsed)
                : Object.create(null)
        } catch (e) {
            counts = Object.create(null)
        }
    }

    FileView {
        id: store
        path: Quickshell.statePath("launcher.json")
        blockLoading: true
        printErrors: false
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.open = !root.open }
    }
}

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    required property string name
    property string ipcTarget: root.name
    property bool ipc: true
    property bool open: false

    function toggle() {
        root.open = !root.open
    }

    function report() {
        return ""
    }

    function status() {
        const d = root.report()
        return (root.open ? "open" : "closed") + (d !== "" ? " · " + d : "")
    }

    onOpenChanged: if (root.open) Modal.claim(root.name)
    Component.onCompleted: Modal.register(root.name, root)

    IpcHandler {
        target: root.ipcTarget
        enabled: root.ipc
        function toggle(): void { root.toggle() }
        function status(): string { return root.status() }
    }
}

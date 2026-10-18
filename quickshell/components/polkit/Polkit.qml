pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit

Singleton {
    id: root
    readonly property bool open: agent.isActive
    readonly property alias flow: agent.flow
    readonly property alias registered: agent.isRegistered

    onOpenChanged: if (open)
        Modal.close("")

    function cancel() {
        if (flow) flow.cancelAuthenticationRequest()
    }

    PolkitAgent {
        id: agent
        path: "/org/quickshell/PolkitAgent"
    }

    IpcHandler {
        target: "polkit"
        function status(): string {
            return root.registered ? "registered" : "not registered"
        }
    }
}

pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Singleton {
    id: root
    property bool open: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: !!adapter
    readonly property bool enabled: available && adapter.enabled

    readonly property string title: {
        if (!available)
            return "no adapter"
        if (!enabled)
            return "bluetooth off"
        return adapter.name || "bluetooth"
    }

    function cmp(a, b) {
        if (a.connected !== b.connected)
            return a.connected ? -1 : 1
        if (a.paired !== b.paired)
            return a.paired ? -1 : 1
        const an = a.name || a.deviceName || ""
        const bn = b.name || b.deviceName || ""
        return an.localeCompare(bn)
    }

    readonly property var items: {
        if (!available)
            return []
        const list = [...adapter.devices.values].filter(d => d.paired || d.connected || (d.name && d.name !== ""))
        return list.sort(cmp)
    }

    onOpenChanged: {
        if (open)
            Modal.claim("bluetooth")
        if (available)
            adapter.discovering = open
    }

    function toggleAdapter() {
        if (available)
            adapter.enabled = !adapter.enabled
    }

    function statusOf(d) {
        if (!d)
            return ""
        if (d.state === BluetoothDeviceState.Connecting)
            return "connecting…"
        if (d.state === BluetoothDeviceState.Disconnecting)
            return "disconnecting…"
        if (d.pairing)
            return "pairing…"
        if (d.connected)
            return "connected"
        return ""
    }

    function pick(d) {
        if (!d)
            return
        if (d.connected)
            d.disconnect()
        else if (d.paired)
            d.connect()
        else
            d.pair()
    }

    IpcHandler {
        target: "bluetooth"
        function toggle(): void { root.open = !root.open }
        function status(): string {
            if (!root.available)
                return "no adapter"
            return root.enabled ? "on" : "off"
        }
    }
}

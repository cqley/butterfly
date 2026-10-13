pragma Singleton
import "../core"
import "../notifications"
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
        return displayName(a).localeCompare(displayName(b))
    }

    function named(d) {
        return !!d && !!d.name && d.name !== "" && d.name !== d.address
    }

    function displayName(d) {
        if (!d)
            return ""
        if (named(d))
            return d.name
        if (d.deviceName && d.deviceName !== d.address)
            return d.deviceName
        return "unknown device"
    }

    readonly property var items: {
        if (!available)
            return []
        const list = [...adapter.devices.values].filter(d => d.paired || d.connected || named(d))
        return list.sort(cmp)
    }

    readonly property bool busy: items.some(d =>
        d.state === BluetoothDeviceState.Connecting ||
        d.state === BluetoothDeviceState.Disconnecting ||
        d.pairing)

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
        if (d.connected) {
            d.disconnect()
            return
        }
        if (available)
            adapter.discovering = false
        if (d.paired)
            d.connect()
        else
            d.pair()
    }

    Instantiator {
        model: root.available ? root.adapter.devices : null

        Connections {
            required property var modelData
            target: modelData
            function onConnectedChanged() {
                if (!modelData.connected || root.open)
                    return
                const name = root.displayName(modelData)
                const body = modelData.batteryAvailable ? `${name} · ${Math.round(modelData.battery * 100)}%` : name
                Notifs.pushSystem("connected", body, false, "bluetooth")
            }
        }
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

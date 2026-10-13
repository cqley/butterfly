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
        if (!d)
            return false
        if (d.name && d.name !== "" && d.name !== d.address)
            return true
        return !!d.deviceName && d.deviceName !== "" && d.deviceName !== d.address
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

    property int devicesVersion: 0

    readonly property var items: {
        devicesVersion
        if (!available)
            return []
        const list = [...adapter.devices.values].filter(d => d.paired || d.connected || named(d))
        return list.sort(cmp)
    }

    Connections {
        target: root.available ? root.adapter.devices : null
        function onValuesChanged() { root.devicesVersion++ }
    }

    readonly property bool busy: items.some(d =>
        d.state === BluetoothDeviceState.Connecting ||
        d.state === BluetoothDeviceState.Disconnecting ||
        d.pairing)

    onBusyChanged: {
        if (!busy) {
            connectTimeout.stop()
            connecting = null
            if (open && available)
                adapter.discovering = true
        }
    }

    property var connecting: null

    Timer {
        id: connectTimeout
        interval: Theme.btTimeout
        onTriggered: {
            const d = root.connecting
            root.connecting = null
            if (!d)
                return
            if (d.pairing)
                d.cancelPair()
            else if (d.state === BluetoothDeviceState.Connecting)
                d.disconnect()
        }
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
        if (d.connected) {
            d.disconnect()
            return
        }
        if (available)
            adapter.discovering = false
        connecting = d
        connectTimeout.restart()
        if (d.paired)
            d.connect()
        else
            d.pair()
    }

    property var pendingConnects: []

    Timer {
        id: connectNotifyDelay
        interval: 1200
        onTriggered: {
            if (root.pendingConnects.length === 0)
                return
            const d = root.pendingConnects.shift()
            if (d && d.connected && !root.open) {
                const name = root.displayName(d)
                const level = d.batteryAvailable ? d.battery : -1
                const body = level >= 0 ? `${name} · ${Math.round(level * 100)}%` : name
                Notifs.pushSystem("connected", body, true, "bluetooth", false, level)
            }
            if (root.pendingConnects.length > 0)
                connectNotifyDelay.restart()
        }
    }

    Instantiator {
        model: root.available ? root.adapter.devices : null

        Connections {
            required property var modelData
            target: modelData
            function onConnectedChanged() {
                if (root.open)
                    return
                if (modelData.connected) {
                    root.pendingConnects.push(modelData)
                    if (!connectNotifyDelay.running)
                        connectNotifyDelay.restart()
                } else {
                    Notifs.pushSystem("disconnected", root.displayName(modelData), false, "bluetooth")
                }
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

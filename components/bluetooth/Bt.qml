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
    readonly property bool blocked: available && adapter.state === BluetoothAdapterState.Blocked
    property bool powering: false

    readonly property string title: {
        if (!available)
            return "no adapter"
        if (blocked)
            return "bluetooth blocked"
        if (adapter.state === BluetoothAdapterState.Enabling)
            return "turning on…"
        if (adapter.state === BluetoothAdapterState.Disabling)
            return "turning off…"
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

    property var order: []
    property var items: []

    function rebuild() {
        if (!available) {
            items = []
            return
        }
        const devs = [...adapter.devices.values].filter(d => d.paired || d.connected || named(d))
        const pos = Object.create(null)
        for (let i = 0; i < order.length; i++)
            pos[order[i]] = i
        const kept = []
        const fresh = []
        for (const d of devs) {
            if (pos[d.address] === undefined)
                fresh.push(d)
            else
                kept.push(d)
        }
        kept.sort((a, b) => pos[a.address] - pos[b.address])
        fresh.sort(cmp)
        const out = kept.concat(fresh)
        order = out.map(d => d.address)
        items = out
    }

    Component.onCompleted: rebuild()

    Connections {
        target: root.available ? root.adapter.devices : null
        function onValuesChanged() { root.rebuild() }
    }

    Connections {
        target: root.available ? root.adapter : null
        function onStateChanged() { root.settlePower() }
        function onEnabledChanged() {
            root.settlePower()
            root.syncScan()
        }
    }

    function syncScan() {
        if (!available || !enabled)
            return
        const want = open && !busy
        if (adapter.discovering !== want)
            adapter.discovering = want
    }

    function settlePower() {
        if (!available)
            return
        if (adapter.state === BluetoothAdapterState.Enabling || adapter.state === BluetoothAdapterState.Disabling)
            return
        powerSettle.stop()
        powering = false
        syncScan()
    }

    Timer {
        id: powerSettle
        interval: Theme.btPowerSettle
        onTriggered: {
            root.powering = false
            root.syncScan()
        }
    }

    readonly property bool busy: items.some(d =>
        d.state === BluetoothDeviceState.Connecting ||
        d.state === BluetoothDeviceState.Disconnecting ||
        d.pairing)

    onBusyChanged: {
        if (!busy) {
            connectTimeout.stop()
            connecting = null
        }
        syncScan()
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
        if (open) {
            Modal.claim("bluetooth")
            order = []
            rebuild()
        }
        syncScan()
    }

    function toggleAdapter() {
        if (!available || blocked || powering)
            return
        const on = !adapter.enabled
        powering = true
        powerSettle.restart()
        adapter.enabled = on
        if (!open)
            Notifs.pushSystem(on ? "bluetooth on" : "bluetooth off", "", on, "bluetooth")
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
        return ""
    }

    function pick(d) {
        if (!d || busy)
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
        interval: Theme.btBatteryWait
        onTriggered: {
            if (root.pendingConnects.length === 0)
                return
            const d = root.pendingConnects.shift()
            if (d && d.connected && !root.open) {
                const name = root.displayName(d)
                const level = d.batteryAvailable ? d.battery : -1
                Notifs.pushSystem("connected", name, true, "bluetooth", false, level)
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
                } else if (!root.powering && root.enabled) {
                    Notifs.pushSystem("disconnected", root.displayName(modelData), false, "bluetooth")
                }
            }
        }
    }

    IpcHandler {
        target: "bluetooth"
        function toggle(): void { root.open = !root.open }
        function power(): void {
            if (!root.available) {
                Notifs.pushSystem("bluetooth unavailable", "no adapter found", false, "bluetooth", true)
                return
            }
            if (root.blocked) {
                Notifs.pushSystem("bluetooth unavailable", "blocked by hardware", false, "bluetooth", true)
                return
            }
            root.toggleAdapter()
        }
        function status(): string {
            if (!root.available)
                return "no adapter"
            if (root.blocked)
                return "blocked"
            return root.enabled ? "on" : "off"
        }
    }
}

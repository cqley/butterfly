pragma Singleton
import "../core"
import "../notifications"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    property bool shown: true
    property bool ringShown: true
    property string lastPowerConnection: ""
    property int lastPercent: -1
    property bool chargingSeen: false
    property bool fullNotified: false

    property bool testMode: false
    property real testPct: 0.8
    property bool testCharging: false

    readonly property var device: UPower.displayDevice
    readonly property bool available: root.testMode || (!!device && device.ready && device.isLaptopBattery)
    readonly property real pct: {
        if (root.testMode)
            return Math.max(0, Math.min(1, root.testPct))
        if (!root.available)
            return 0
        const value = Number(root.device.percentage)
        return isFinite(value) ? Math.max(0, Math.min(1, value)) : 0
    }
    readonly property int percent: Math.round(root.pct * 100)
    readonly property color tone: Theme.batTone(root.pct)
    readonly property string powerConnection: root.testMode
        ? (root.testCharging ? "external" : "battery")
        : root.connectionForState(root.available && root.device ? root.device.state : null)
    readonly property string stablePowerConnection:
        root.powerConnection !== "" ? root.powerConnection : root.lastPowerConnection
    readonly property bool pluggedIn: root.stablePowerConnection === "external"

    function connectionForState(state) {
        switch (state) {
        case UPowerDeviceState.PendingCharge:
        case UPowerDeviceState.Charging:
        case UPowerDeviceState.FullyCharged:
            return "external"
        case UPowerDeviceState.PendingDischarge:
        case UPowerDeviceState.Discharging:
        case UPowerDeviceState.Empty:
            return "battery"
        default:
            return ""
        }
    }

    function isChargingState(state) {
        return state === UPowerDeviceState.PendingCharge || state === UPowerDeviceState.Charging
    }

    function isChargedState(state) {
        return state === UPowerDeviceState.FullyCharged
    }

    function syncPowerConnection() {
        if (root.testMode)
            return
        if (!root.available)
            return

        const connection = root.powerConnection
        const powerState = root.device.state
        const percent = root.percent
        const previousConnection = root.lastPowerConnection
        const previousPercent = root.lastPercent
        const charging = root.isChargingState(powerState)
        const reachedFull = !root.fullNotified && percent >= 100 && (
            previousConnection === "external" && previousPercent >= 0 && previousPercent < 100 && charging ||
            root.chargingSeen && root.isChargedState(powerState)
        )

        if (connection !== "" && connection !== previousConnection) {
            root.lastPowerConnection = connection
            if (previousConnection !== "") {
                Notifs.pushSystem(
                    connection === "external" ? "charger connected" : "charger disconnected",
                    connection === "external"
                        ? percent >= 100
                            ? `battery full · ${percent}%`
                            : `battery charging · ${percent}%`
                        : `running on battery · ${percent}%`,
                    connection === "external",
                    "battery",
                    false,
                    root.pct
                )
            }
            if (connection === "battery") {
                root.chargingSeen = false
                root.fullNotified = false
            }
        }

        if (charging)
            root.chargingSeen = true

        if (reachedFull) {
            root.chargingSeen = false
            root.fullNotified = true
            Notifs.pushSystem("battery full", `charging complete · ${percent}%`, true, "battery", false, root.pct)
        }

        root.lastPercent = percent
    }

    function resetPowerConnection() {
        root.lastPowerConnection = ""
        root.lastPercent = -1
        root.chargingSeen = false
        root.fullNotified = false
        root.syncPowerConnection()
    }

    function toggle() {
        root.shown = !root.shown
    }

    function toggleRing() {
        root.ringShown = !root.ringShown
    }

    Component.onCompleted: root.syncPowerConnection()
    onDeviceChanged: root.resetPowerConnection()

    Connections {
        target: root.device
        function onReadyChanged() { root.syncPowerConnection() }
        function onIsLaptopBatteryChanged() { root.resetPowerConnection() }
        function onStateChanged() { root.syncPowerConnection() }
        function onPercentageChanged() { root.syncPowerConnection() }
    }

    IpcHandler {
        target: "battery"
        function toggle(): void { root.toggle() }
        function ringToggle(): void { root.toggleRing() }
        function status(): string {
            const base = !root.testMode
                ? ""
                : `test · ${root.percent}% · ${root.testCharging ? "charging" : "battery"} · `
            return `${base}icon ${root.shown ? "on" : "off"} · ring ${root.ringShown ? "on" : "off"}`
        }
        function test(): void { root.testMode = !root.testMode }
        function testPct(value: int): void { root.testPct = Math.max(0, Math.min(100, value)) / 100 }
        function testUp(): void { root.testPct = Math.min(1, root.testPct + 0.1) }
        function testDown(): void { root.testPct = Math.max(0, root.testPct - 0.1) }
        function testCharging(): void { root.testCharging = !root.testCharging }
    }
}

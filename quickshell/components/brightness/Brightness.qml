pragma Singleton
import "../core"
import "../mixer"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool scanned: false
    property int screenCount: 0
    property bool probed: false
    property bool backlit: false
    property int writing: -1
    property int fetchBus: 0
    property var queue: []
    property alias devices: devs

    readonly property int count: devs.count

    Component.onCompleted: refresh()

    Connections {
        target: Quickshell
        function onScreensChanged() { root.refresh() }
    }

    ListModel { id: devs }

    function clamp(v) {
        return Math.max(0, Math.min(1, v))
    }

    function find(kind, bus) {
        for (let i = 0; i < devs.count; i++)
            if (devs.get(i).kind === kind && devs.get(i).bus === bus)
                return i
        return -1
    }

    function enqueue(bus) {
        if (queue.indexOf(bus) < 0 && !(fetch.running && fetchBus === bus))
            queue.push(bus)
    }

    function held(i) {
        return devs.get(i).dirty || (writer.running && writing === i)
    }

    function home() {
        const want = Theme.screen.toLowerCase()
        for (let i = 0; i < devs.count; i++)
            if (devs.get(i).label === want)
                return i
        return 0
    }

    function refresh() {
        for (let i = 0; i < devs.count; i++) {
            const d = devs.get(i)
            if (d.kind === "ddc" && !d.ready)
                enqueue(d.bus)
        }
        if (!scanned || count === 0 || screenCount !== Quickshell.screens.length || queue.length > 0)
            settle.restart()
        if (!probed || backlit)
            probe.running = true
    }

    function set(i, v) {
        if (i < 0 || i >= devs.count || !devs.get(i).ready)
            return
        const next = Math.max(Theme.brightMin / 100, clamp(v))
        if (next === devs.get(i).value)
            return
        devs.setProperty(i, "value", next)
        devs.setProperty(i, "dirty", true)
        flush()
    }

    function nudge(i, d) {
        if (i >= 0 && i < devs.count)
            set(i, (Math.round(devs.get(i).value * 100) + d) / 100)
    }

    function flush() {
        if (writer.running)
            return
        for (let i = 0; i < devs.count; i++) {
            const d = devs.get(i)
            if (!d.dirty)
                continue
            devs.setProperty(i, "dirty", false)
            writing = i
            writer.command = d.kind === "ddc"
                ? ["ddcutil", "--bus", String(d.bus), "setvcp", "10", String(Math.round(d.value * d.vcpMax))]
                : ["brightnessctl", "-q", "-c", "backlight", "set", Math.round(d.value * 100) + "%"]
            writer.running = true
            return
        }
    }

    function pump() {
        if (fetch.running || queue.length === 0)
            return
        fetchBus = queue.shift()
        fetch.running = true
    }

    function onProbe(text) {
        const p = text.trim().split("\n")[0].split(",")
        probed = true
        backlit = p.length >= 5
        const i = find("backlight", 0)
        if (!backlit) {
            if (i >= 0)
                devs.remove(i)
            return
        }
        const v = clamp(parseInt(p[3]) / 100)
        if (i < 0)
            devs.insert(0, { kind: "backlight", bus: 0, label: "internal", value: v, vcpMax: 100, ready: true, dirty: false })
        else if (!held(i))
            devs.setProperty(i, "value", v)
    }

    function place(label) {
        const all = Quickshell.screens
        for (let i = 0; i < all.length; i++)
            if (all[i].name.toLowerCase() === label)
                return all[i].x
        return 1e9
    }

    function onScan(text) {
        const lines = text.split("\n")
        const found = []
        let blk = null
        for (let i = 0; i < lines.length; i++) {
            const d = lines[i].match(/^Display (\d+)/)
            if (d || /^(Invalid|Busy) display/.test(lines[i])) {
                if (blk && blk.bus >= 0)
                    found.push(blk)
                blk = d ? { bus: -1, label: "display " + d[1] } : null
                continue
            }
            if (!blk)
                continue
            const b = lines[i].match(/I2C bus:\s+\/dev\/i2c-(\d+)/)
            if (b) {
                blk.bus = parseInt(b[1])
                continue
            }
            const c = lines[i].match(/DRM[ _]connector:\s+card\d+-(\S+)/)
            if (c)
                blk.label = c[1].toLowerCase()
        }
        if (blk && blk.bus >= 0)
            found.push(blk)
        found.sort((a, b) => place(a.label) - place(b.label))
        for (let i = devs.count - 1; i >= 0; i--)
            if (devs.get(i).kind === "ddc" && !found.some(f => f.bus === devs.get(i).bus))
                devs.remove(i)
        for (let i = 0; i < found.length; i++) {
            if (find("ddc", found[i].bus) >= 0)
                continue
            devs.append({ kind: "ddc", bus: found[i].bus, label: found[i].label, value: 0, vcpMax: 100, ready: false, dirty: false })
            enqueue(found[i].bus)
        }
        scanned = true
        screenCount = Quickshell.screens.length
        pump()
    }

    function onFetch(text) {
        const i = find("ddc", fetchBus)
        const m = text.match(/VCP 10 C (\d+) (\d+)/)
        if (i >= 0 && m && !held(i)) {
            const max = Math.max(1, parseInt(m[2]))
            devs.setProperty(i, "vcpMax", max)
            devs.setProperty(i, "value", clamp(parseInt(m[1]) / max))
            devs.setProperty(i, "ready", true)
        }
        pump()
    }

    function onWrite(code) {
        if (code === 0 || writing < 0 || writing >= devs.count)
            return
        const d = devs.get(writing)
        if (d.kind === "backlight") {
            probe.running = true
            return
        }
        devs.setProperty(writing, "ready", false)
        enqueue(d.bus)
        settle.restart()
    }

    Timer {
        id: settle
        interval: Theme.speed
        onTriggered: {
            if (!root.scanned || root.count === 0 || root.screenCount !== Quickshell.screens.length)
                scan.running = true
            else
                root.pump()
        }
    }

    Process {
        id: probe
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        stdout: StdioCollector {}
        onRunningChanged: if (!running) root.onProbe(stdout.text)
    }

    Process {
        id: scan
        command: ["ddcutil", "detect"]
        stdout: StdioCollector {}
        onRunningChanged: if (!running) root.onScan(stdout.text)
    }

    Process {
        id: fetch
        command: ["ddcutil", "--bus", String(root.fetchBus), "getvcp", "10", "--brief"]
        stdout: StdioCollector {}
        onRunningChanged: if (!running) root.onFetch(stdout.text)
    }

    Process {
        id: writer
        onExited: code => root.onWrite(code)
        onRunningChanged: if (!running) root.flush()
    }

    IpcHandler {
        target: "brightness"
        function toggle(): void { Mixer.open = !Mixer.open }
        function status(): string {
            if (root.count === 0)
                return root.scanned ? "unavailable" : "not probed"
            const out = []
            for (let i = 0; i < root.count; i++) {
                const d = root.devices.get(i)
                out.push(d.label + " " + Theme.pctOrUnavailable(d.ready, d.value))
            }
            return out.join(", ")
        }
    }
}

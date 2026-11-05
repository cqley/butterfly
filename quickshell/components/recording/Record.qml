pragma Singleton
import "../core"
import "../notifications"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false
    readonly property bool active: proc.running || pending !== null
    property string backend: ""
    property string bin: ""
    property string lastFile: ""
    property string lastError: ""
    property string targetLabel: ""
    property string checkFile: ""
    property double startedAt: 0
    property int elapsedSec: 0
    property var items: []
    property var pending: null
    property bool intentional: false
    readonly property bool canMic: backend !== ""
    readonly property bool canDesktopAudio: backend === "gsr"
    readonly property bool canCursor: backend === "gsr" || backend === "wl"
    readonly property bool canFps: backend === "gsr"
    readonly property string backendLabel: {
        if (backend === "gsr")
            return "gpu-screen-recorder"
        if (backend === "wf")
            return "wf-recorder"
        if (backend === "wl")
            return "wl-screenrec"
        return "not found"
    }
    readonly property string optsLabel: {
        const a = []
        if (canDesktopAudio && Theme.recordDesktopAudio)
            a.push("desktop")
        if (canMic && Theme.recordMic)
            a.push("mic")
        const cur = canCursor ? (Theme.recordCursor ? "yes" : "no") : "n/a"
        return "audio:" + (a.length ? a.join("+") : "none") + " cursor:" + cur
    }
    readonly property string clock: {
        const m = Math.floor(elapsedSec / 60)
        const s = elapsedSec % 60
        return m + ":" + String(s).padStart(2, "0")
    }

    onOpenChanged: if (open) {
        Modal.claim("record")
        refresh()
    }

    onActiveChanged: if (open)
        refresh()

    function toggle() {
        open = !open
    }

    function notify(title, body, bad) {
        Notifs.pushSystem(title, body, false, "rec", bad)
    }

    function fail(title, msg) {
        lastError = msg
        notify(title, msg, true)
    }

    function stop() {
        pending = null
        if (!proc.running)
            return
        intentional = true
        proc.signal(2)
        settle.restart()
    }

    function refresh() {
        const list = []
        if (active)
            list.push({ kind: "stop", label: "stop recording", value: "" })
        const screens = Quickshell.screens
        for (let i = 0; i < screens.length; i++)
            list.push({ kind: "monitor", label: screens[i].name, value: screens[i].name })
        if (backend === "gsr")
            list.push({ kind: "portal", label: "portal", value: "portal" })
        items = list
    }

    function pick(item) {
        if (!item)
            return
        open = false
        if (item.kind === "stop") {
            stop()
            return
        }
        if (proc.running) {
            pending = item
            intentional = true
            proc.signal(2)
            settle.restart()
            return
        }
        start(item)
    }

    function gsrCmd(target, out) {
        const a = [bin, "-w", target, "-f", String(Theme.recordFps)]
        const srcs = []
        if (Theme.recordDesktopAudio)
            srcs.push("default_output")
        if (Theme.recordMic)
            srcs.push("default_input")
        if (srcs.length)
            a.push("-a", srcs.join("|"))
        if (!Theme.recordCursor)
            a.push("-cursor", "no")
        if (target === "portal")
            a.push("-restore-portal-session", "yes")
        return a.concat(["-o", out])
    }

    function cmd(item, mon, out) {
        if (backend === "gsr")
            return gsrCmd(item.kind === "portal" ? "portal" : mon, out)
        if (backend === "wl") {
            const a = [bin, "-o", mon, "-f", out]
            if (Theme.recordMic)
                a.push("--audio")
            if (!Theme.recordCursor)
                a.push("--no-cursor")
            return a
        }
        const a = [bin, "-y", "-f", out, "-o", mon]
        if (Theme.recordMic)
            a.push("-a")
        return a
    }

    function start(item) {
        if (!item)
            return
        if (bin === "") {
            fail("recording unavailable", "no recorder found")
            return
        }
        if (backend !== "gsr" && backend !== "wf" && backend !== "wl") {
            fail("recording unavailable", "recordBackend required")
            return
        }
        if (item.kind === "portal" && backend !== "gsr") {
            fail("recording unavailable", "portal requires gsr")
            return
        }
        lastError = ""
        intentional = false
        const stamp = Qt.formatDateTime(new Date(), Theme.stampFormat)
        const out = Theme.recordDir + "/" + stamp + ".mp4"
        const mon = item.kind === "monitor" ? item.value : Theme.screen
        lastFile = out
        targetLabel = item.label
        startedAt = Date.now()
        elapsedSec = 0
        proc.exec(cmd(item, mon, out))
    }

    function resume() {
        const item = pending
        pending = null
        start(item)
    }

    function ensureDir() {
        Quickshell.execDetached(["mkdir", "-p", Theme.recordDir])
    }

    function verify(file) {
        if (file === "" || check.running)
            return
        checkFile = file
        check.running = true
    }

    Process {
        id: detect
        command: ["sh", "-lc", "for b in gpu-screen-recorder wf-recorder wl-screenrec; do p=$(command -v $b) && echo \"$b $p\" && break; done; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                const i = t.indexOf(" ")
                const kinds = { "gpu-screen-recorder": "gsr", "wf-recorder": "wf", "wl-screenrec": "wl" }
                root.backend = i > 0 ? kinds[t.slice(0, i)] || "" : ""
                root.bin = root.backend !== "" ? t.slice(i + 1) : ""
                if (root.backend === "")
                    root.lastError = "no recorder found"
                if (root.open)
                    root.refresh()
            }
        }
    }

    Process {
        id: proc
        onExited: code => {
            settle.stop()
            const file = root.lastFile
            const wanted = root.intentional
            root.intentional = false
            if (root.pending)
                Qt.callLater(root.resume)
            if (code !== 0 && !wanted) {
                root.fail("recording failed", "exited " + code)
                return
            }
            root.verify(file)
        }
    }

    Process {
        id: check
        command: ["sh", "-c", "test -s \"$1\"", "sh", root.checkFile]
        onExited: code => {
            if (code === 0)
                root.notify("recording saved", root.checkFile, false)
            else
                root.fail("recording failed", "no output file")
        }
    }

    Timer {
        id: tick
        interval: Theme.recordTick
        repeat: true
        running: proc.running
        onTriggered: root.elapsedSec = Math.floor((Date.now() - root.startedAt) / 1000)
    }

    Timer {
        id: settle
        interval: Theme.recordStopGrace
        onTriggered: {
            if (proc.running)
                proc.signal(15)
        }
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (root.open)
                root.refresh()
        }
    }

    Connections {
        target: Theme
        function onRecordDirChanged() {
            root.ensureDir()
        }
    }

    Component.onCompleted: {
        root.ensureDir()
        if (Theme.recordBin !== "") {
            root.bin = Theme.recordBin
            root.backend = Theme.recordBackend
            if (root.backend !== "gsr" && root.backend !== "wf" && root.backend !== "wl")
                root.lastError = "recordBackend required"
        } else {
            detect.running = true
        }
    }

    IpcHandler {
        target: "record"
        function toggle(): void { root.toggle() }
        function stop(): void { root.stop() }
        function status(): string {
            if (root.pending)
                return "switching"
            if (root.active)
                return "recording " + root.backend + " " + root.clock + " " + root.targetLabel + " " + root.optsLabel + " " + root.lastFile
            if (root.lastError !== "")
                return "idle " + root.backend + " " + root.bin + " err:" + root.lastError
            return "idle " + (root.bin !== "" ? root.backend + " " + root.optsLabel + " " + root.bin : "no-backend")
        }
    }
}

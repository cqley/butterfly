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
        if (backend === "gsr" && item.kind === "portal")
            proc.exec([bin, "-w", "portal", "-f", String(Theme.recordFps), "-a", "default_output", "-restore-portal-session", "yes", "-o", out])
        else if (backend === "gsr")
            proc.exec([bin, "-w", mon, "-f", String(Theme.recordFps), "-a", "default_output", "-o", out])
        else if (backend === "wl")
            proc.exec([bin, "-o", mon, "-f", out])
        else
            proc.exec([bin, "-a", "-y", "-f", out, "-o", mon])
    }

    function resume() {
        const item = pending
        pending = null
        start(item)
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
        running: root.active
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

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Theme.recordDir])
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
                return "recording " + root.backend + " " + root.clock + " " + root.targetLabel + " " + root.lastFile
            if (root.lastError !== "")
                return "idle " + root.backend + " " + root.bin + " err:" + root.lastError
            return "idle " + (root.bin !== "" ? root.backend + " " + root.bin : "no-backend")
        }
    }
}

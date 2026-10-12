pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false
    readonly property bool active: proc.running
    property string backend: ""
    property string bin: ""
    property string lastFile: ""
    property string lastError: ""
    property string targetLabel: ""
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
        if (open)
            refresh()
    }

    onActiveChanged: if (open)
        refresh()

    function toggle() {
        open = !open
    }

    function stop() {
        if (!proc.running)
            return
        intentional = true
        pending = null
        proc.signal(2)
        settle.restart()
    }

    function refresh() {
        const list = []
        if (proc.running)
            list.push({ kind: "stop", label: "stop recording", value: "" })
        const screens = Quickshell.screens
        for (let i = 0; i < screens.length; i++) {
            const s = screens[i]
            list.push({ kind: "monitor", label: s.name, value: s.name })
        }
        if (backend === "gsr")
            list.push({ kind: "portal", label: "portal", value: "portal" })
        items = list
    }

    function pick(item) {
        if (!item)
            return
        if (item.kind === "stop") {
            stop()
            open = false
            return
        }
        if (proc.running) {
            pending = item
            intentional = true
            proc.signal(2)
            settle.restart()
            open = false
            return
        }
        start(item)
        open = false
    }

    function start(item) {
        if (Theme.recordBin !== "") {
            bin = Theme.recordBin
            backend = Theme.recordBackend
        }
        if (bin === "") {
            lastError = "no recorder found"
            return
        }
        if (backend !== "gsr" && backend !== "wf" && backend !== "wl") {
            lastError = "recordBackend required"
            return
        }
        if (item.kind === "portal" && backend !== "gsr") {
            lastError = "portal requires gsr"
            return
        }
        lastError = ""
        intentional = false
        const stamp = Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss")
        const out = Theme.recordDir + "/rec-" + stamp + ".mp4"
        lastFile = out
        targetLabel = item.label
        startedAt = Date.now()
        elapsedSec = 0
        Quickshell.execDetached(["mkdir", "-p", Theme.recordDir])

        if (backend === "gsr") {
            let src = Theme.screen
            if (item.kind === "monitor")
                src = item.value
            else if (item.kind === "portal")
                src = "portal"
            if (src === "portal")
                proc.exec([bin, "-w", "portal", "-f", String(Theme.recordFps), "-a", "default_output", "-restore-portal-session", "yes", "-o", out])
            else
                proc.exec([bin, "-w", src, "-f", String(Theme.recordFps), "-a", "default_output", "-o", out])
        } else if (backend === "wl") {
            const mon = item.kind === "monitor" ? item.value : Theme.screen
            proc.exec([bin, "-o", mon, "-f", out])
        } else {
            const mon = item.kind === "monitor" ? item.value : Theme.screen
            proc.exec([bin, "-a", "-y", "-f", out, "-o", mon])
        }
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
        onExited: (code, status) => {
            settle.stop()
            if (root.pending) {
                const item = root.pending
                root.pending = null
                root.intentional = false
                Qt.callLater(() => root.start(item))
                return
            }
            if (code !== 0 && !root.intentional && root.lastError === "")
                root.lastError = "exited " + code
            root.intentional = false
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
            if (root.active)
                return "recording " + root.backend + " " + root.clock + " " + root.targetLabel + " " + root.lastFile
            if (root.pending)
                return "switching"
            if (root.lastError !== "")
                return "idle " + root.backend + " " + root.bin + " err:" + root.lastError
            return "idle " + (root.bin !== "" ? root.backend + " " + root.bin : "no-backend")
        }
    }
}


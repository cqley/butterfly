pragma Singleton
import "../core"
import "../notifications"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false
    property bool picking: false
    property bool targeting: false
    property string targetKind: ""
    property var targets: []
    property int targetIndex: -1
    property string grimBin: ""
    property string copyBin: ""
    property string lastFile: ""
    property bool needsCopy: false
    property var items: []
    readonly property bool busy: proc.running || picking || targeting || settle.running || check.running || copy.running || clientsQuery.running || activeQuery.running

    onOpenChanged: if (open) {
        Modal.claim("screenshot")
        refresh()
    }

    function toggle() {
        if (picking || targeting)
            return
        open = !open
    }

    function refresh() {
        const list = []
        if (grimBin !== "") {
            list.push({ kind: "region", label: "region" })
            list.push({ kind: "window", label: "window" })
            list.push({ kind: "active", label: "active window" })
            if (Quickshell.screens.length > 0)
                list.push({ kind: "monitor", label: "monitor" })
        }
        items = list
    }

    function pick(item) {
        if (!item)
            return
        open = false
        if (item.kind === "region") {
            startRegion()
        } else if (item.kind === "window") {
            startWindowPick()
        } else if (item.kind === "monitor") {
            startMonitorPick()
        } else if (item.kind === "active") {
            settleCapture.restart()
        }
    }

    Timer {
        id: settleCapture
        interval: Theme.screenshotSettleDelay
        onTriggered: root.captureActive()
    }

    function notifySaved(clipboardFailed) {
        const body = clipboardFailed ? root.lastFile + " · clipboard unavailable" : root.lastFile + " · copied to clipboard"
        Notifs.pushSystem("screenshot saved", body, false, "shot")
    }

    function newFile() {
        const stamp = Qt.formatDateTime(new Date(), Theme.stampFormat)
        lastFile = Theme.screenshotDir + "/" + stamp + ".png"
        return lastFile
    }

    function captureBox(x, y, w, h) {
        const file = newFile()
        const geo = Math.round(x) + "," + Math.round(y) + " " + Math.round(w) + "x" + Math.round(h)
        needsCopy = true
        proc.exec([grimBin, "-g", geo, file])
    }

    function captureMonitor(name) {
        const file = newFile()
        needsCopy = true
        proc.exec([grimBin, "-o", name, file])
    }

    function captureActive() {
        if (grimBin === "") {
            Notifs.pushSystem("screenshot unavailable", "grim not found", false, "shot", true)
            return
        }
        if (busy)
            return
        activeQuery.running = true
    }

    Process {
        id: activeQuery
        command: ["hyprctl", "-j", "activewindow"]
        stdout: StdioCollector {
            onStreamFinished: {
                let d = null
                try {
                    d = JSON.parse(text)
                } catch (e) {
                    d = null
                }
                if (!d || !d.at || !d.size) {
                    Notifs.pushSystem("screenshot failed", "no active window", false, "shot", true)
                    return
                }
                root.captureBox(d.at[0], d.at[1], d.size[0], d.size[1])
            }
        }
    }

    // region (free drag)
    readonly property point offscreen: Qt.point(-100000, -100000)
    property point pressG: Qt.point(0, 0)
    property point curG: Qt.point(-100000, -100000)
    property bool dragging: false

    function startRegion() {
        if (busy)
            return
        if (grimBin === "") {
            Notifs.pushSystem("screenshot unavailable", "grim not found", false, "shot", true)
            return
        }
        dragging = false
        curG = offscreen
        picking = true
        cursorPos.running = true
    }

    function cancelRegion() {
        picking = false
        dragging = false
    }

    function updatePointer(gx, gy) {
        curG = Qt.point(gx, gy)
    }

    function beginDrag() {
        if (!picking || dragging)
            return
        pressG = curG
        dragging = true
    }

    function endDrag() {
        if (!dragging)
            return
        const rx = Math.min(pressG.x, curG.x)
        const ry = Math.min(pressG.y, curG.y)
        const rw = Math.abs(curG.x - pressG.x)
        const rh = Math.abs(curG.y - pressG.y)
        if (rw >= Theme.regionMinSize && rh >= Theme.regionMinSize && !proc.running)
            captureBox(rx, ry, rw, rh)
        dragging = false
        picking = false
    }

    Process {
        id: cursorPos
        command: ["hyprctl", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                if (parts.length !== 2)
                    return
                const x = parseFloat(parts[0])
                const y = parseFloat(parts[1])
                if (isFinite(x) && isFinite(y) && root.picking && !root.dragging)
                    root.curG = Qt.point(x, y)
            }
        }
    }

    // window / monitor targeting (hover or keyboard cycle, then confirm)
    function startMonitorPick() {
        if (busy)
            return
        if (grimBin === "") {
            Notifs.pushSystem("screenshot unavailable", "grim not found", false, "shot", true)
            return
        }
        const screens = Quickshell.screens.slice().sort((a, b) => a.x - b.x)
        if (screens.length === 0)
            return
        targets = screens.map(s => ({ x: s.x, y: s.y, w: s.width, h: s.height, name: s.name }))
        targetKind = "monitor"
        targetIndex = 0
        targeting = true
        targetSeed.running = true
    }

    function startWindowPick() {
        if (busy)
            return
        if (grimBin === "") {
            Notifs.pushSystem("screenshot unavailable", "grim not found", false, "shot", true)
            return
        }
        clientsQuery.running = true
    }

    Process {
        id: clientsQuery
        command: ["sh", "-c", "hyprctl -j monitors; echo '@@split@@'; hyprctl -j clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("@@split@@")
                if (parts.length !== 2)
                    return
                let monitors = []
                let clients = []
                try {
                    monitors = JSON.parse(parts[0])
                    clients = JSON.parse(parts[1])
                } catch (e) {
                    return
                }
                const visibleWs = new Set()
                for (const m of monitors) {
                    if (m.activeWorkspace)
                        visibleWs.add(m.activeWorkspace.id)
                    if (m.specialWorkspace && m.specialWorkspace.id !== 0)
                        visibleWs.add(m.specialWorkspace.id)
                }
                const list = []
                for (const c of clients) {
                    if (!c.mapped || c.hidden)
                        continue
                    if (!c.workspace || !visibleWs.has(c.workspace.id))
                        continue
                    list.push({ x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1] })
                }
                if (list.length === 0) {
                    Notifs.pushSystem("screenshot unavailable", "no window to capture", false, "shot", true)
                    return
                }
                root.targets = list
                root.targetKind = "window"
                root.targetIndex = 0
                root.targeting = true
                targetSeed.running = true
            }
        }
    }

    Process {
        id: targetSeed
        command: ["hyprctl", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                if (parts.length !== 2)
                    return
                const x = parseFloat(parts[0])
                const y = parseFloat(parts[1])
                if (isFinite(x) && isFinite(y) && root.targeting)
                    root.hoverTarget(x, y)
            }
        }
    }

    function hoverTarget(gx, gy) {
        for (let i = 0; i < targets.length; i++) {
            const t = targets[i]
            if (gx >= t.x && gx <= t.x + t.w && gy >= t.y && gy <= t.y + t.h) {
                targetIndex = i
                return
            }
        }
    }

    function cycleTarget(delta) {
        if (targets.length === 0)
            return
        targetIndex = (targetIndex + delta + targets.length) % targets.length
    }

    function confirmTargetPick() {
        if (targetIndex < 0 || targetIndex >= targets.length || proc.running) {
            cancelTargetPick()
            return
        }
        const t = targets[targetIndex]
        if (targetKind === "monitor")
            captureMonitor(t.name)
        else
            captureBox(t.x, t.y, t.w, t.h)
        targeting = false
        targetKind = ""
        targets = []
        targetIndex = -1
    }

    function cancelTargetPick() {
        if (!targeting)
            return
        targeting = false
        targetKind = ""
        targets = []
        targetIndex = -1
    }

    Process {
        id: detect
        command: ["sh", "-lc", "for b in grim wl-copy; do p=$(command -v $b) && echo \"$b $p\"; done; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {}
                for (const line of text.trim().split("\n")) {
                    if (!line)
                        continue
                    const i = line.indexOf(" ")
                    if (i > 0)
                        map[line.slice(0, i)] = line.slice(i + 1)
                }
                root.grimBin = map["grim"] || ""
                root.copyBin = map["wl-copy"] || ""
                if (root.open)
                    root.refresh()
            }
        }
    }

    Process {
        id: proc
        onExited: settle.restart()
    }

    Process {
        id: check
        command: ["sh", "-c", "test -f \"$1\"", "sh", root.lastFile]
        onExited: code => {
            if (code !== 0) {
                if (root.needsCopy)
                    Notifs.pushSystem("screenshot failed", "grim exited nonzero", false, "shot", true)
                root.needsCopy = false
                return
            }
            if (root.needsCopy && root.copyBin !== "") {
                copy.running = true
            } else {
                root.notifySaved(root.needsCopy)
                root.needsCopy = false
            }
        }
    }

    Process {
        id: copy
        command: ["sh", "-c", "exec \"$0\" --type image/png < \"$1\"", root.copyBin, root.lastFile]
        onExited: code => {
            root.notifySaved(code !== 0)
            root.needsCopy = false
        }
    }

    Timer {
        id: settle
        interval: Theme.screenshotCheckDelay
        onTriggered: check.running = true
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Theme.screenshotDir])
        detect.running = true
    }

    IpcHandler {
        target: "screenshot"
        function toggle(): void { root.toggle() }
        function region(): void { root.startRegion() }
        function window(): void { root.startWindowPick() }
        function monitor(): void { root.startMonitorPick() }
        function active(): void { root.captureActive() }
        function cancel(): void {
            root.cancelRegion()
            root.cancelTargetPick()
        }
        function status(): string {
            if (root.picking || root.targeting)
                return "picking"
            if (root.busy)
                return "capturing"
            if (root.grimBin === "")
                return "no backend"
            return "idle " + root.grimBin
        }
    }
}

pragma Singleton
import "../core"
import "../notifications"
import QtQuick
import Quickshell
import Quickshell.Io

Menu {
    id: root
    name: "screenshot"
    ipc: false
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
    readonly property bool busy: proc.running || picking || targeting || holding || settle.running || check.running || copy.running || clientsQuery.running || activeQuery.running || pickQuery.running

    onOpenChanged: if (open) {
        refresh()
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (root.open)
                root.refresh()
        }
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
            if (Compositor.supportsWindowTargets || Compositor.supportsNativeWindowShot) {
                list.push({ kind: "window", label: "window" })
                list.push({ kind: "active", label: "active window" })
            }
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

    function captureNative(id) {
        const file = newFile()
        needsCopy = true
        proc.exec(Compositor.nativeWindowShotCmd(file, id))
    }

    function captureActive() {
        if (Compositor.supportsNativeWindowShot) {
            if (!busy)
                captureNative(null)
            return
        }
        if (grimBin === "") {
            Notifs.pushSystem("screenshot unavailable", "grim not found", false, "shot", true)
            return
        }
        if (!Compositor.supportsWindowTargets) {
            Notifs.pushSystem("screenshot unavailable", "active window capture needs " + Compositor.backend, false, "shot", true)
            return
        }
        if (busy)
            return
        activeQuery.running = true
    }

    Process {
        id: activeQuery
        command: Compositor.activeWindowCmd
        stdout: StdioCollector {
            onStreamFinished: {
                const d = Compositor.parseActiveWindow(text)
                if (!d) {
                    Notifs.pushSystem("screenshot failed", "no active window", false, "shot", true)
                    return
                }
                root.captureBox(d.x, d.y, d.w, d.h)
            }
        }
    }

    // region
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
        if (Compositor.supportsCursorSeed) {
            cursorPos.running = false
            cursorPos.running = true
        }
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
        if (rw >= Theme.regionMinSize && rh >= Theme.regionMinSize && !proc.running) {
            shot = Qt.rect(rx, ry, rw, rh)
            holding = true
            shotWait.restart()
        }
        dragging = false
        picking = false
    }

    property rect shot: Qt.rect(0, 0, 0, 0)
    property bool holding: false

    Timer {
        id: shotWait
        interval: Theme.regionShotWait
        onTriggered: root.captureBox(root.shot.x, root.shot.y, root.shot.width, root.shot.height)
    }

    Process {
        id: cursorPos
        command: Compositor.cursorPosCmd
        stdout: StdioCollector {
            onStreamFinished: {
                const p = Compositor.parseCursorPos(text)
                if (p && root.picking && !root.dragging)
                    root.curG = Qt.point(p.x, p.y)
            }
        }
    }

    // targeting
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
        if (Compositor.supportsCursorSeed) {
            targetSeed.running = false
            targetSeed.running = true
        }
    }

    function startWindowPick() {
        if (busy)
            return
        if (Compositor.supportsNativeWindowShot) {
            pickQuery.running = true
            return
        }
        if (grimBin === "") {
            Notifs.pushSystem("screenshot unavailable", "grim not found", false, "shot", true)
            return
        }
        if (!Compositor.supportsWindowTargets) {
            Notifs.pushSystem("screenshot unavailable", "window capture needs " + Compositor.backend, false, "shot", true)
            return
        }
        clientsQuery.running = true
    }

    Process {
        id: clientsQuery
        command: Compositor.windowListCmd
        stdout: StdioCollector {
            onStreamFinished: {
                const list = Compositor.parseWindowList(text)
                if (list.length === 0) {
                    Notifs.pushSystem("screenshot unavailable", "no window to capture", false, "shot", true)
                    return
                }
                root.targets = list
                root.targetKind = "window"
                root.targetIndex = 0
                root.targeting = true
                if (Compositor.supportsCursorSeed) {
                    targetSeed.running = false
                    targetSeed.running = true
                }
            }
        }
    }

    Process {
        id: pickQuery
        command: Compositor.pickWindowCmd
        stdout: StdioCollector {
            onStreamFinished: {
                const id = Compositor.parsePickedWindow(text)
                if (id !== null)
                    root.captureNative(id)
            }
        }
    }

    Process {
        id: targetSeed
        command: Compositor.cursorPosCmd
        stdout: StdioCollector {
            onStreamFinished: {
                const p = Compositor.parseCursorPos(text)
                if (p && root.targeting)
                    root.hoverTarget(p.x, p.y)
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
            if (proc.running)
                Notifs.pushSystem("screenshot skipped", "previous capture still running", false, "shot", true)
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

    Which {
        id: detect
        names: ["grim", "wl-copy"]
        onDone: {
            root.grimBin = found["grim"] || ""
            root.copyBin = found["wl-copy"] || ""
            if (root.open)
                root.refresh()
        }
    }

    Process {
        id: proc
        onExited: {
            root.holding = false
            settle.restart()
        }
    }

    Process {
        id: check
        command: ["sh", "-c", "test -s \"$1\"", "sh", root.lastFile]
        onExited: code => {
            if (code !== 0) {
                if (root.needsCopy)
                    Notifs.pushSystem("screenshot failed", "no output file", false, "shot", true)
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

    function report() {
        if (root.picking || root.targeting)
            return "picking"
        if (root.busy)
            return "capturing"
        if (root.grimBin === "")
            return "no backend"
        return "idle " + root.grimBin
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
        function status(): string { return root.status() }
    }
}

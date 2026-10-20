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
    property string bin: ""
    property string grimBin: ""
    property string copyBin: ""
    property string lastFile: ""
    property bool needsCopy: false
    property var items: []
    readonly property bool busy: proc.running || picking || settle.running || check.running || copy.running

    onOpenChanged: if (open) {
        Modal.claim("screenshot")
        refresh()
    }

    function toggle() {
        if (picking)
            return
        open = !open
    }

    function refresh() {
        const list = []
        if (grimBin !== "")
            list.push({ kind: "region", label: "region" })
        if (bin !== "") {
            list.push({ kind: "window", label: "window" })
            list.push({ kind: "active", label: "active window" })
            const screens = Quickshell.screens
            for (let i = 0; i < screens.length; i++)
                list.push({ kind: "output", label: screens[i].name, value: screens[i].name })
        }
        items = list
    }

    function pick(item) {
        if (!item)
            return
        open = false
        shoot(item)
    }

    function shoot(item) {
        if (item.kind === "region") {
            startRegion()
            return
        }
        if (item.kind !== "window" && item.kind !== "active" && item.kind !== "output")
            return
        if (bin === "") {
            Notifs.pushSystem("screenshot unavailable", "hyprshot not found", false, "shot", true)
            return
        }
        if (busy)
            return
        const stamp = Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss")
        const name = "shot-" + stamp + ".png"
        lastFile = Theme.screenshotDir + "/" + name
        const args = [bin, "-s", "-o", Theme.screenshotDir, "-f", name]
        if (item.kind === "window")
            args.push("-m", "window")
        else if (item.kind === "active")
            args.push("-m", "window", "-m", "active")
        else
            args.push("-m", "output", "-m", item.value)
        needsCopy = false
        proc.exec(args)
    }

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
        dragging = false
        const rx = Math.min(pressG.x, curG.x)
        const ry = Math.min(pressG.y, curG.y)
        const rw = Math.abs(curG.x - pressG.x)
        const rh = Math.abs(curG.y - pressG.y)
        if (rw >= Theme.regionMinSize && rh >= Theme.regionMinSize)
            finishRegion(Qt.rect(rx, ry, rw, rh))
        else
            cancelRegion()
    }

    function finishRegion(rect) {
        picking = false
        if (busy)
            return
        const stamp = Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss")
        const name = "shot-" + stamp + ".png"
        lastFile = Theme.screenshotDir + "/" + name
        const x = Math.round(rect.x)
        const y = Math.round(rect.y)
        const w = Math.round(rect.width)
        const h = Math.round(rect.height)
        const geo = x + "," + y + " " + w + "x" + h
        needsCopy = true
        proc.exec([grimBin, "-g", geo, lastFile])
    }

    function notifySaved(clipboardFailed) {
        const body = clipboardFailed ? root.lastFile + " · clipboard unavailable" : root.lastFile + " · copied to clipboard"
        Notifs.pushSystem("screenshot saved", body, false, "shot")
    }

    Process {
        id: detect
        command: ["sh", "-lc", "for b in hyprshot grim wl-copy; do p=$(command -v $b) && echo \"$b $p\"; done; true"]
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
                root.bin = Theme.screenshotBin !== "" ? Theme.screenshotBin : (map["hyprshot"] || "")
                root.grimBin = map["grim"] || ""
                root.copyBin = map["wl-copy"] || ""
                if (root.open)
                    root.refresh()
            }
        }
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
        function window(): void { root.shoot({ kind: "window" }) }
        function active(): void { root.shoot({ kind: "active" }) }
        function cancel(): void { root.cancelRegion() }
        function status(): string {
            if (root.picking)
                return "picking"
            if (root.busy)
                return "capturing"
            if (root.bin === "" && root.grimBin === "")
                return "no backend"
            return "idle " + (root.bin || root.grimBin)
        }
    }
}

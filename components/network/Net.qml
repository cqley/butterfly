pragma Singleton
import "../core"
import "../notifications"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false
    property bool enabled: true
    property string active: ""
    property string error: ""
    property string asking: ""
    property var list: []
    property bool busy: false
    property bool toggling: false
    property string pending: ""
    property string phase: ""
    property string target: ""
    property string activeConnection: ""
    property bool canceling: false
    property bool sent: false
    property bool timedOut: false
    property bool watch: false
    property bool askLocked: false
    property bool resolved: false
    property var order: []

    readonly property string title: {
        if (!enabled)
            return "wifi off"
        if (asking !== "")
            return asking
        if (phase === "connecting")
            return "connecting…"
        if (phase === "disconnecting")
            return "disconnecting…"
        if (active !== "")
            return active
        return "network"
    }

    onOpenChanged: if (open) {
        Modal.claim("net")
        if (!open)
            return
        asking = ""
        error = ""
        if (!busy) {
            pending = ""
            phase = ""
        }
        order = []
        refresh()
        if (enabled)
            rescan.running = true
        poll.restart()
        monitor.running = true
    } else {
        if (!watch) {
            poll.stop()
            monitor.running = false
        }
        if (asking !== "")
            cancelAsk()
        error = ""
        if (!busy) {
            pending = ""
            phase = ""
        }
    }

    onActiveChanged: {
        if (!resolved && busy && phase === "connecting" && target !== "" && active === target)
            finish(target)
        else if (watch && active !== "") {
            watch = false
            Notifs.pushSystem("connected", active, false, "net")
        }
    }

    function finish(name) {
        resolved = true
        kill.stop()
        if (up.running)
            up.signal(15)
        busy = false
        watch = false
        sent = false
        askLocked = false
        asking = ""
        error = ""
        target = ""
        pending = ""
        phase = ""
        settle.restart()
        Notifs.pushSystem("connected", name, false, "net")
        open = false
    }

    function needsSecret(err) {
        const t = err.toLowerCase()
        if (t === "")
            return false
        if (t.indexOf("connection activated") >= 0 || t.indexOf("successfully") >= 0)
            return false
        return t.indexOf("secrets were required") >= 0 || t.indexOf("no secrets provided") >= 0 || t.indexOf("802-11-wireless-security.psk") >= 0 || t.indexOf("password") >= 0 || t.indexOf("passphrase") >= 0 || t.indexOf("secret") >= 0
    }

    onWatchChanged: if (watch) {
        watchEnd.restart()
        poll.restart()
        monitor.running = true
    } else if (!open) {
        poll.stop()
        monitor.running = false
    }

    function refresh() {
        if (toggling)
            return
        if (!radio.running)
            radio.running = true
        if (!activeCon.running)
            activeCon.running = true
    }

    function toggleWifi() {
        if (toggling || busy)
            return
        const next = enabled ? "off" : "on"
        toggling = true
        enabled = next === "on"
        watch = enabled
        if (!enabled) {
            list = []
            order = []
            active = ""
            pending = ""
            phase = ""
        }
        radioSet.command = ["nmcli", "radio", "wifi", next]
        radioSet.running = true
    }

    function pick(item) {
        if (!item || busy || toggling || up.running)
            return
        watch = false
        error = ""
        if (item.active) {
            busy = true
            pending = item.ssid
            phase = "disconnecting"
            down.command = ["nmcli", "connection", "down", "id", item.connection]
            down.running = true
            return
        }
        if (asking === item.ssid)
            return
        busy = true
        pending = item.ssid
        phase = "connecting"
        asking = ""
        target = item.ssid
        askLocked = !!item.locked
        resolved = false
        sent = false
        up.command = ["nmcli", "device", "wifi", "connect", item.ssid]
        up.running = true
    }

    function submitPsk(psk) {
        if (asking === "" || psk === "" || busy || up.running)
            return
        error = ""
        busy = true
        pending = asking
        phase = "connecting"
        target = asking
        asking = ""
        resolved = false
        sent = true
        up.command = ["nmcli", "device", "wifi", "connect", target, "password", psk]
        up.running = true
    }

    function cancelAsk() {
        canceling = up.running
        sent = false
        if (up.running) {
            up.signal(15)
            kill.restart()
        }
        asking = ""
        error = ""
        busy = false
        target = ""
        pending = ""
        phase = ""
    }

    function clearPhase() {
        pending = ""
        phase = ""
    }

    function fields(line) {
        const out = [""]
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (c === "\\" && i + 1 < line.length)
                out[out.length - 1] += line[++i]
            else if (c === ":")
                out.push("")
            else
                out[out.length - 1] += c
        }
        return out
    }

    function rank(a, b) {
        if (a.active !== b.active)
            return a.active ? -1 : 1
        return b.signal - a.signal
    }

    function parseWifi(text) {
        const best = Object.create(null)
        const lines = text.trim().split("\n")
        let cur = ""
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (line === "")
                continue
            const p = fields(line)
            if (p.length < 4)
                continue
            const ssid = p[2]
            if (ssid === "" || ssid === "--")
                continue
            const active = p[0] === "yes"
            const sig = Math.max(0, Math.min(100, parseInt(p[1]) || 0)) / 100
            const sec = p[3]
            if (active)
                cur = ssid
            const prev = best[ssid]
            if (prev && !(active && !prev.active) && !(active === prev.active && sig > prev.signal))
                continue
            best[ssid] = {
                ssid: ssid,
                signal: sig,
                active: active,
                connection: active ? root.activeConnection : ssid,
                locked: sec !== "" && sec !== "--" && sec.toLowerCase().indexOf("open") < 0,
                security: sec
            }
        }
        if (asking !== "" && !best[asking]) {
            for (let i = 0; i < list.length; i++) {
                if (list[i].ssid === asking) {
                    best[asking] = list[i]
                    break
                }
            }
        }
        const pos = Object.create(null)
        for (let i = 0; i < order.length; i++)
            pos[order[i]] = i
        const kept = []
        const fresh = []
        for (const k in best) {
            if (pos[k] === undefined)
                fresh.push(best[k])
            else
                kept.push(best[k])
        }
        kept.sort((a, b) => pos[a.ssid] - pos[b.ssid])
        fresh.sort(rank)
        const out = kept.concat(fresh)
        order = out.map(r => r.ssid)
        list = out
        active = cur
    }

    Process {
        id: radioSet
        onExited: code => {
            root.toggling = false
            radio.running = true
            activeCon.running = true
        }
    }

    Process {
        id: radio
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.toggling)
                    return
                const t = text.trim().toLowerCase()
                root.enabled = t === "enabled"
                if (!root.enabled) {
                    root.list = []
                    root.active = ""
                    root.activeConnection = ""
                    root.pending = ""
                    root.phase = ""
                }
            }
        }
    }

    Process {
        id: activeCon
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                root.activeConnection = ""
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i] === "")
                        continue
                    const p = root.fields(lines[i])
                    if (p.length < 3 || p[1] !== "802-11-wireless")
                        continue
                    root.activeConnection = p[0]
                    break
                }
                if (root.enabled)
                    scan.running = true
            }
        }
    }

    Process {
        id: scan
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL,SSID,SECURITY", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.enabled)
                    root.parseWifi(text)
                else {
                    root.list = []
                    root.active = ""
                }
            }
        }
    }

    Process {
        id: rescan
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: late.restart()
    }

    Process {
        id: monitor
        running: false
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.refresh()
        }
        onExited: if (root.open || root.watch) monitorRestart.restart()
    }

    Timer {
        id: monitorRestart
        interval: Theme.netMonitorRestart
        onTriggered: if (root.open || root.watch) monitor.running = true
    }

    Timer {
        id: late
        interval: Theme.netRescanWait
        onTriggered: if (root.open) root.refresh()
    }

    Process {
        id: up
        stderr: StdioCollector {
            waitForEnd: false
        }
        onExited: code => {
            kill.stop()
            if (root.resolved) {
                root.canceling = false
                root.timedOut = false
                root.sent = false
                root.busy = false
                return
            }
            const canceled = root.canceling
            const timedOut = root.timedOut
            const wasSent = root.sent
            const name = root.target
            root.canceling = false
            root.timedOut = false
            root.sent = false
            root.busy = false
            if (canceled)
                return
            if (code === 0) {
                root.asking = ""
                root.error = ""
                root.target = ""
                root.phase = ""
                root.refresh()
                settle.restart()
                Notifs.pushSystem("connected", name, false, "net")
                root.open = false
                return
            }
            if (!timedOut && root.needsSecret(stderr.text) && root.askLocked) {
                root.asking = root.target
                root.phase = ""
                if (wasSent) {
                    root.error = "wrong password"
                    forget.command = ["nmcli", "connection", "delete", "id", root.target]
                    forget.running = true
                }
            }
            if (root.asking === "") {
                root.target = ""
                root.phase = ""
                root.pending = ""
                Notifs.pushSystem("can't connect", timedOut ? name + " · timed out" : name, false, "net", true)
                root.open = false
            }
            root.refresh()
        }
    }

    Process {
        id: forget
    }

    Process {
        id: down
        onExited: code => {
            root.busy = false
            root.phase = ""
            root.pending = ""
            root.refresh()
        }
    }

    Timer {
        id: guard
        interval: Theme.netTimeout
        running: up.running
        onTriggered: {
            if (up.running) {
                root.timedOut = true
                up.signal(15)
                kill.restart()
            }
        }
    }

    Timer {
        id: kill
        interval: Theme.netKill
        onTriggered: {
            if (up.running)
                up.signal(9)
            root.canceling = false
            root.timedOut = false
            root.sent = false
            root.busy = false
            root.target = ""
            root.pending = ""
            root.phase = ""
            root.refresh()
        }
    }

    Timer {
        id: settle
        interval: Theme.netSettle
        onTriggered: {
            if (!root.busy)
                root.clearPhase()
            root.refresh()
        }
    }

    Timer {
        id: watchEnd
        interval: Theme.netTimeout
        onTriggered: root.watch = false
    }

    Timer {
        id: poll
        interval: root.phase === "connecting" ? Theme.netVerify : root.busy ? Theme.netPollBusy : Theme.netPoll
        repeat: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "network"
        function toggle(): void { root.open = !root.open }
        function status(): string {
            if (!root.enabled)
                return "wifi off"
            if (root.phase !== "")
                return root.phase + " " + root.pending
            if (root.active !== "")
                return "connected " + root.active
            return "idle"
        }
    }
}


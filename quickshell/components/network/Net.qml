pragma Singleton
import "../core"
import "../notifications"
import QtQuick
import Quickshell
import Quickshell.Io

Menu {
    id: root
    name: "net"
    ipc: false
    property bool enabled: true
    property bool hw: true
    property bool device: true
    property bool probed: false
    property bool wantPower: false
    property bool watch: false
    property var list: []
    property var order: []
    property string active: ""
    property string activeUuid: ""
    property var saved: ({})
    property bool savedReady: false
    property string op: ""
    property string target: ""
    property string kind: ""
    property var fields: []
    property bool locked: false
    property bool tried: false
    property var before: null
    property int gen: 0
    property string error: ""
    property string secret: ""

    readonly property string nm: Quickshell.shellPath("components/network/nm.sh")
    readonly property bool available: hw && device
    readonly property bool busy: op !== "" && op !== "ask"
    readonly property bool toggling: op === "radio"
    readonly property bool asked: op === "ask"
    readonly property string phase: op === "connect" ? "connecting" : op === "disconnect" ? "disconnecting" : op === "forget" ? "forgetting" : ""
    readonly property string pending: phase !== "" ? target : ""
    readonly property string asking: asked ? (kind === "hidden" ? "hidden network" : target) : ""

    readonly property string title: {
        if (!available)
            return "wifi not available"
        if (!enabled)
            return "wifi off"
        if (asking !== "")
            return asking
        if (phase !== "")
            return phase + "…"
        if (active !== "")
            return active
        return "network"
    }

    property bool watchLink: false
    property bool pinLink: false
    readonly property bool liveLink: root.watchLink || root.pinLink
    property real link: -1
    readonly property bool linkKnown: root.link >= 0

    readonly property int bars: {
        if (root.linkKnown)
            return root.link <= 0 ? 0 : Math.max(1, Math.round(root.link * Theme.sigBars))
        if (!root.available || !root.enabled || root.active === "")
            return 0
        for (const n of root.list)
            if (n.active)
                return Math.max(1, Math.round(n.signal * Theme.sigBars))
        return Theme.sigBars
    }

    function linkText() {
        return root.linkKnown ? " · signal " + Math.round(root.link * 100) + "%" : " · signal unknown"
    }

    function parseLink(text) {
        const lines = String(text || "").split("\n")
        for (let i = 2; i < lines.length; i++) {
            const row = lines[i].trim()
            if (row === "" || row.indexOf(":") < 0)
                continue
            const p = row.split(/\s+/)
            if (p.length < 3)
                continue
            const q = parseFloat(p[2])
            if (!isFinite(q))
                continue
            return Math.max(0, Math.min(1, q / Theme.netLinkMax))
        }
        return -1
    }

    FileView {
        id: linkFile
        path: "/proc/net/wireless"
        onLoaded: root.link = root.parseLink(text())
        onLoadFailed: root.link = -1
    }

    Timer {
        interval: root.watchLink ? Theme.netLinkPoll : Theme.netLinkIdlePoll
        repeat: true
        running: root.liveLink
        triggeredOnStart: true
        onTriggered: {
            linkFile.reload()
            if (!root.linkKnown)
                root.refresh()
        }
    }

    function startWatching() {
        poll.restart()
        monitor.running = true
    }

    function stopWatching() {
        poll.stop()
        coalesce.stop()
        monitor.running = false
    }

    Component.onCompleted: probe()

    onOpenChanged: if (open) {
        probe()
        error = ""
        if (asked)
            idle()
        order = []
        refresh()
        loadSaved()
        if (enabled && !rescan.live)
            rescan.launch()
        startWatching()
    } else {
        if (!watch)
            stopWatching()
        if (asked)
            idle()
        error = ""
    }

    onActiveChanged: {
        if (op === "connect" && target !== "" && active === target)
            succeed()
        else if (watch && active !== "") {
            watch = false
            Notifs.pushSystem("connected", active, true, "net")
        }
    }

    onWatchChanged: if (watch) {
        watchEnd.restart()
        startWatching()
    } else if (!open)
        stopWatching()

    function begin(o, ssid) {
        op = o
        target = ssid
        error = ""
        return ++gen
    }

    function idle() {
        gen++
        op = ""
        target = ""
        kind = ""
        fields = []
        tried = false
        secret = ""
    }

    function succeed() {
        const name = target
        if (up.live)
            up.halt("done")
        idle()
        watch = false
        settle.restart()
        loadSaved()
        Notifs.pushSystem("connected", name, true, "net")
        open = false
    }

    function isEap(sec) {
        return /802\.1X/i.test(sec)
    }

    function isLocked(sec) {
        return /WEP|WPA|SAE|802\.1X/i.test(sec)
    }

    function known(ssid) {
        return (saved[ssid] || []).length > 0
    }

    function needsSecret(err) {
        const t = err.toLowerCase()
        if (t === "")
            return false
        if (t.indexOf("connection activated") >= 0 || t.indexOf("successfully") >= 0)
            return false
        return t.indexOf("secrets were required") >= 0 || t.indexOf("no secrets provided") >= 0 || t.indexOf("802-11-wireless-security.psk") >= 0 || t.indexOf("802-1x") >= 0 || t.indexOf("password") >= 0 || t.indexOf("passphrase") >= 0 || t.indexOf("secret") >= 0
    }

    function refresh() {
        if (toggling)
            return
        if (!radio.live)
            radio.launch()
        if (!activeCon.live)
            activeCon.launch()
    }

    function probe() {
        if (!devs.live)
            devs.launch()
    }

    function loadSaved() {
        if (!savedJob.live)
            savedJob.launch(["sh", root.nm, "saved"])
    }

    function clearConnectionState() {
        list = []
        order = []
        active = ""
        activeUuid = ""
    }

    function setRadio(on) {
        if (busy)
            return
        radioSet.ticket = begin("radio", "")
        enabled = on
        watch = on
        if (!on)
            clearConnectionState()
        radioSet.launch(["nmcli", "radio", "wifi", on ? "on" : "off"])
    }

    function requestPower() {
        if (wantPower || busy)
            return
        wantPower = true
        probed = false
        powerGuard.restart()
        probe()
    }

    function applyPower() {
        if (!wantPower)
            return
        powerGuard.stop()
        wantPower = false
        if (!available) {
            Notifs.pushSystem("wifi unavailable", hw ? "no wifi device" : "blocked by hardware", false, "net", true)
            return
        }
        setRadio(!enabled)
    }

    function ask(k, ssid, f) {
        begin("ask", ssid)
        kind = k
        fields = f
    }

    function pick(item) {
        if (!item || busy)
            return
        watch = false
        if (item.hidden) {
            if (!(asked && kind === "hidden"))
                ask("hidden", "", ["ssid", "password"])
            return
        }
        if (asked && target === item.ssid)
            return
        if (item.active) {
            disconnect()
            return
        }
        const eap = isEap(item.security)
        if (!known(item.ssid) && savedReady && eap) {
            ask("eap", item.ssid, ["identity", "password"])
            return
        }
        if (!known(item.ssid) && savedReady && item.locked) {
            ask("psk", item.ssid, ["password"])
            return
        }
        connect(eap ? "eap" : "psk", item.ssid, item.locked, {})
    }

    function submit(v) {
        if (!asked)
            return false
        const ssid = kind === "hidden" ? String(v.ssid || "").trim() : target
        const pass = String(v.password || "")
        if (ssid === "" || kind === "eap" && String(v.identity || "").trim() === "" || kind !== "hidden" && pass === "")
            return false
        connect(kind, ssid, true, v)
        return true
    }

    function connect(k, ssid, lock, v) {
        const t = begin("connect", ssid)
        kind = k
        fields = []
        locked = lock
        before = savedReady ? (saved[ssid] || []).slice() : null
        secret = String(v.password || "")
        tried = secret !== ""
        let cmd
        if (k === "eap" && v.identity !== undefined)
            cmd = ["sh", root.nm, "eap", before && before.length ? before[0] : "", ssid, String(v.identity).trim()]
        else if (k === "eap" && known(ssid))
            cmd = ["nmcli", "connection", "up", "uuid", saved[ssid][0]]
        else
            cmd = ["nmcli"].concat(tried ? ["--ask"] : [], ["device", "wifi", "connect", ssid], k === "hidden" ? ["hidden", "yes"] : [])
        up.ticket = t
        up.stdinEnabled = tried
        up.launch(cmd)
    }

    function prune(ssid) {
        if (before !== null && ssid !== "" && !pruner.live)
            pruner.launch(["sh", root.nm, "prune", ssid].concat(before))
        else
            loadSaved()
    }

    function cancel() {
        const live = op === "connect"
        const ssid = target
        const keep = before
        if (up.live)
            up.halt("cancel")
        idle()
        error = ""
        if (live && !abort.live)
            abort.launch(["sh", root.nm, "abort", keep !== null ? ssid : ""].concat(keep || []))
        refresh()
    }

    function disconnect() {
        if (activeUuid === "") {
            refresh()
            return
        }
        down.ticket = begin("disconnect", active)
        down.launch(["nmcli", "connection", "down", "uuid", activeUuid])
    }

    function forget(ssid) {
        const u = saved[ssid] || []
        if (busy || !u.length)
            return
        drop.ticket = begin("forget", ssid)
        drop.launch(["nmcli", "connection", "delete"].concat(...u.map(x => ["uuid", x])))
    }

    function fieldsOf(line) {
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
            const p = fieldsOf(line)
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
                locked: isLocked(sec),
                security: sec
            }
        }
        if (asked && target !== "" && !best[target]) {
            for (let i = 0; i < list.length; i++) {
                if (list[i].ssid === target) {
                    best[target] = list[i]
                    break
                }
            }
        }
        const result = Theme.stableReorder(Object.values(best), order, r => r.ssid, rank)
        order = result.order
        list = result.items
        active = cur
        if (list.length > 0)
            device = true
    }

    Job {
        id: radioSet
        property int ticket: 0
        onDone: (code, why) => {
            if (radioSet.ticket !== root.gen)
                return
            root.idle()
            if (code !== 0) {
                root.watch = false
                Notifs.pushSystem(root.enabled ? "couldn't turn wifi on" : "couldn't turn wifi off", why === "missing" ? "nmcli not found" : "", false, "net", true)
            } else if (!root.open)
                Notifs.pushSystem(root.enabled ? "wifi on" : "wifi off", "", root.enabled, "net")
            root.refresh()
        }
    }

    Job {
        id: devs
        command: ["nmcli", "-t", "-f", "TYPE", "device", "status"]
        stdout: StdioCollector { id: devsOut }
        onDone: (code, why) => {
            if (why === "") {
                const lines = devsOut.text.trim().split("\n")
                root.device = lines.some(l => l.trim() === "wifi")
            } else if (why === "missing")
                root.device = false
            root.probed = true
            if (root.wantPower && !radio.live)
                radio.launch()
        }
    }

    Timer {
        id: powerGuard
        interval: Theme.netProbe
        onTriggered: {
            if (!root.probed) {
                root.device = false
                root.probed = true
            }
            root.applyPower()
        }
    }

    Job {
        id: radio
        command: ["nmcli", "-t", "-f", "WIFI-HW,WIFI", "radio"]
        stdout: StdioCollector { id: radioOut }
        onDone: (code, why) => {
            const p = root.fieldsOf(radioOut.text.trim().toLowerCase())
            if (why === "" && p.length >= 2) {
                root.hw = p[0] === "enabled"
                if (!root.toggling) {
                    root.enabled = p[1] === "enabled"
                    if (!root.enabled)
                        root.clearConnectionState()
                }
            }
            if (root.wantPower && root.probed)
                root.applyPower()
        }
    }

    Job {
        id: activeCon
        command: ["nmcli", "-t", "-f", "UUID,TYPE", "connection", "show", "--active"]
        stdout: StdioCollector { id: activeOut }
        onDone: (code, why) => {
            if (why !== "")
                return
            let uuid = ""
            for (const line of activeOut.text.trim().split("\n")) {
                const p = root.fieldsOf(line)
                if (p.length >= 2 && p[1] === "802-11-wireless") {
                    uuid = p[0]
                    break
                }
            }
            root.activeUuid = uuid
            if (root.enabled && !scan.live)
                scan.launch()
        }
    }

    Job {
        id: scan
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL,SSID,SECURITY", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector { id: scanOut }
        onDone: (code, why) => {
            if (why !== "")
                return
            if (root.enabled)
                root.parseWifi(scanOut.text)
            else
                root.clearConnectionState()
        }
    }

    Job {
        id: savedJob
        stdout: StdioCollector { id: savedOut }
        onDone: (code, why) => {
            if (why !== "" || code !== 0)
                return
            const map = {}
            for (const line of savedOut.text.split("\n")) {
                const i = line.indexOf("\t")
                if (i <= 0)
                    continue
                const ssid = line.slice(i + 1)
                if (ssid === "")
                    continue
                if (!map[ssid])
                    map[ssid] = []
                map[ssid].push(line.slice(0, i))
            }
            root.saved = map
            root.savedReady = true
        }
    }

    Job {
        id: rescan
        command: ["nmcli", "device", "wifi", "rescan"]
        onDone: late.restart()
    }

    Process {
        id: monitor
        running: false
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: coalesce.restart()
        }
        onExited: if (root.open || root.watch) monitorRestart.restart()
    }

    Timer {
        id: coalesce
        interval: Theme.netCoalesce
        onTriggered: root.refresh()
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

    Job {
        id: up
        property int ticket: 0
        limit: Theme.netTimeout
        stderr: StdioCollector { id: upErr }
        onStarted: {
            if (root.secret === "")
                return
            up.write(root.secret + "\n")
            root.secret = ""
            up.stdinEnabled = false
        }
        onDone: (code, why) => {
            root.secret = ""
            if (up.ticket !== root.gen || root.op !== "connect")
                return
            if (code === 0 && why === "") {
                root.refresh()
                root.succeed()
                return
            }
            const name = root.target
            const k = root.kind
            const wrong = root.tried
            root.prune(name)
            if (why === "" && root.locked && root.needsSecret(upErr.text)) {
                root.ask(k, name, k === "eap" ? ["identity", "password"] : k === "hidden" ? ["ssid", "password"] : ["password"])
                if (wrong)
                    root.error = "wrong password"
                root.refresh()
                return
            }
            root.idle()
            Notifs.pushSystem("couldn't connect", why === "timeout" ? name + " · timed out" : why === "missing" ? "nmcli not found" : name, false, "net", true)
            root.open = false
            root.refresh()
        }
    }

    Job {
        id: pruner
        onDone: root.loadSaved()
    }

    Job {
        id: abort
        onDone: {
            root.loadSaved()
            root.refresh()
        }
    }

    Job {
        id: down
        property int ticket: 0
        onDone: (code, why) => {
            if (down.ticket !== root.gen)
                return
            const name = root.target
            root.idle()
            if (code !== 0)
                Notifs.pushSystem("couldn't disconnect", why === "timeout" ? name + " · timed out" : name, false, "net", true)
            root.refresh()
        }
    }

    Job {
        id: drop
        property int ticket: 0
        onDone: (code, why) => {
            if (drop.ticket !== root.gen)
                return
            root.idle()
            if (code !== 0)
                root.error = "couldn't forget"
            root.loadSaved()
            root.refresh()
        }
    }

    Timer {
        id: settle
        interval: Theme.netSettle
        onTriggered: root.refresh()
    }

    Timer {
        id: watchEnd
        interval: Theme.netTimeout
        onTriggered: root.watch = false
    }

    Timer {
        id: poll
        interval: root.op === "connect" ? Theme.netVerify : root.busy ? Theme.netPollBusy : Theme.netPoll
        repeat: true
        onTriggered: root.refresh()
    }

    function report() {
        if (!root.available)
            return "no wifi"
        if (!root.enabled)
            return "wifi off"
        if (root.phase !== "")
            return root.phase + " " + root.pending
        if (root.asked)
            return "asking " + root.asking
        if (root.active !== "")
            return "connected " + root.active + root.linkText()
        return "idle" + root.linkText()
    }

    IpcHandler {
        target: "network"
        function toggle(): void { root.open = !root.open }
        function power(): void { root.requestPower() }

        function indicator(): string {
            const on = !Theme.wifiOn
            Cfg.set("wifiOn", on)
            Cfg.flush()
            return on ? "shown" : "hidden"
        }

        function status(): string { return root.status() }
    }
}

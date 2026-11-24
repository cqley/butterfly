pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Singleton {
    id: root
    property string phase: "idle"
    property bool preview: false
    property bool secure: false
    property bool pillSettled: true
    property bool opened: false
    property bool busy: false
    property int fails: 0
    property int shown: 0
    property string buffer: ""
    property string attempt: ""
    property bool queued: false
    property bool red: false
    property bool booted: false
    property bool leaving: false
    property int woken: 0
    property real swapAt: 0
    property int stages: 0
    readonly property bool staged: root.stages > 0
    property bool stageSettled: true
    property bool ripe: false
    property Item twin: null
    readonly property bool held: keep.held
    readonly property bool covering: root.phase !== "idle"
    readonly property bool staging: root.phase === "closing" || root.phase === "locked" && !root.secure && !root.preview
    readonly property bool down: root.phase === "closing" || root.phase === "locked"
    readonly property bool cooling: failHold.running && root.buffer === ""
    readonly property bool pulsing: root.busy && root.buffer === ""
    readonly property int count: root.buffer.length > 0 ? root.buffer.length : root.busy || failHold.running ? root.shown : 0
    readonly property real glyphAt: root.phase === "opening" ? Theme.lockerGlyphLeave : Theme.lockerGlyphAt
    readonly property bool shut: root.down || root.phase === "opening" && root.t > Theme.lockerGlyphBack
    readonly property bool glyph: root.count === 0 && !root.busy && !root.cooling
    readonly property real t: Math.max(0, Math.min(1, travel.shaped))
    readonly property real move: travel.shaped
    readonly property real fade: root.smooth(Math.max(0, Math.min(1, veil.shaped)))

    function smooth(u) {
        return u * u * (3 - 2 * u)
    }

    readonly property string flag: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/butterfly-locked"

    PersistentProperties {
        id: keep
        reloadableId: "locker"
        property bool held: false

        onLoaded: {
            if (root.booted)
                return
            root.booted = true
            if (keep.held) {
                root.phase = "locked"
                travel.land(1)
                veil.land(1)
                secureWait.restart()
            } else {
                stale.running = true
            }
        }
    }

    function lock(instant) {
        if (root.leaving) {
            root.leaving = false
            giveUp.stop()
            root.opened = false
            root.hold()
            return "locked"
        }
        if (root.down) {
            if (!root.preview)
                return "already locked"
            root.preview = false
            root.opened = false
            openHold.stop()
            if (instant || root.phase === "locked") {
                root.phase = "locked"
                travel.land(1)
                veil.land(1)
                root.hold()
            }
            return "locked"
        }
        Modal.dismiss()
        root.clear()
        root.red = false
        failHold.stop()
        root.opened = false
        root.preview = false
        if (instant) {
            root.phase = "locked"
            travel.land(1)
            veil.land(1)
            root.hold()
            return "locked"
        }
        root.phase = "closing"
        return "locking"
    }

    function beginPreview() {
        if (root.preview && root.phase === "locked" && !root.busy && !root.opened) {
            root.release()
            return "closing preview"
        }
        if (root.covering)
            return "busy"
        Modal.dismiss()
        root.clear()
        root.red = false
        failHold.stop()
        root.opened = false
        root.preview = true
        root.phase = "closing"
        return "preview"
    }

    function hold() {
        if (root.preview)
            return
        keep.held = true
        mark.running = true
        secureWait.restart()
    }

    function arrive() {
        if (root.phase === "closing" && !travel.moving && !veil.moving && root.pillSettled) {
            root.phase = "locked"
            root.hold()
            if (root.queued)
                Qt.callLater(root.submit)
        }
    }

    function settle() {
        root.arrive()
        root.depart()
    }

    function depart() {
        if (root.phase === "opening" && !travel.moving && !veil.moving) {
            root.phase = "idle"
            root.opened = false
            root.preview = false
        }
    }

    function release() {
        keep.held = false
        secureWait.stop()
        unmark.running = true
        root.clear()
        if (root.preview) {
            root.phase = "opening"
            return
        }
        root.woken = 0
        root.leaving = true
        giveUp.restart()
    }

    function woke() {
        if (!root.leaving || root.staged)
            return
        const now = Date.now()
        const gap = now - root.swapAt
        root.woken = gap >= Theme.lockerWakeMin && gap <= Theme.lockerWakeGap ? root.woken + 1 : 0
        root.swapAt = now
        if (root.woken >= Theme.lockerWakeFrames)
            root.wakeUp()
    }

    function wakeUp() {
        if (!root.leaving)
            return
        giveUp.stop()
        root.phase = "opening"
        root.leaving = false
    }

    Timer {
        id: giveUp
        interval: Theme.lockerWakeCap
        onTriggered: root.wakeUp()
    }

    onBufferChanged: if (root.buffer !== "") root.red = false

    function clear() {
        root.buffer = ""
        root.queued = false
        if (!root.busy)
            root.shown = 0
    }

    function key(event) {
        if (!root.down || root.opened)
            return
        const enter = event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        if (event.key === Qt.Key_Escape) {
            if (root.preview && root.phase === "locked" && root.count === 0 && !root.busy)
                root.release()
            else
                root.clear()
        } else if (enter) {
            if (root.busy || root.phase !== "locked")
                root.queued = root.buffer !== ""
            else
                root.submit()
        } else if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_U) && (event.modifiers & Qt.ControlModifier)) {
            root.clear()
        } else if (event.key === Qt.Key_Backspace) {
            root.buffer = root.buffer.slice(0, -1)
            if (root.buffer === "")
                root.queued = false
        } else if (event.text && /^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
            root.buffer += event.text
        }
    }

    function submit() {
        root.queued = false
        if (root.buffer === "" || root.busy || root.phase !== "locked" || root.opened)
            return
        if (pam.active)
            pam.abort()
        failHold.stop()
        root.red = false
        root.attempt = root.buffer
        root.shown = root.buffer.length
        root.buffer = ""
        root.busy = true
        if (!pam.start())
            root.fail()
    }

    function fail() {
        const was = root.busy
        root.busy = false
        root.attempt = ""
        if (pam.active)
            pam.abort()
        if (!was)
            return
        root.red = root.buffer === ""
        root.fails++
        failHold.restart()
        if (root.queued)
            Qt.callLater(root.submit)
    }

    PamContext {
        id: pam
        config: Theme.lockerPam
        configDirectory: Quickshell.shellPath("components/lock/pam")

        onResponseRequiredChanged: {
            if (!responseRequired)
                return
            if (!root.busy || root.attempt === "") {
                root.fail()
                return
            }
            respond(root.attempt)
            root.attempt = ""
        }

        onCompleted: result => {
            if (!root.busy)
                return
            if (result !== PamResult.Success || root.phase !== "locked") {
                root.fail()
                return
            }
            root.busy = false
            root.buffer = ""
            root.queued = false
            root.shown = 0
            root.ripe = false
            root.opened = true
            openHold.restart()
            openCap.restart()
        }

        onError: err => {
            console.warn("lock: pam " + PamError.toString(err))
            root.fail()
        }
    }

    Timer {
        id: failHold
        interval: Theme.lockerFailHold
        onTriggered: root.shown = 0
    }

    Timer {
        id: openHold
        interval: Theme.lockerOpenHold
        onTriggered: {
            root.ripe = true
            root.leave()
        }
    }

    Timer {
        id: openCap
        interval: Theme.lockerOpenCap
        onTriggered: if (root.opened && root.phase === "locked") root.release()
    }

    Timer {
        id: secureWait
        interval: Theme.lockerSecureWait
        onTriggered: if (keep.held && !root.secure) {
            console.warn("lock: compositor never confirmed the lock, giving up")
            root.release()
        }
    }

    function lost() {
        if (keep.held && root.phase === "locked") {
            console.warn("lock: the compositor ended the lock")
            root.release()
        }
    }

    Spring {
        id: travel
        target: root.down ? 1 : 0
        hold: Theme.lockerHold
        response: Theme.lockerResponse
        damping: root.down ? Theme.lockerDamping : Theme.lockerHomeDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
        onMovingChanged: Qt.callLater(root.settle)
    }

    Spring {
        id: veil
        target: root.down ? 1 : 0
        hold: Theme.lockerHold
        response: root.down ? Theme.lockerVeilResponse : Theme.lockerResponse
        damping: 1
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
        onMovingChanged: Qt.callLater(root.settle)
    }

    onPillSettledChanged: root.arrive()
    onStageSettledChanged: root.leave()

    function leave() {
        if (root.opened && root.ripe && root.phase === "locked" && root.stageSettled)
            root.release()
    }

    Process {
        id: mark
        command: ["touch", root.flag]
    }

    Process {
        id: unmark
        command: ["rm", "-f", root.flag]
    }

    Process {
        id: stale
        command: ["test", "-e", root.flag]
        onExited: code => {
            if (code === 0 && !keep.held)
                root.lock(true)
        }
    }

    Process {
        id: inhibit
        running: !root.secure
        command: ["setpriv", "--pdeathsig", "TERM", "systemd-inhibit", "--what=sleep", "--mode=delay", "--who=butterfly",
            "--why=lock the screen before sleep", "setpriv", "--pdeathsig", "TERM", "sleep", "infinity"]
    }

    Process {
        id: sleepWatch
        running: true
        command: ["setpriv", "--pdeathsig", "TERM", "busctl", "--system", "wait", "/org/freedesktop/login1",
            "org.freedesktop.login1.Manager", "PrepareForSleep"]
        stdout: SplitParser {
            onRead: line => {
                if (/\btrue\b/.test(line))
                    root.lock(true)
            }
        }
        onExited: code => {
            if (code === 0)
                running = true
            else
                rewatch.restart()
        }
    }

    Timer {
        id: rewatch
        interval: 5000
        onTriggered: sleepWatch.running = true
    }

    IpcHandler {
        target: "lock"

        function lock(): string { return root.lock(false) }
        function preview(): string { return root.beginPreview() }
        function status(): string {
            return root.phase + (root.preview ? " (preview)" : "")
                + (keep.held ? " · held" : "") + (root.secure ? " · secure" : "")
        }
    }
}

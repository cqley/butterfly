import QtQuick
import Quickshell.Io

Process {
    id: root
    property int limit: Theme.jobLimit
    property bool live: false
    property string why: ""
    property bool began: false
    signal done(int code, string why)

    function launch(cmd) {
        if (root.live)
            return
        if (cmd)
            root.command = cmd
        root.why = ""
        root.began = false
        root.live = true
        root.running = true
        root.watchdog.restart()
        root.starter.restart()
    }

    function halt(why) {
        if (!root.live || root.why !== "")
            return
        root.why = root.running || root.began ? why : "missing"
        if (!root.running) {
            root.end(-1)
            return
        }
        root.signal(15)
        root.reaper.restart()
    }

    function end(code) {
        if (!root.live)
            return
        root.live = false
        root.watchdog.stop()
        root.starter.stop()
        root.reaper.stop()
        root.done(code, root.why)
    }

    onStarted: root.began = true
    onExited: code => root.end(code)

    readonly property Timer watchdog: Timer {
        interval: root.limit
        onTriggered: root.halt("timeout")
    }

    readonly property Timer starter: Timer {
        interval: Theme.jobStart
        onTriggered: if (!root.running && !root.began) root.halt("missing")
    }

    readonly property Timer reaper: Timer {
        interval: Theme.jobKill
        onTriggered: {
            if (root.running)
                root.signal(9)
            root.end(-1)
        }
    }
}

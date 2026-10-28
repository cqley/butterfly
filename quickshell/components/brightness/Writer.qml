import "../core"
import QtQuick
import Quickshell.Io

QtObject {
    id: root
    required property string kind
    required property int bus
    required property int vcpMax

    property real want: -1
    property real sent: -1
    property bool careful: false
    readonly property bool busy: proc.running
    readonly property bool active: root.busy || (root.want >= 0 && root.want !== root.sent)
    signal settled(bool ok)

    readonly property var proc: Process {
        onExited: code => root.finish(code)
    }

    readonly property var again: Timer {
        interval: Theme.brightRetry
        onTriggered: root.kick()
    }

    function argv(v) {
        if (root.kind !== "ddc")
            return ["brightnessctl", "-q", "-c", "backlight", "set", Math.round(v * 100) + "%"]
        const a = ["ddcutil", "--bus", String(root.bus)]
        if (!root.careful)
            a.push("--noverify", "--skip-ddc-checks")
        return a.concat(["setvcp", "10", String(Math.round(v * root.vcpMax))])
    }

    function push(v) {
        root.want = v
        root.kick()
    }

    function kick() {
        if (root.proc.running || root.want < 0 || root.want === root.sent)
            return
        root.sent = root.want
        root.proc.command = root.argv(root.sent)
        root.proc.running = true
    }

    function finish(code) {
        if (code !== 0 && !root.careful && root.kind === "ddc") {
            root.careful = true
            root.sent = -1
            root.again.restart()
            return
        }
        root.careful = false
        if (root.want !== root.sent) {
            root.kick()
            return
        }
        root.settled(code === 0)
    }
}

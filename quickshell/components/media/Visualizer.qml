pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool on: false
    property string cavaBin: ""
    readonly property bool real: cavaBin !== ""
    property var levels: []
    readonly property string configPath: Quickshell.statePath("cava.conf")

    function toggle() {
        root.on = !root.on
    }

    function sync() {
        if (Media.playing)
            offTimer.stop()
        else
            offTimer.restart()
        cava.running = root.real && (Media.playing || offTimer.running)
    }

    onRealChanged: root.sync()

    function configText() {
        return "[general]\nbars = " + Theme.visBars + "\nframerate = " + Theme.visFps
            + "\nautosens = 1\nsensitivity = 100\nchannels = mono\n\n[input]\nmethod = pulse\nsource = auto"
            + "\n\n[output]\nmethod = raw\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 100"
            + "\n\n[smoothing]\nnoise_reduction = " + Theme.visNoiseReduction + "\n"
    }

    Connections {
        target: Media
        function onPlayingChanged() { root.sync() }
    }

    Timer {
        id: offTimer
        interval: Theme.visOffDelay
        onTriggered: {
            root.on = false
            root.sync()
        }
    }

    FileView {
        id: config
        path: root.configPath
        blockLoading: true
        printErrors: false
    }

    Process {
        id: detect
        command: ["sh", "-lc", "command -v cava"]
        stdout: StdioCollector {
            onStreamFinished: root.cavaBin = text.trim()
        }
    }

    Process {
        id: cava
        running: false
        command: [root.cavaBin, "-p", root.configPath]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split(";").filter(p => p.length > 0)
                root.levels = parts.map(p => Math.min(1, Math.max(0, Number(p) / 100)))
            }
        }
        onExited: root.levels = []
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Quickshell.stateDir])
        config.setText(root.configText())
        detect.running = true
    }

    IpcHandler {
        target: "visualizer"
        function toggle(): void { root.toggle() }
        function status(): string { return (root.on ? "on" : "off") + (root.real ? " cava" : " fallback") }
    }
}

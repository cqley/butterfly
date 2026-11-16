pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool on: false
    property bool heard: false
    readonly property bool active: Media.playing || (root.heard && offTimer.running)
    property string cavaBin: ""
    readonly property bool real: cavaBin !== ""
    property var levels: []
    readonly property string configPath: Quickshell.statePath("cava.conf")

    function toggle() {
        root.on = !root.on
        root.sync()
    }

    function sync() {
        if (Media.playing) {
            root.heard = true
            offTimer.stop()
        } else {
            offTimer.restart()
        }
        cava.running = root.real && (Media.playing || offTimer.running)
    }

    onRealChanged: root.sync()
    onConfigTextChanged: {
        config.setText(root.configText)
        reload.restart()
    }

    readonly property string configText: {
        return "[general]\nbars = " + Theme.visBars + "\nframerate = " + Theme.visFps
            + "\nautosens = 1\nsensitivity = 100\n\n[input]\nmethod = pulse\nsource = auto"
            + "\n\n[output]\nmethod = raw\nchannels = mono\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 100"
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
            root.heard = false
            root.sync()
        }
    }

    Timer {
        id: reload
        interval: 250
        onTriggered: if (cava.running) {
            cava.reloading = true
            cava.running = false
        }
    }

    FileView {
        id: config
        path: root.configPath
        blockLoading: true
        blockWrites: true
        printErrors: false
    }

    Which {
        id: detect
        names: ["cava"]
        onDone: root.cavaBin = found["cava"] || ""
    }

    Process {
        id: cava
        property bool reloading: false
        running: false
        command: [root.cavaBin, "-p", root.configPath]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split(";").filter(p => p.length > 0)
                root.levels = parts.map(p => Math.min(1, Math.max(0, Number(p) / 100)))
            }
        }
        onExited: {
            root.levels = []
            if (cava.reloading) {
                cava.reloading = false
                cava.running = true
            }
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Quickshell.stateDir])
        config.setText(root.configText)
        detect.running = true
    }

    IpcHandler {
        target: "visualizer"
        function toggle(): void { root.toggle() }
        function status(): string { return (root.on ? "on" : "off") + (root.real ? " cava" : " fallback") }
    }
}

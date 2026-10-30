pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property string path: home + "/.config/quickshell/settings.json"
    readonly property string shortPath: "~/.config/quickshell/settings.json"
    readonly property int settleMs: 400
    property var v: ({})
    property string mine: ""
    readonly property int count: Object.keys(v).length

    function has(key) {
        const x = root.v[key]
        return x !== undefined && x !== null
    }

    function get(key, fallback) {
        const x = root.v[key]
        return x === undefined || x === null ? fallback : x
    }

    function set(key, value) {
        if (root.v[key] === value)
            return
        const next = Object.assign({}, root.v)
        next[key] = value
        root.v = next
        settle.restart()
    }

    function clear(key) {
        if (!root.has(key))
            return
        const next = Object.assign({}, root.v)
        delete next[key]
        root.v = next
        settle.restart()
    }

    function clearAll() {
        if (Object.keys(root.v).length === 0)
            return
        root.v = ({})
        settle.restart()
    }

    function flush() {
        settle.stop()
        root.mine = JSON.stringify(root.v, null, 2) + "\n"
        file.setText(root.mine)
    }

    function adopt(text) {
        let parsed = null
        try {
            parsed = JSON.parse(text)
        } catch (e) {
            parsed = null
        }
        root.v = parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : ({})
    }

    Timer {
        id: settle
        interval: root.settleMs
        onTriggered: root.flush()
    }

    FileView {
        id: file
        path: root.path
        preload: true
        blockLoading: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoadFailed: root.v = ({})
        onLoaded: if (!settle.running && text() !== root.mine) root.adopt(text())
    }

}

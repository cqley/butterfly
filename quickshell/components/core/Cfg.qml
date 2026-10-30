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
    readonly property int writeGuardMs: 1500
    property var v: ({})
    property bool writing: false
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
        root.writing = true
        guard.restart()
        file.setText(JSON.stringify(root.v, null, 2) + "\n")
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

    Timer {
        id: guard
        interval: root.writeGuardMs
        onTriggered: root.writing = false
    }

    FileView {
        id: file
        path: root.path
        preload: true
        blockLoading: true
        watchChanges: true
        printErrors: false

        onFileChanged: {
            if (root.writing) {
                root.writing = false
                guard.stop()
                return
            }
            reload()
        }
        onLoadFailed: root.v = ({})
        onLoaded: root.adopt(text())
        onSaved: {
            root.writing = false
            guard.stop()
        }
        onSaveFailed: {
            root.writing = false
            guard.stop()
        }
    }

}

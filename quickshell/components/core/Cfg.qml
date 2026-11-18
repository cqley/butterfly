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
    readonly property var defaults: ({})
    property bool ready: false
    property string mine: ""
    property var pending: ({})
    readonly property int count: Object.keys(v).length

    function has(key) {
        const x = root.v[key]
        return x !== undefined && x !== null
    }

    function remember(key, fallback) {
        root.defaults[key] = fallback
    }

    function same(a, b) {
        if (typeof a === "number" && typeof b === "number")
            return Math.abs(a - b) < 1e-6
        if (a !== null && b !== null && typeof a === "object" && typeof b === "object")
            return JSON.stringify(a) === JSON.stringify(b)
        return a === b
    }

    function isDefault(key) {
        return !root.has(key) || (key in root.defaults && root.same(root.v[key], root.defaults[key]))
    }

    function get(key, fallback, lo, hi) {
        root.remember(key, fallback)
        const x = root.v ? root.v[key] : undefined
        if (x === undefined || x === null || typeof x !== typeof fallback)
            return fallback
        if (Array.isArray(lo))
            return lo.indexOf(x) < 0 ? fallback : x
        if (typeof x !== "number")
            return x
        if (!isFinite(x))
            return fallback
        return lo === undefined ? x : Math.min(Math.max(x, lo), hi)
    }

    function set(key, value) {
        if (key in root.defaults && root.same(value, root.defaults[key])) {
            root.clear(key)
            return
        }
        if (root.v[key] === value)
            return
        const next = Object.assign({}, root.v)
        next[key] = value
        root.v = next
        root.pending[key] = { value: value }
        settle.restart()
    }

    function clear(key) {
        if (!root.has(key))
            return
        const next = Object.assign({}, root.v)
        delete next[key]
        root.v = next
        root.pending[key] = { gone: true }
        settle.restart()
    }

    function clearAll() {
        if (Object.keys(root.v).length === 0)
            return
        for (const k in root.v)
            root.pending[k] = { gone: true }
        root.v = ({})
        settle.restart()
    }

    function flush() {
        settle.stop()
        root.pending = ({})
        root.mine = JSON.stringify(root.v, null, 2) + "\n"
        file.setText(root.mine)
    }

    function parse(text) {
        try {
            const p = JSON.parse(text)
            return p && typeof p === "object" && !Array.isArray(p) ? p : null
        } catch (e) {
            return null
        }
    }

    function adopt(text) {
        const parsed = root.parse(text)
        if (!parsed && root.ready)
            return
        root.v = parsed || ({})
    }

    function merge(text) {
        const theirs = root.parse(text)
        if (!theirs)
            return
        const base = root.parse(root.mine) || ({})
        const next = Object.assign({}, theirs)
        for (const k in root.pending) {
            if (!root.same(theirs[k], base[k])) {
                delete root.pending[k]
                continue
            }
            if (root.pending[k].gone)
                delete next[k]
            else
                next[k] = root.pending[k].value
        }
        root.v = next
        root.mine = text
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
        onLoadFailed: { if (!root.ready) root.v = ({}); root.ready = true }
        onLoaded: {
            const t = text()
            if (t !== root.mine) {
                if (settle.running) {
                    root.merge(t)
                } else {
                    root.adopt(t)
                    root.mine = t
                }
            }
            root.ready = true
        }
    }

}

pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property var registry: ({})
    property bool busy: false
    property string pending: ""
    readonly property string which: Object.keys(registry).find(k => !!registry[k] && registry[k].open) || ""
    readonly property bool any: which !== ""

    function register(name, owner) {
        const next = Object.assign({}, registry)
        next[name] = owner
        registry = next
    }

    function all() {
        const out = {}
        for (const k in registry)
            if (k !== "polkit") out[k] = registry[k]
        return out
    }

    function close(except) {
        const m = all()
        for (const k in m)
            if (k !== except) m[k].open = false
    }

    function dismiss() {
        const p = registry.polkit
        if (p && p.open)
            p.cancel()
        root.pending = ""
        close("")
    }

    function claim(name) {
        const owner = registry[name]
        if (!owner) return
        if (registry.polkit && registry.polkit.open) {
            owner.open = false
            return
        }
        const other = Object.keys(registry).some(k => k !== name && !!registry[k] && registry[k].open)
        if (Theme.blockSwap && root.busy && other) {
            owner.open = false
            root.pending = name
            return
        }
        root.pending = ""
        close(name)
    }

    function flush() {
        const name = root.pending
        root.pending = ""
        if (!name || !registry[name] || !root.any)
            return
        close(name)
        registry[name].open = true
    }
}

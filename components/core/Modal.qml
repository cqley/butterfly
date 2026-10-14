pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property var registry: ({})
    readonly property bool any: Object.keys(registry).some(k => !!registry[k] && registry[k].open)

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
        close("")
    }

    function claim(name) {
        const owner = registry[name]
        if (!owner) return
        if (registry.polkit && registry.polkit.open)
            owner.open = false
        else
            close(name)
    }
}

pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root
    property var last: null
    property var live: null
    property var recent: null
    property var pinned: null
    property var idle: null
    property var sources: []
    readonly property var player: pinned || live || last || idle
    readonly property bool playing: pinned ? pinned.isPlaying : live !== null
    readonly property string title: player ? player.trackTitle || player.identity : ""
    readonly property string artUrl: artFor(player)
    readonly property string trackKey: keyFor(player)

    function proxy(p) {
        return (p && p.dbusName ? p.dbusName : "").toLowerCase().indexOf("playerctld") >= 0
    }

    function usable(p) {
        return p !== null && !proxy(p) && (p.isPlaying || (p.trackTitle || "") !== "")
    }

    function pool() {
        const v = Mpris.players.values
        const out = []
        for (let i = 0; i < v.length; i++)
            if (!proxy(v[i]))
                out.push(v[i])
        return out
    }

    function urlFor(p) {
        return p && p.metadata ? p.metadata["xesam:url"] || "" : ""
    }

    function keyFor(p) {
        return p ? (p.dbusName || "") + "|" + (p.trackTitle || "") + "|" + (p.trackArtUrl || "") : ""
    }

    function artFor(p) {
        if (!p)
            return ""
        const art = p.trackArtUrl || ""
        if (art)
            return art.charAt(0) === "/" ? "file://" + art : art
        const m = urlFor(p).match(/(?:youtube\.com\/watch.*[?&]v=|youtu\.be\/)([\w-]{11})/)
        return m ? `https://img.youtube.com/vi/${m[1]}/hqdefault.jpg` : ""
    }

    function nameFor(p) {
        return p ? String(p.identity || "").toLowerCase() : ""
    }

    function pick() {
        const v = pool()
        const names = []
        for (let i = 0; i < v.length; i++)
            if (names.indexOf(nameFor(v[i])) < 0 && nameFor(v[i]) !== "")
                names.push(nameFor(v[i]))
        sources = names
        pinned = Theme.mediaSource === "" ? null : v.find(p => nameFor(p) === Theme.mediaSource) || null
        idle = v.length > 0 ? v[0] : null
        if (recent && (v.indexOf(recent) < 0 || !usable(recent)))
            recent = null
        let found = null
        if (recent && recent.isPlaying)
            found = recent
        for (let i = 0; i < v.length && !found; i++)
            if (v[i].isPlaying && usable(v[i]))
                found = v[i]
        live = found
        if (found) {
            last = found
            return
        }
        if (last && v.indexOf(last) >= 0 && usable(last))
            return
        last = recent
        for (let i = 0; i < v.length && !last; i++)
            if (usable(v[i]))
                last = v[i]
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.pick() }
    }

    Connections {
        target: Theme
        function onMediaSourceChanged() { root.pick() }
    }

    Instantiator {
        model: Mpris.players
        Connections {
            required property var modelData
            target: modelData
            function onIsPlayingChanged() {
                if (modelData.isPlaying)
                    root.recent = modelData
                root.pick()
            }
            function onTrackTitleChanged() { root.pick() }
            function onIdentityChanged() { root.pick() }
        }
    }

    Component.onCompleted: pick()
}

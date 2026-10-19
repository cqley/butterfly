pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root
    property var last: null
    property var live: null
    property var recent: null
    readonly property var player: live || last
    readonly property bool playing: live !== null
    readonly property string title: player ? player.trackTitle || player.identity : ""
    readonly property string artUrl: artFor(player)

    function artFor(p) {
        if (!p)
            return ""
        if (p.trackArtUrl)
            return p.trackArtUrl
        const url = p.metadata ? p.metadata["xesam:url"] || "" : ""
        const m = url.match(/^https:\/\/(?:www|music)\.youtube\.com\/watch.*[?&]v=([\w-]{11})/)
        return m ? `https://img.youtube.com/vi/${m[1]}/hqdefault.jpg` : ""
    }

    function pick() {
        const v = Mpris.players.values
        let found = null
        if (recent && v.indexOf(recent) >= 0 && recent.isPlaying)
            found = recent
        for (let i = 0; !found && i < v.length; i++) {
            if (v[i].isPlaying) {
                found = v[i]
                break
            }
        }
        live = found
        if (found)
            last = found
        else if (last) {
            let still = false
            for (let i = 0; i < v.length; i++) {
                if (v[i] === last) {
                    still = true
                    break
                }
            }
            if (!still) last = null
        }
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.pick() }
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
        }
    }

    Component.onCompleted: pick()
}

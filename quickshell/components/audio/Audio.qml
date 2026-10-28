pragma Singleton
import "../core"
import "../mixer"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root
    property bool watch: false

    readonly property bool active: watch
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: active ? Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink && !n.isStream) : []
    readonly property var sources: active ? Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource && !n.isStream) : []
    readonly property bool hasIn: !!source
    readonly property int count: hasIn ? 2 : 1
    readonly property bool outReady: node(0) !== null
    readonly property bool inReady: node(1) !== null
    readonly property real outLevel: outReady ? clamp(sink.audio.volume) : 0
    readonly property real inLevel: inReady ? clamp(source.audio.volume) : 0
    readonly property bool outMuted: outReady && sink.audio.muted
    readonly property bool inMuted: inReady && source.audio.muted

    readonly property var streams: active ? Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioOutStream).sort((a, b) => a.id - b.id) : []
    readonly property int streamCount: streams.length

    function streamNode(i) {
        const n = streams[i]
        return n && n.ready && n.audio ? n : null
    }

    function streamReady(i) {
        return streamNode(i) !== null
    }

    function streamLevel(i) {
        const n = streamNode(i)
        return n ? clamp(n.audio.volume) : 0
    }

    function streamMuted(i) {
        const n = streamNode(i)
        return n !== null && n.audio.muted
    }

    function streamSet(i, v) {
        const n = streamNode(i)
        if (!n)
            return
        const next = clamp(v)
        if (next !== n.audio.volume)
            n.audio.volume = next
    }

    function streamNudge(i, d) {
        if (streamNode(i))
            streamSet(i, (Math.round(streamLevel(i) * 100) + d) / 100)
    }

    function streamToggleMute(i) {
        const n = streamNode(i)
        if (n)
            n.audio.muted = !n.audio.muted
    }

    function streamLabel(i) {
        const n = streams[i]
        if (!n)
            return ""
        const p = n.properties || {}
        const t = p["application.name"] || n.description || p["media.name"] || n.name || ""
        return String(t).toLowerCase()
    }

    function streamIcon(i) {
        const n = streams[i]
        if (!n)
            return ""
        const p = n.properties || {}
        const names = [p["application.icon-name"], p["application.process.binary"], p["application.name"]]
        for (const raw of names) {
            const v = String(raw || "").trim()
            if (v === "")
                continue
            const hit = Quickshell.iconPath(v, true) || Quickshell.iconPath(v.toLowerCase(), true)
            if (hit)
                return Theme.url(hit)
        }
        return ""
    }

    function deviceName(n) {
        const t = n ? (n.nickname || n.description || n.name) : ""
        return String(t).toLowerCase()
    }

    function current(i) {
        return i === 0 ? sink : source
    }

    function isDefault(i, n) {
        const cur = current(i)
        return !!n && !!cur && n.id === cur.id
    }

    function choose(i, n) {
        if (!n)
            return
        if (i === 0)
            Pipewire.preferredDefaultAudioSink = n
        else
            Pipewire.preferredDefaultAudioSource = n
    }

    function clamp(v) {
        return Math.max(0, Math.min(1, v))
    }

    function node(i) {
        const n = i === 0 ? sink : source
        return n && n.ready && n.audio ? n : null
    }

    function ready(i) {
        return i === 0 ? outReady : inReady
    }

    function level(i) {
        return i === 0 ? outLevel : inLevel
    }

    function muted(i) {
        return i === 0 ? outMuted : inMuted
    }

    function peak(i) {
        const m = i === 0 ? outMeter : inMeter
        return m.node && ready(i) && !muted(i) ? clamp(m.peak) : 0
    }

    function label(i) {
        const t = deviceName(current(i))
        return t === "" ? (i === 0 ? "no output" : "no input") : t
    }

    function list(i) {
        return i === 0 ? sinks : sources
    }

    function set(i, v) {
        const n = node(i)
        if (!n)
            return
        const next = clamp(v)
        if (next !== n.audio.volume)
            n.audio.volume = next
    }

    function nudge(i, d) {
        if (node(i))
            set(i, (Math.round(level(i) * 100) + d) / 100)
    }

    function toggleMute(i) {
        const n = node(i)
        if (n)
            n.audio.muted = !n.audio.muted
    }

    function cycle(i) {
        const all = list(i)
        if (all.length < 2)
            return
        let at = -1
        for (let k = 0; k < all.length; k++)
            if (isDefault(i, all[k]))
                at = k
        choose(i, all[(at + 1) % all.length])
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    PwObjectTracker {
        objects: root.streams
    }

    PwNodePeakMonitor {
        id: outMeter
        node: root.active ? Pipewire.defaultAudioSink : null
        enabled: root.active
    }

    PwNodePeakMonitor {
        id: inMeter
        node: root.active ? Pipewire.defaultAudioSource : null
        enabled: root.active
    }

    IpcHandler {
        target: "audio"
        function toggle(): void { Mixer.open = !Mixer.open }
        function status(): string {
            const out = []
            for (let i = 0; i < root.count; i++) {
                const name = i === 0 ? "output" : "input"
                const prefix = root.node(i) ? name + " " + root.label(i) : name
                out.push(prefix + " " + Theme.pctOrUnavailable(root.node(i) !== null, root.level(i), root.muted(i) ? " muted" : ""))
            }
            return out.join(", ")
        }
    }
}

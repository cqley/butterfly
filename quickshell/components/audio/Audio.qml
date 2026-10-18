pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root
    property bool open: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: open ? Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink && !n.isStream) : []
    readonly property var sources: open ? Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource && !n.isStream) : []
    readonly property bool hasIn: !!source
    readonly property int count: hasIn ? 2 : 1
    readonly property bool outReady: node(0) !== null
    readonly property bool inReady: node(1) !== null
    readonly property real outLevel: outReady ? clamp(sink.audio.volume) : 0
    readonly property real inLevel: inReady ? clamp(source.audio.volume) : 0
    readonly property bool outMuted: outReady && sink.audio.muted
    readonly property bool inMuted: inReady && source.audio.muted

    onOpenChanged: if (open) Modal.claim("audio")

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
        const n = i === 0 ? sink : source
        const t = n ? (n.nickname || n.description || n.name) : ""
        return t === "" ? (i === 0 ? "no output" : "no input") : t.toLowerCase()
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
        const cur = i === 0 ? sink : source
        let at = -1
        for (let k = 0; k < all.length; k++)
            if (cur && all[k].id === cur.id)
                at = k
        const next = all[(at + 1) % all.length]
        if (i === 0)
            Pipewire.preferredDefaultAudioSink = next
        else
            Pipewire.preferredDefaultAudioSource = next
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    PwNodePeakMonitor {
        id: outMeter
        node: root.open ? Pipewire.defaultAudioSink : null
        enabled: root.open
    }

    PwNodePeakMonitor {
        id: inMeter
        node: root.open ? Pipewire.defaultAudioSource : null
        enabled: root.open
    }

    IpcHandler {
        target: "audio"
        function toggle(): void { root.open = !root.open }
        function status(): string {
            const out = []
            for (let i = 0; i < root.count; i++) {
                const name = i === 0 ? "output" : "input"
                out.push(root.node(i)
                    ? name + " " + root.label(i) + " " + Math.round(root.level(i) * 100) + "%" + (root.muted(i) ? " muted" : "")
                    : name + " unavailable")
            }
            return out.join(", ")
        }
    }
}

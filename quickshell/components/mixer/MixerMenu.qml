import "../core"
import "../brightness"
import "../audio"
import QtQuick

Fade {
    id: root
    property int sel: 0
    readonly property int bn: Brightness.count
    readonly property int an: Audio.count
    readonly property int sn: Theme.mixerApps ? Audio.streamCount : 0
    readonly property int total: bn + an + sn

    width: Math.max(0, total * Theme.mixerColW + Math.max(0, total - 1) * Theme.mixerColGap)
    height: rail.height
    focus: shown

    function pick() {
        sel = root.bn > 0 ? Brightness.home() : 0
        forceActiveFocus()
    }

    function kindOf(i) {
        return i < root.bn ? "bright" : i < root.bn + root.an ? "audio" : "stream"
    }

    function localOf(i) {
        return i < root.bn ? i : i < root.bn + root.an ? i - root.bn : i - root.bn - root.an
    }

    function move(d) {
        if (root.total < 2)
            return
        sel = ((sel + d) % root.total + root.total) % root.total
    }

    function nudge(d) {
        if (root.total === 0)
            return
        const k = kindOf(sel)
        const l = localOf(sel)
        if (k === "bright")
            Brightness.nudge(l, d)
        else if (k === "audio")
            Audio.nudge(l, d)
        else
            Audio.streamNudge(l, d)
    }

    function setv(v) {
        if (root.total === 0)
            return
        const k = kindOf(sel)
        const l = localOf(sel)
        if (k === "bright")
            Brightness.set(l, v)
        else if (k === "audio")
            Audio.set(l, v)
        else
            Audio.streamSet(l, v)
    }

    function toggleMute() {
        if (root.total === 0)
            return
        const k = kindOf(sel)
        const l = localOf(sel)
        if (k === "audio")
            Audio.toggleMute(l)
        else if (k === "stream")
            Audio.streamToggleMute(l)
    }

    onTotalChanged: sel = Math.max(0, Math.min(root.total - 1, sel))
    onVisibleChanged: if (visible) pick()

    Connections {
        target: Mixer
        function onOpenChanged() {
            if (Mixer.open)
                root.pick()
        }
    }

    Keys.onPressed: e => {
        const k = e.key
        const s = e.modifiers & Qt.ShiftModifier ? Theme.mixerFineStep : Theme.mixerStep
        if (k === Qt.Key_Escape)
            Mixer.open = false
        else if (k === Qt.Key_M || k === Qt.Key_Space)
            root.toggleMute()
        else if (k === Qt.Key_Up || k === Qt.Key_K)
            root.nudge(s)
        else if (k === Qt.Key_Down || k === Qt.Key_J)
            root.nudge(-s)
        else if (k === Qt.Key_Right || k === Qt.Key_L || k === Qt.Key_Tab)
            root.move(1)
        else if (k === Qt.Key_Left || k === Qt.Key_H || k === Qt.Key_Backtab)
            root.move(-1)
        else if (k === Qt.Key_PageUp)
            root.nudge(Theme.mixerBigStep)
        else if (k === Qt.Key_PageDown)
            root.nudge(-Theme.mixerBigStep)
        else if (k === Qt.Key_Home)
            root.setv(0)
        else if (k === Qt.Key_End)
            root.setv(1)
        else if (k === Qt.Key_O)
            Audio.cycle(0)
        else if (k === Qt.Key_I)
            Audio.cycle(1)
        else
            return
        e.accepted = true
    }

    Row {
        id: rail
        spacing: Theme.mixerColGap

        Repeater {
            model: Brightness.devices

            MixerTrack {
                required property int index

                label: ""
                path: Theme.brightSunPath
                filled: false
                focused: root.sel === index
                onPicked: root.sel = index
                onMoved: v => Brightness.set(index, v)
                onStepped: d => {
                    root.sel = index
                    Brightness.nudge(index, d)
                }
            }
        }

        Repeater {
            model: [
                { path: Theme.audioSpeakerPath, path2: "", filled: false, waves: true },
                { path: Theme.audioInPath, path2: Theme.audioInCradlePath, filled: true, waves: false }
            ]

            MixerTrack {
                required property int index
                required property var modelData
                readonly property int gi: root.bn + index

                visible: index < root.an
                value: Audio.level(index)
                ready: Audio.ready(index)
                label: ""
                muted: Audio.muted(index)
                path: modelData.path
                path2: modelData.path2
                filled: modelData.filled
                waves: modelData.waves
                toggles: true
                focused: root.sel === gi
                onPicked: root.sel = gi
                onMoved: v => Audio.set(index, v)
                onStepped: d => {
                    root.sel = gi
                    Audio.nudge(index, d)
                }
                onToggled: Audio.toggleMute(index)
            }
        }

        Repeater {
            model: root.sn

            MixerTrack {
                required property int index
                readonly property int gi: root.bn + root.an + index

                value: Audio.streamLevel(index)
                ready: Audio.streamReady(index)
                label: Audio.streamLabel(index)
                muted: Audio.streamMuted(index)
                icon: Audio.streamIcon(index)
                path: Theme.audioSpeakerPath
                filled: false
                waves: true
                toggles: true
                focused: root.sel === gi
                onPicked: root.sel = gi
                onMoved: v => Audio.streamSet(index, v)
                onStepped: d => {
                    root.sel = gi
                    Audio.streamNudge(index, d)
                }
                onToggled: Audio.streamToggleMute(index)
            }
        }
    }
}

import "../core"
import "../brightness"
import "../audio"
import QtQuick

Fade {
    id: root
    property int sel: 0
    readonly property int bn: Brightness.count
    readonly property int an: Audio.count
    readonly property int total: bn + an

    width: Math.max(0, total * Theme.mixerColW + Math.max(0, total - 1) * Theme.mixerColGap)
    height: row.height
    focus: shown

    function pick() {
        sel = root.bn > 0 ? Brightness.home() : 0
        forceActiveFocus()
    }

    function kindOf(i) {
        return i < root.bn ? "bright" : "audio"
    }

    function audioIndex(i) {
        return i - root.bn
    }

    function move(d) {
        if (root.total < 2)
            return
        sel = ((sel + d) % root.total + root.total) % root.total
    }

    function nudge(d) {
        if (root.total === 0)
            return
        if (kindOf(sel) === "bright")
            Brightness.nudge(sel, d)
        else
            Audio.nudge(audioIndex(sel), d)
    }

    function setv(v) {
        if (root.total === 0)
            return
        if (kindOf(sel) === "bright")
            Brightness.set(sel, v)
        else
            Audio.set(audioIndex(sel), v)
    }

    function toggleMute() {
        if (root.total === 0 || kindOf(sel) === "bright")
            return
        Audio.toggleMute(audioIndex(sel))
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
        else
            return
        e.accepted = true
    }

    Row {
        id: row
        spacing: Theme.mixerColGap

        Repeater {
            model: Brightness.devices

            MixerTrack {
                required property int index

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
                meter: true
                peak: Audio.peak(index)
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
    }
}

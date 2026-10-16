import "../core"
import QtQuick

Fade {
    id: root
    property int sel: 0
    readonly property int n: Audio.count

    width: Theme.audioW - 2 * Theme.audioPad
    height: col.height
    focus: shown

    function pick() {
        sel = 0
        forceActiveFocus()
    }

    function move(d, wrap) {
        if (n < 2)
            return
        sel = wrap ? ((sel + d) % n + n) % n : Math.max(0, Math.min(n - 1, sel + d))
    }

    onNChanged: sel = Math.max(0, Math.min(n - 1, sel))
    onVisibleChanged: if (visible) pick()

    Connections {
        target: Audio
        function onOpenChanged() {
            if (Audio.open)
                root.pick()
        }
    }

    Keys.onPressed: e => {
        const k = e.key
        const s = e.modifiers & Qt.ShiftModifier ? Theme.audioFineStep : Theme.audioStep
        const solo = root.n < 2
        if (k === Qt.Key_Escape)
            Audio.open = false
        else if (k === Qt.Key_M || k === Qt.Key_Space)
            Audio.toggleMute(sel)
        else if (k === Qt.Key_D)
            Audio.cycle(sel)
        else if (k === Qt.Key_Right || k === Qt.Key_L || (solo && (k === Qt.Key_Up || k === Qt.Key_K)))
            Audio.nudge(sel, s)
        else if (k === Qt.Key_Left || k === Qt.Key_H || (solo && (k === Qt.Key_Down || k === Qt.Key_J)))
            Audio.nudge(sel, -s)
        else if (k === Qt.Key_Up || k === Qt.Key_K)
            move(-1, false)
        else if (k === Qt.Key_Down || k === Qt.Key_J)
            move(1, false)
        else if (k === Qt.Key_Tab)
            move(1, true)
        else if (k === Qt.Key_Backtab)
            move(-1, true)
        else if (k === Qt.Key_PageUp)
            Audio.nudge(sel, Theme.audioBigStep)
        else if (k === Qt.Key_PageDown)
            Audio.nudge(sel, -Theme.audioBigStep)
        else if (k === Qt.Key_Home)
            Audio.set(sel, 0)
        else if (k === Qt.Key_End)
            Audio.set(sel, 1)
        else
            return
        e.accepted = true
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.audioGap

        Repeater {
            model: [
                { body: Theme.audioOutPath, stroke: "" },
                { body: Theme.audioInPath, stroke: Theme.audioInCradlePath }
            ]

            AudioRow {
                required property int index
                required property var modelData

                visible: index < root.n
                bodyPath: modelData.body
                strokePath: modelData.stroke
                name: Audio.label(index)
                value: Audio.level(index)
                peak: Audio.peak(index)
                ready: Audio.ready(index)
                muted: Audio.muted(index)
                switchable: Audio.list(index).length > 1
                focused: root.n > 1 && root.sel === index
                onPicked: root.sel = index
                onToggled: Audio.toggleMute(index)
                onCycled: Audio.cycle(index)
                onMoved: v => Audio.set(index, v)
                onStepped: d => {
                    root.sel = index
                    Audio.nudge(index, d)
                }
            }
        }
    }
}

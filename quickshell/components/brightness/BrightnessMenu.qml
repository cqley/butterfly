import "../core"
import QtQuick

Fade {
    id: root
    property int sel: 0
    readonly property int n: Brightness.count

    width: Theme.brightW - 2 * Theme.brightPad
    height: col.height
    focus: shown

    function pick() {
        sel = Brightness.home()
        forceActiveFocus()
    }

    function move(d, wrap) {
        if (n < 2)
            return
        sel = wrap ? ((sel + d) % n + n) % n : Math.max(0, Math.min(n - 1, sel + d))
    }

    onNChanged: sel = Brightness.home()
    onVisibleChanged: if (visible) pick()

    Connections {
        target: Brightness
        function onOpenChanged() {
            if (Brightness.open)
                root.pick()
        }
    }

    Keys.onPressed: e => {
        const k = e.key
        const s = e.modifiers & Qt.ShiftModifier ? Theme.brightFineStep : Theme.brightStep
        const solo = root.n < 2
        if (k === Qt.Key_Escape)
            Brightness.open = false
        else if (k === Qt.Key_Right || k === Qt.Key_L || (solo && (k === Qt.Key_Up || k === Qt.Key_K)))
            Brightness.nudge(sel, s)
        else if (k === Qt.Key_Left || k === Qt.Key_H || (solo && (k === Qt.Key_Down || k === Qt.Key_J)))
            Brightness.nudge(sel, -s)
        else if (k === Qt.Key_Up || k === Qt.Key_K)
            move(-1, false)
        else if (k === Qt.Key_Down || k === Qt.Key_J)
            move(1, false)
        else if (k === Qt.Key_Tab)
            move(1, true)
        else if (k === Qt.Key_Backtab)
            move(-1, true)
        else if (k === Qt.Key_PageUp)
            Brightness.nudge(sel, Theme.brightBigStep)
        else if (k === Qt.Key_PageDown)
            Brightness.nudge(sel, -Theme.brightBigStep)
        else if (k === Qt.Key_Home)
            Brightness.set(sel, 0)
        else if (k === Qt.Key_End)
            Brightness.set(sel, 1)
        else
            return
        e.accepted = true
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.brightGap

        BrightnessTrack {
            visible: root.n === 0
            value: 0
            ready: false
            label: ""
        }

        Repeater {
            model: Brightness.devices

            BrightnessTrack {
                required property int index
                labeled: root.n > 1
                onPicked: root.sel = index
                onMoved: v => Brightness.set(index, v)
                onStepped: d => {
                    root.sel = index
                    Brightness.nudge(index, d)
                }
            }
        }
    }
}

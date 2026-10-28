import QtQuick

Fade {
    id: root
    property int n: 0
    property int rows: 5
    property int sel: 0
    property int start: 0
    property bool snap: false
    property real px: -1
    property real py: -1
    property var view: []
    property bool churn: false
    readonly property bool settled: !root.churn
    readonly property int dur: Theme.glide

    Timer {
        id: release
        interval: 0
        onTriggered: root.snap = false
    }

    function hold() {
        snap = true
        release.restart()
    }

    function move(d, wrap) {
        if (!n)
            return
        const t = wrap ? ((sel + d) % n + n) % n : Math.max(0, Math.min(n - 1, sel + d))
        snap = Math.abs(t - sel) !== 1
        sel = t
        if (snap)
            release.restart()
    }

    function reset() {
        hold()
        sel = 0
        start = 0
        px = -1
        py = -1
    }

    onNChanged: {
        if (n <= 0) {
            sel = 0
            start = 0
        } else {
            sel = Math.max(0, Math.min(n - 1, sel))
            start = Math.max(0, Math.min(Math.max(0, n - rows), start))
        }
    }

    function aim(p, i) {
        if (p.x === px && p.y === py)
            return
        px = p.x
        py = p.y
        if (i >= 0 && i < n)
            sel = i
    }

    function nav(e) {
        if (e.isAutoRepeat)
            return true
        const k = e.key
        const c = e.modifiers & Qt.ControlModifier
        const s = e.modifiers & Qt.ShiftModifier
        const w = true
        if (k === Qt.Key_Down || k === Qt.Key_J || k === Qt.Key_L || k === Qt.Key_Tab || c && k === Qt.Key_N)
            move(1, w)
        else if (k === Qt.Key_Up || k === Qt.Key_K || k === Qt.Key_H || k === Qt.Key_Backtab || c && k === Qt.Key_P)
            move(-1, w)
        else if (k === Qt.Key_PageDown)
            move(1, false)
        else if (k === Qt.Key_PageUp)
            move(-1, false)
        else if (k === Qt.Key_End || k === Qt.Key_G && s)
            move(n, false)
        else if (k === Qt.Key_Home || k === Qt.Key_G)
            move(-n, false)
        else
            return false
        return true
    }

    onSelChanged: {
        if (sel < start)
            start = sel
        else if (sel > start + rows - 1)
            start = sel - rows + 1
    }
}

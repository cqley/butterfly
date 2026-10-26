import QtQuick

Fade {
    id: root
    property int n: 0
    property int sel: 0
    property bool snap: false
    property real px: -1
    property real py: -1

    function reset() {
        snap = true
        sel = 0
        px = -1
        py = -1
        snap = false
    }

    function aim(p, i) {
        if (p.x === px && p.y === py)
            return
        px = p.x
        py = p.y
        sel = i
    }

    function nav(e) {
        if (!n)
            return false
        const k = e.key
        const s = e.modifiers & Qt.ShiftModifier
        if (k === Qt.Key_Right || k === Qt.Key_L || k === Qt.Key_J || k === Qt.Key_Tab)
            sel = (sel + 1) % n
        else if (k === Qt.Key_Left || k === Qt.Key_H || k === Qt.Key_K || k === Qt.Key_Backtab)
            sel = (sel + n - 1) % n
        else if (k === Qt.Key_End || k === Qt.Key_G && s)
            sel = n - 1
        else if (k === Qt.Key_Home || k === Qt.Key_G)
            sel = 0
        else
            return false
        return true
    }

    onNChanged: if (sel >= n) sel = Math.max(0, n - 1)
}

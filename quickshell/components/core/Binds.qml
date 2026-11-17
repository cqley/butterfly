pragma Singleton
import QtQuick
import Quickshell

Singleton {
    function action(e, mode) {
        const k = e.key
        const insert = mode === "insert"
        const c = e.modifiers & Qt.ControlModifier
        const v = !insert || c
        if (k === Qt.Key_Escape)
            return "cancel"
        if (k === Qt.Key_Return || k === Qt.Key_Enter || !insert && k === Qt.Key_Space)
            return "accept"
        if (!insert && (k === Qt.Key_Delete || k === Qt.Key_Backspace))
            return "delete"
        if (k === Qt.Key_Tab || c && k === Qt.Key_N)
            return "next"
        if (k === Qt.Key_Backtab || c && k === Qt.Key_P)
            return "prev"
        if (k === Qt.Key_Down || v && k === Qt.Key_J)
            return "down"
        if (k === Qt.Key_Up || v && k === Qt.Key_K)
            return "up"
        if (k === Qt.Key_Left || v && k === Qt.Key_H)
            return "left"
        if (k === Qt.Key_Right || v && k === Qt.Key_L)
            return "right"
        if (k === Qt.Key_PageDown)
            return "pageDown"
        if (k === Qt.Key_PageUp)
            return "pageUp"
        if (v && k === Qt.Key_Home)
            return "home"
        if (v && k === Qt.Key_End)
            return "end"
        if (v && k === Qt.Key_G)
            return e.modifiers & Qt.ShiftModifier ? "bottom" : "top"
        return insert ? "" : e.text.toLowerCase()
    }

    readonly property var held: ["up", "down", "left", "right", "next", "prev", "pageUp", "pageDown"]

    function run(e, map, mode) {
        const a = action(e, mode)
        const f = map[a]
        if (typeof f !== "function")
            return false
        e.accepted = true
        if (!e.isAutoRepeat || mode === "hold" && held.includes(a))
            f()
        return true
    }

    function step(f) {
        const fwd = () => f(1)
        const back = () => f(-1)
        return {
            down: fwd, right: fwd, next: fwd,
            up: back, left: back, prev: back
        }
    }

    function list(move, count) {
        const top = () => move(-count(), false)
        const bottom = () => move(count(), false)
        return Object.assign(step(d => move(d, true)), {
            pageDown: () => move(1, false),
            pageUp: () => move(-1, false),
            top: top, home: top,
            bottom: bottom, end: bottom
        })
    }
}

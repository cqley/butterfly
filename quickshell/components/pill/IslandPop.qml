import "../core"
import QtQuick

QtObject {
    id: root
    property bool hovered: false
    property bool armed: true
    property bool media: false
    property bool open: false
    property var at: ({ mode: "home", level: 0 })

    readonly property string mode: root.at.mode
    readonly property int level: root.at.level
    readonly property int pages: root.mode === "dates" || root.media ? 2 : 1
    readonly property int depth: level > 0 ? level + 1 : (hovered && armed ? 1 : 0)
    readonly property bool popped: depth >= 1
    readonly property string face: root.level === 0 ? (root.popped ? "peek" : "")
        : root.mode === "dates" ? (root.level >= 2 ? "calendar" : "week")
        : root.level >= 2 ? "media" : "dash"
    readonly property bool dashShown: root.face === "dash"
    readonly property bool mediaShown: root.face === "media"
    readonly property bool weekShown: root.face === "week"
    readonly property bool calendarShown: root.face === "calendar"
    readonly property string primary: root.level > 0 ? root.mode : "home"
    readonly property string report: root.face === "" ? "closed" : root.face

    function go(mode, level) {
        root.at = { mode: mode, level: level }
    }

    function show(next) {
        root.armed = true
        if (root.mode === next && root.level > 0) {
            root.go(next, root.level < root.pages ? root.level + 1 : (root.pages > 1 ? 1 : 0))
            return
        }
        root.go(next, 1)
    }

    function toggleFace(name) {
        if (root.face === name) {
            root.open = false
            return root.report
        }
        if (name === "media" && !root.media)
            return "no media"
        root.armed = true
        const dates = name === "week" || name === "calendar"
        root.go(dates ? "dates" : "home", name === "calendar" || name === "media" ? 2 : 1)
        return root.report
    }

    onHoveredChanged: if (!hovered) armed = true

    onAtChanged: {
        if (root.at.level > 0) {
            root.open = true
            Modal.claim("island")
        } else {
            root.open = false
        }
    }

    onOpenChanged: {
        if (root.open && root.at.level === 0) {
            root.go(root.at.mode, 1)
        } else if (!root.open && root.at.level > 0) {
            root.go(root.at.mode, 0)
            root.armed = !root.hovered
        }
    }
}

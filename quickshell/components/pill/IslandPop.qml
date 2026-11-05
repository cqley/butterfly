import "../core"
import QtQuick

QtObject {
    id: root
    property bool hovered: false
    property bool armed: true
    property bool media: false
    property string mode: "dates"
    property int level: 0
    property bool open: false

    readonly property int pages: root.mode === "dates" ? 2 : 1
    readonly property int depth: level > 0 ? level + 1 : (hovered && armed ? 1 : 0)
    readonly property bool popped: depth >= 1
    readonly property bool mediaShown: depth === 2 && mode === "media"
    readonly property bool weekShown: depth === 2 && mode === "dates"
    readonly property bool calendarShown: depth >= 3
    readonly property string face: calendarShown ? "calendar" : mediaShown ? "media" : weekShown ? "week" : popped ? "peek" : ""
    readonly property string primary: root.level > 0 ? root.mode : "media"
    readonly property string report: root.face === "" ? "closed" : root.face

    function show(next) {
        if (root.mode === next && root.level > 0) {
            root.armed = true
            root.level = root.level < root.pages ? root.level + 1 : (root.pages > 1 ? 1 : 0)
            return
        }
        if (next === "media" && !root.media)
            return
        root.armed = true
        root.mode = next
        root.level = 1
    }

    function toggleFace(name) {
        if (root.face === name) {
            root.open = false
            return root.report
        }
        if (name === "media" && !root.media)
            return "no media"
        root.armed = true
        root.mode = name === "media" ? "media" : "dates"
        root.level = name === "calendar" ? 2 : 1
        return root.report
    }

    onHoveredChanged: if (!hovered) armed = true

    onLevelChanged: {
        if (level > 0) {
            open = true
            Modal.claim("island")
        } else {
            open = false
        }
    }

    onOpenChanged: {
        if (open && level === 0) {
            if (mode === "media" && !media)
                mode = "dates"
            level = 1
        } else if (!open && level > 0) {
            level = 0
            armed = !hovered
        }
    }
}

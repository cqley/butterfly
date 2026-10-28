import "../core"
import QtQuick

QtObject {
    id: root
    property bool enabled: false
    property bool hovered: false
    property bool armed: true
    property bool media: false
    property bool mediaLatch: false
    property int level: 0
    property bool open: false

    readonly property int depth: level > 0 ? level + 1 : (enabled && hovered && armed ? 1 : 0)
    readonly property bool popped: depth >= 1
    readonly property bool mediaShown: depth === 2 && mediaLatch
    readonly property bool weekShown: depth === 2 && !mediaLatch
    readonly property bool calendarShown: depth >= 3

    function click() {
        if (!enabled)
            return
        armed = true
        level = level === 2 ? 1 : level + 1
    }

    onHoveredChanged: if (!hovered) armed = true

    onLevelChanged: {
        if (level === 1)
            mediaLatch = media
        if (level > 0) {
            open = true
            Modal.claim("island")
        } else {
            open = false
        }
    }

    onOpenChanged: {
        if (!open && level > 0) {
            level = 0
            armed = !hovered
        }
    }

    onEnabledChanged: {
        if (enabled)
            return
        level = 0
        armed = true
    }
}

import "../core"
import QtQuick

QtObject {
    id: root
    property bool enabled: false
    property bool hovered: false
    property int depth: 0
    property bool open: false

    readonly property bool popped: depth >= 1
    readonly property bool weekShown: depth >= 2
    readonly property bool calendarShown: depth >= 3

    function click() {
        if (!enabled || !hovered)
            return
        depth = depth === 3 ? 2 : Math.min(3, depth + 1)
    }

    onHoveredChanged: {
        if (!enabled)
            return
        if (hovered) {
            if (depth === 0)
                depth = 1
        } else if (depth > 0) {
            depth = depth - 1
        }
    }

    onEnabledChanged: if (!enabled) depth = 0

    onCalendarShownChanged: {
        if (calendarShown) {
            open = true
            Modal.claim("island")
        } else {
            open = false
        }
    }

    onOpenChanged: if (!open && depth === 3) depth = 0
}

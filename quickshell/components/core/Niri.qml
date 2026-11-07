pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []
    readonly property var focused: root.workspaces.find(w => w.is_focused) || null

    function apply(ev) {
        if (ev.WorkspacesChanged) {
            root.workspaces = ev.WorkspacesChanged.workspaces
        } else if (ev.WorkspaceActivated) {
            const id = ev.WorkspaceActivated.id
            const hit = root.workspaces.find(w => w.id === id)
            if (!hit)
                return
            const focus = ev.WorkspaceActivated.focused
            root.workspaces = root.workspaces.map(w => Object.assign({}, w, {
                is_active: w.output === hit.output ? w.id === id : w.is_active,
                is_focused: focus ? w.id === id : w.is_focused
            }))
        } else if (ev.WorkspaceActiveWindowChanged) {
            const d = ev.WorkspaceActiveWindowChanged
            root.workspaces = root.workspaces.map(w => w.id === d.workspace_id
                ? Object.assign({}, w, { active_window_id: d.active_window_id }) : w)
        }
    }

    Process {
        id: stream
        running: Compositor.isNiri
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.apply(JSON.parse(line))
                } catch (e) {}
            }
        }
        onExited: if (Compositor.isNiri) retry.restart()
    }

    Timer {
        id: retry
        interval: 1000
        onTriggered: stream.running = true
    }
}

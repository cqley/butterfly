import QtQuick

Panel {
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
    property var keys: ({})
    property bool frozen: false
    property var entries: []
    property var identity: null
    property string anchor: ""
    property bool holdResync: true

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

    function remember() {
        if (root.identity && root.entries && root.entries[sel])
            anchor = root.identity(root.entries[sel])
    }

    function syncSel() {
        if (!n) {
            anchor = ""
            return
        }
        if (anchor !== "") {
            for (let i = 0; i < n; i++) {
                if (root.entries[i] && root.identity(root.entries[i]) === anchor) {
                    if (i !== sel) {
                        if (root.holdResync)
                            hold()
                        sel = i
                    }
                    return
                }
            }
        }
        const i = Math.max(0, Math.min(n - 1, sel))
        if (i !== sel) {
            if (root.holdResync)
                hold()
            sel = i
        }
        remember()
    }

    Keys.onPressed: e => Binds.run(e, Object.assign(root.frozen ? {} : Binds.list((d, w) => root.move(d, w), () => root.n), root.keys))

    onSelChanged: {
        remember()
        if (sel < start)
            start = sel
        else if (sel > start + rows - 1)
            start = sel - rows + 1
    }
}

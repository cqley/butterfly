import QtQuick

Panel {
    id: root
    property int n: 0
    property int sel: 0
    property bool snap: false
    property real px: -1
    property real py: -1
    property var keys: ({})

    Timer {
        id: release
        interval: 0
        onTriggered: root.snap = false
    }

    function reset() {
        snap = true
        release.restart()
        sel = 0
        px = -1
        py = -1
    }

    function aim(p, i) {
        if (p.x === px && p.y === py)
            return
        px = p.x
        py = p.y
        sel = i
    }

    function move(d, wrap) {
        if (!n)
            return
        sel = wrap ? ((sel + d) % n + n) % n : Math.max(0, Math.min(n - 1, sel + d))
    }

    Keys.onPressed: e => Binds.run(e, Object.assign(Binds.list((d, w) => root.move(d, w), () => root.n), { pageDown: null, pageUp: null }, root.keys))

    onNChanged: if (sel >= n) sel = Math.max(0, n - 1)
}

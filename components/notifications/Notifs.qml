pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    property var current: null
    property var queue: []
    property bool hovered: false

    onHoveredChanged: if (current) {
        if (hovered)
            hold.stop()
        else
            armHold(current)
    }

    function dwellFor(n) {
        if (!n)
            return Theme.dwell
        if (n.system)
            return n.kind === "battery" ? Theme.dwellCritical : Theme.dwell
        const t = Number(n.expireTimeout)
        if (isFinite(t) && t === 0)
            return Theme.dwellNever
        if (isFinite(t) && t > 0)
            return Math.min(Theme.dwellMax, Math.max(Theme.dwellMin, Math.round(t)))
        if (n.urgency === NotificationUrgency.Critical)
            return Theme.dwellCritical
        return Theme.dwell
    }

    function armHold(n) {
        const ms = dwellFor(n)
        if (ms <= 0) {
            hold.stop()
            return
        }
        hold.interval = ms
        hold.restart()
    }

    function trim(list) {
        const cut = list.length - Theme.notificationQueueMax
        if (cut <= 0)
            return list
        for (const n of list.slice(0, cut))
            if (n && !n.system && n.tracked)
                n.expire()
        return list.slice(cut)
    }

    function touched() {
        if (current && !hovered)
            armHold(current)
    }

    function sameId(a, b) {
        return a && b && !a.system && !b.system && a.id === b.id
    }

    function push(n) {
        if (!n)
            return
        n.tracked = true

        if (sameId(current, n)) {
            current = n
            if (!hovered)
                armHold(n)
            return
        }

        const qi = queue.findIndex(x => sameId(x, n))
        if (qi >= 0) {
            const next = queue.slice()
            next[qi] = n
            queue = next
            return
        }

        queue = trim([...queue, n])
        if (current === null && !gap.running)
            pump()
    }

    function pushSystem(summary, body, charging, kind = "battery", failed = false, level = -1) {
        const same = n => n && n.system && n.kind === kind && n.summary === summary && (kind === "battery" || n.body === body)
        if (same(current) || queue.some(same))
            return

        queue = trim([...queue, {
            system: true,
            kind: kind,
            summary: summary,
            body: body,
            appName: "system",
            appIcon: "",
            image: "",
            urgency: failed ? NotificationUrgency.Critical : NotificationUrgency.Normal,
            charging: charging,
            level: level
        }])
        if (current === null && !gap.running)
            pump()
    }

    function alive(n) {
        if (!n)
            return false
        if (n.system)
            return true
        return n.tracked !== false
    }

    function pump() {
        const q = queue.filter(alive)
        queue = q.slice(1)
        if (q.length === 0)
            return
        current = q[0]
        if (!hovered)
            armHold(current)
    }

    function next() {
        hold.stop()
        current = null
        gap.restart()
    }

    function dismiss() {
        const n = current
        if (!n)
            return
        next()
        if (!n.system)
            n.dismiss()
    }

    function drop() {
        const n = current
        if (!n)
            return
        next()
        if (!n.system)
            n.expire()
    }

    Timer {
        id: hold
        onTriggered: root.drop()
    }

    Timer {
        id: gap
        interval: Theme.speed
        onTriggered: root.pump()
    }

    Connections {
        id: watched
        property var item: root.current && !root.current.system ? root.current : null
        target: item
        ignoreUnknownSignals: true
        function onClosed() {
            if (root.current === item)
                root.next()
        }
        function onSummaryChanged() { root.touched() }
        function onBodyChanged() { root.touched() }
        function onUrgencyChanged() { root.touched() }
        function onExpireTimeoutChanged() { root.touched() }
    }

    NotificationServer {
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        onNotification: n => root.push(n)
    }
}

pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root
    property var current: null
    property var queue: []
    property bool hovered: false
    property bool open: false
    property bool dnd: false
    property var history: []
    property int seq: 0

    onOpenChanged: if (open) Modal.claim("notifs")

    function plain(text) {
        return String(text || "")
            .replace(/^\s*<a[^>]*>.*?<\/a>\s*/i, "")
            .replace(/<[^>]*>/g, "")
            .replace(/\s+/g, " ")
            .trim()
    }

    function fileUrl(value) {
        const v = String(value || "").trim()
        if (v === "")
            return ""
        if (/^[a-z][a-z0-9+.-]*:/i.test(v))
            return v
        if (v.startsWith("/"))
            return Theme.url(v)
        const hit = Quickshell.iconPath(v, true)
        if (!hit)
            return ""
        if (hit.startsWith("/") || /^[a-z][a-z0-9+.-]*:/i.test(hit))
            return Theme.url(hit)
        return hit
    }

    function snap(n) {
        const own = !!n.system
        const name = String(n.appName || "").trim()
        const raw = own ? "" : String(n.image || "")
        return {
            key: "",
            nid: own ? -1 : n.id,
            system: own,
            kind: own ? String(n.kind || "") : "",
            summary: plain(n.summary),
            body: plain(n.body),
            app: own ? "system" : name.toLowerCase(),
            letter: ((name || "?")[0] || "?").toLowerCase(),
            picture: own || /^image:\/\/qsimage\//i.test(raw) ? "" : fileUrl(raw),
            mark: own ? "" : (fileUrl(n.appIcon) || fileUrl(n.desktopEntry)),
            critical: n.urgency === NotificationUrgency.Critical,
            on: !!n.charging,
            level: own && isFinite(Number(n.level)) ? Number(n.level) : -1,
            time: Date.now()
        }
    }

    function echoes(a, b) {
        return a && b && a.system && b.system && a.kind === b.kind && a.summary === b.summary && a.body === b.body
    }

    function coalesceHead(h, e) {
        if (!echoes(h[0], e))
            return null
        e.key = h[0].key
        const next = h.slice()
        next[0] = e
        return next
    }

    function replaceById(h, e) {
        if (e.system)
            return null
        const i = h.findIndex(x => !x.system && x.nid === e.nid)
        if (i < 0)
            return null
        e.key = h[i].key
        e.time = h[i].time
        const next = h.slice()
        next[i] = e
        return next
    }

    function insertNew(h, e) {
        e.key = "h" + (++seq)
        return [e, ...h]
    }

    function remember(n) {
        if (!n)
            return
        const e = snap(n)
        const h = history.slice()
        const merged = coalesceHead(h, e) || replaceById(h, e) || insertNew(h, e)
        history = merged.slice(0, Theme.notificationHistoryMax)
    }

    function forget(key) {
        const e = history.find(x => x.key === key)
        history = history.filter(x => x.key !== key)
        if (!e)
            return
        if (e.system) {
            if (echoes(current, e))
                next()
            queue = queue.filter(x => !echoes(x, e))
            return
        }
        if (current && !current.system && current.id === e.nid) {
            dismiss()
            return
        }
        const hit = queue.find(x => x && !x.system && x.id === e.nid)
        if (!hit)
            return
        queue = queue.filter(x => x !== hit)
        if (hit.tracked)
            hit.dismiss()
    }

    function flush(expire) {
        for (const x of queue) {
            if (!x || x.system || !x.tracked)
                continue
            if (expire)
                x.expire()
            else
                x.dismiss()
        }
        queue = []
        if (!current)
            return
        if (expire)
            drop()
        else
            dismiss()
    }

    function clear() {
        history = []
        flush(false)
    }

    function toggleDnd() {
        dnd = !dnd
        if (dnd)
            flush(true)
        pushSystem(dnd ? "do not disturb on" : "do not disturb off", "", dnd, "dnd")
    }

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
            return n.kind === "battery" || n.urgency === NotificationUrgency.Critical
                ? Theme.dwellCritical
                : Theme.dwell
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
        remember(current)
        if (current && !hovered)
            armHold(current)
    }

    function sameId(a, b) {
        return a && b && !a.system && !b.system && a.id === b.id
    }

    function enqueue(item) {
        queue = trim([...queue, item])
        if (current === null && !gap.running)
            pump()
    }

    function push(n) {
        if (!n)
            return
        n.tracked = true
        remember(n)

        if (dnd) {
            n.expire()
            return
        }

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

        enqueue(n)
    }

    function pushSystem(summary, body, charging, kind = "battery", failed = false, level = -1) {
        const item = {
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
        }
        const mode = kind === "dnd"
        if (!mode)
            remember(item)
        if (dnd && !mode)
            return
        if (open && mode)
            return

        const same = n => n && n.system && n.kind === kind && n.summary === summary && (kind === "battery" || n.body === body)
        if (same(current) || queue.some(same))
            return

        enqueue(item)
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
        if (!n.system && n.tracked)
            n.dismiss()
    }

    function drop() {
        const n = current
        if (!n)
            return
        next()
        if (!n.system && n.tracked)
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

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.open = !root.open }
        function clear(): void { root.clear() }
        function status(): string {
            return (root.open ? "open" : "closed") + " · " + (root.dnd ? "dnd" : "on") + " · " + root.history.length
        }
    }

    IpcHandler {
        target: "dnd"
        function toggle(): void { root.toggleDnd() }
        function status(): string { return root.dnd ? "on" : "off" }
    }
}

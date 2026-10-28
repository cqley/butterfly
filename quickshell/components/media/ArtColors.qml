import "../core"
import QtQuick

Item {
    id: root
    property string source: ""
    property string loaded: ""
    property color a: Theme.visFallback
    property color b: Theme.visFallback

    Behavior on a { ColorAnimation { duration: Theme.visTint; easing.type: Theme.ease } }

    Behavior on b { ColorAnimation { duration: Theme.visTint; easing.type: Theme.ease } }

    onSourceChanged: {
        if (loaded !== "" && loaded !== source)
            cv.unloadImage(loaded)
        loaded = source
        wait.stop()
        if (source === "") {
            reset()
            return
        }
        if (cv.isImageLoaded(source)) {
            cv.requestPaint()
            return
        }
        cv.loadImage(source)
        wait.restart()
    }

    function reset() {
        a = Theme.visFallback
        b = Theme.visFallback
    }

    function rgb(k) {
        return Qt.rgba(((k >> 16) & 0xff) / 255, ((k >> 8) & 0xff) / 255, (k & 0xff) / 255, 1)
    }

    function chroma(c) {
        return Math.max(c.r, c.g, c.b) - Math.min(c.r, c.g, c.b)
    }

    function lift(c) {
        if (c.hslLightness >= Theme.visDim)
            return c
        return Qt.hsla(Math.max(0, c.hslHue), c.hslSaturation, Theme.visDim, 1)
    }

    function apart(x, y) {
        return Math.abs(x.r - y.r) + Math.abs(x.g - y.g) + Math.abs(x.b - y.b) >= Theme.visSpread
    }

    Timer {
        id: wait
        interval: Theme.visSampleWait
        onTriggered: if (!cv.isImageLoaded(root.source)) root.reset()
    }

    Canvas {
        id: cv
        width: Theme.visSampleSize
        height: Theme.visSampleSize
        visible: false

        onImageLoaded: requestPaint()

        onPaint: {
            const src = root.source
            if (src === "")
                return
            if (isImageError(src)) {
                wait.stop()
                root.reset()
                return
            }
            if (!isImageLoaded(src))
                return
            wait.stop()
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.drawImage(src, 0, 0, width, height)
            const d = ctx.getImageData(0, 0, width, height).data
            const bins = {}
            let mode = -1
            let modeN = 0
            let n = 0
            for (let i = 0; i < d.length; i += 4) {
                if (d[i + 3] < Theme.visSampleAlpha)
                    continue
                const k = ((d[i] & 0xf8) << 16) | ((d[i + 1] & 0xf8) << 8) | (d[i + 2] & 0xf8)
                const c = (bins[k] || 0) + 1
                bins[k] = c
                n++
                if (c > modeN) {
                    modeN = c
                    mode = k
                }
            }
            if (n === 0) {
                root.reset()
                return
            }
            let pick = mode
            let best = -1
            for (const key in bins) {
                const k = Number(key)
                const score = root.chroma(root.rgb(k)) * Math.sqrt(bins[k] / n)
                if (score > best) {
                    best = score
                    pick = k
                }
            }
            const base = root.rgb(mode)
            const lead = root.rgb(pick)
            if (root.chroma(lead) < Theme.visSatFloor) {
                root.reset()
                return
            }
            const tint = root.lift(base)
            root.a = tint
            root.b = root.apart(base, lead) ? root.lift(lead) : Qt.lighter(tint, Theme.visLift)
        }
    }
}

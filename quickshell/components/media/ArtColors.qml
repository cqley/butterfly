import "../core"
import QtQuick

Item {
    id: root
    property string source: ""
    property color a: Theme.visFallback
    property color b: Theme.visFallback

    onSourceChanged: {
        if (source === "") {
            a = Theme.visFallback
            b = Theme.visFallback
            return
        }
        if (cv.isImageLoaded(source))
            cv.requestPaint()
        else
            cv.loadImage(source)
    }

    Canvas {
        id: cv
        width: Theme.visSampleSize
        height: Theme.visSampleSize
        visible: false

        onImageLoaded: requestPaint()

        onPaint: {
            if (root.source === "" || !isImageLoaded(root.source))
                return
            const ctx = getContext("2d")
            ctx.drawImage(root.source, 0, 0, width, height)
            const d = ctx.getImageData(0, 0, width, height).data
            let sr = 0, sg = 0, sb = 0, n = 0
            let br = 0, bg = 0, bb = 0, bestSat = -1
            for (let i = 0; i < d.length; i += 4) {
                const r = d[i], g = d[i + 1], bl = d[i + 2]
                sr += r; sg += g; sb += bl; n++
                const mx = Math.max(r, g, bl), mn = Math.min(r, g, bl)
                const sat = mx === 0 ? 0 : (mx - mn) / mx
                if (sat > bestSat) {
                    bestSat = sat
                    br = r; bg = g; bb = bl
                }
            }
            if (n === 0)
                return
            root.a = Qt.rgba(sr / n / 255, sg / n / 255, sb / n / 255, 1)
            root.b = Qt.rgba(br / 255, bg / 255, bb / 255, 1)
        }
    }
}

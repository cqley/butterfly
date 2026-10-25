import "../core"
import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    property real pillW: 0
    property real pillH: 0
    property real pillRadius: 0
    property real pct: 0
    property color tone: Theme.accent

    readonly property real inset: Theme.batRingGap + Theme.batRingWidth / 2
    readonly property real rad: Math.max(0, pillRadius - inset)
    readonly property real clampedPct: Math.max(0, Math.min(1, pct))
    readonly property var segs: root.segList(root.width, root.height, root.rad)
    readonly property real segTotal: root.segs.reduce((sum, seg) => sum + seg.len, 0)
    readonly property string drawnPath: root.partialPath(root.segs, root.segTotal, root.rad, 0, root.clampedPct)
    readonly property string trackPath: root.partialPath(root.segs, root.segTotal, root.rad, root.clampedPct, 1)

    width: Math.max(0, pillW - inset * 2)
    height: Math.max(0, pillH - inset * 2)
    preferredRendererType: Shape.CurveRenderer

    function segList(w, h, rad) {
        return [
            { len: Math.max(0, w / 2 - rad), arc: false, sx: w / 2, sy: 0, ex: w - rad, ey: 0 },
            { len: (Math.PI / 2) * rad, arc: true, acx: w - rad, acy: rad, a0: -90, sx: w - rad, sy: 0, ex: w, ey: rad },
            { len: Math.max(0, h - 2 * rad), arc: false, sx: w, sy: rad, ex: w, ey: h - rad },
            { len: (Math.PI / 2) * rad, arc: true, acx: w - rad, acy: h - rad, a0: 0, sx: w, sy: h - rad, ex: w - rad, ey: h },
            { len: Math.max(0, w - 2 * rad), arc: false, sx: w - rad, sy: h, ex: rad, ey: h },
            { len: (Math.PI / 2) * rad, arc: true, acx: rad, acy: h - rad, a0: 90, sx: rad, sy: h, ex: 0, ey: h - rad },
            { len: Math.max(0, h - 2 * rad), arc: false, sx: 0, sy: h - rad, ex: 0, ey: rad },
            { len: (Math.PI / 2) * rad, arc: true, acx: rad, acy: rad, a0: 180, sx: 0, sy: rad, ex: rad, ey: 0 },
            { len: Math.max(0, w / 2 - rad), arc: false, sx: rad, sy: 0, ex: w / 2, ey: 0 }
        ]
    }

    function pointAt(seg, lenPos, segStart, rad) {
        const t = seg.len > 0 ? (lenPos - segStart) / seg.len : 0
        if (seg.arc) {
            const ang = (seg.a0 + 90 * t) * Math.PI / 180
            return { x: seg.acx + rad * Math.cos(ang), y: seg.acy + rad * Math.sin(ang) }
        }
        return { x: seg.sx + (seg.ex - seg.sx) * t, y: seg.sy + (seg.ey - seg.sy) * t }
    }

    function partialPath(segs, total, rad, fromFrac, toFrac) {
        if (total <= 0 || toFrac <= fromFrac)
            return ""

        const from = total * Math.max(0, fromFrac)
        const to = total * Math.min(1, toFrac)
        let acc = 0
        let path = ""

        for (const seg of segs) {
            if (seg.len <= 0)
                continue
            const segStart = acc
            const segEnd = acc + seg.len
            acc = segEnd

            if (segEnd <= from || segStart >= to)
                continue

            const a = Math.max(from, segStart)
            const b = Math.min(to, segEnd)
            const pa = root.pointAt(seg, a, segStart, rad)
            const pb = root.pointAt(seg, b, segStart, rad)

            if (path === "")
                path = `M${pa.x} ${pa.y}`

            path += seg.arc ? ` A${rad} ${rad} 0 0 1 ${pb.x} ${pb.y}` : ` L${pb.x} ${pb.y}`
        }

        return path
    }

    ShapePath {
        strokeWidth: Theme.batRingWidth
        strokeColor: Theme.batRingTrack
        fillColor: "transparent"
        capStyle: ShapePath.FlatCap

        PathSvg {
            path: root.trackPath
        }
    }

    ShapePath {
        strokeWidth: Theme.batRingWidth
        strokeColor: root.tone
        fillColor: "transparent"
        capStyle: ShapePath.FlatCap

        PathSvg {
            path: root.drawnPath
        }
    }
}

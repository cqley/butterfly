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
    readonly property real rad: Theme.inner(pillRadius, inset)
    readonly property real charge: Math.max(0, Math.min(1, pct))
    readonly property real perimeter: 2 * Math.max(0, width - 2 * rad)
        + 2 * Math.max(0, height - 2 * rad) + 2 * Math.PI * rad
    readonly property real lead: Math.max(0, width / 2 - rad)
    readonly property real dashes: Theme.batRingWidth > 0 ? perimeter / Theme.batRingWidth : 0

    width: Math.max(0, pillW - inset * 2)
    height: Math.max(0, pillH - inset * 2)
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: Theme.batRingWidth
        strokeColor: Theme.batRingTrack
        fillColor: "transparent"

        PathRectangle {
            width: root.width
            height: root.height
            radius: root.rad
        }
    }

    ShapePath {
        strokeWidth: root.charge > 0 ? Theme.batRingWidth : -1
        strokeColor: root.tone
        fillColor: "transparent"
        capStyle: ShapePath.FlatCap
        strokeStyle: ShapePath.DashLine
        dashOffset: -root.lead / Math.max(Theme.batRingWidth, 0.001)
        dashPattern: [Math.max(0.001, root.charge * root.dashes),
                      Math.max(0.001, (1 - root.charge) * root.dashes)]

        PathRectangle {
            width: root.width
            height: root.height
            radius: root.rad
        }
    }
}

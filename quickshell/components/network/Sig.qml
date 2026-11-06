import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property int level: 0
    property color tint: Theme.fg
    readonly property int grid: 20

    width: Theme.sigRowW
    height: Theme.sigRowH

    Repeater {
        model: Theme.sigBars

        Shape {
            id: bar
            required property int index
            readonly property int bh: Theme.sigH + bar.index * Theme.sigStep

            x: bar.index * (Theme.sigW + Theme.sigGap)
            y: root.height - bar.bh
            width: Theme.sigW
            height: bar.bh
            opacity: root.level > bar.index ? Theme.sigOn : Theme.sigOff
            transformOrigin: Item.TopLeft
            transform: Scale { xScale: 1 / root.grid; yScale: 1 / root.grid }
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: -1
                fillColor: root.tint

                PathSvg {
                    path: Theme.capsulePath(Theme.sigW * root.grid, bar.bh * root.grid)
                }
            }
        }
    }
}

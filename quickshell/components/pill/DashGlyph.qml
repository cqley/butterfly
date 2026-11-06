import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property int size: Theme.dashGlyph
    property color ink: Theme.accent
    property real wash: 1
    property bool fill: false
    property var paths: []
    property var strokePaths: []
    readonly property color tint: Theme.mix(Theme.bg, root.ink, root.wash)

    width: root.size
    height: root.size

    Behavior on ink {
        ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
    }

    Repeater {
        model: root.paths

        Shape {
            required property string modelData
            x: (root.size - Theme.iconGrid) / 2
            y: (root.size - Theme.iconGrid) / 2
            width: Theme.iconGrid
            height: Theme.iconGrid
            transformOrigin: Item.Center
            scale: root.size / Theme.iconGrid
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: root.fill ? -1 : Theme.glyphStroke(root.size)
                strokeColor: root.ink
                fillColor: root.fill ? root.ink : "transparent"
                fillRule: ShapePath.WindingFill
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                Behavior on strokeColor {
                    ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
                }

                PathSvg { path: modelData }
            }
        }
    }

    Repeater {
        model: root.strokePaths

        Shape {
            required property string modelData
            x: (root.size - Theme.iconGrid) / 2
            y: (root.size - Theme.iconGrid) / 2
            width: Theme.iconGrid
            height: Theme.iconGrid
            transformOrigin: Item.Center
            scale: root.size / Theme.iconGrid
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: Theme.glyphStroke(root.size)
                strokeColor: root.ink
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathSvg { path: modelData }
            }
        }
    }
}

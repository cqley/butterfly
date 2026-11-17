import "../core"
import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property real size: 0
    property bool mirror: false

    visible: root.size > 0
    width: root.size + 1
    height: root.size
    preferredRendererType: Shape.CurveRenderer
    transform: Scale { xScale: root.mirror ? -1 : 1; origin.x: root.width / 2 }

    ShapePath {
        fillColor: Theme.bg
        strokeColor: "transparent"
        startX: 0
        startY: 0
        PathLine { x: root.size + 1; y: 0 }
        PathLine { x: root.size + 1; y: root.size }
        PathLine { x: root.size; y: root.size }
        PathArc { x: 0; y: 0; radiusX: root.size; radiusY: root.size; direction: PathArc.Counterclockwise }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: Qt.rgba(1, 1, 1, Theme.pillBorderOpacity)
        strokeWidth: Theme.pillBorderWidth
        capStyle: ShapePath.FlatCap
        startX: root.size + 0.5
        startY: root.size
        PathArc { x: 0; y: -0.5; radiusX: root.size + 0.5; radiusY: root.size + 0.5; direction: PathArc.Counterclockwise }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: Qt.rgba(0, 0, 0, Theme.pillHaloOpacity * Math.min(1, root.size))
        strokeWidth: Theme.pillHaloWidth
        capStyle: ShapePath.FlatCap
        startX: root.size - 0.5
        startY: root.size
        PathArc { x: 0; y: 0.5; radiusX: Math.max(0.01, root.size - 0.5); radiusY: Math.max(0.01, root.size - 0.5); direction: PathArc.Counterclockwise }
    }
}

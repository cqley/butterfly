import "../core"
import QtQuick
import QtQuick.Shapes

Shape {
    width: Theme.lockW
    height: Theme.lockH
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: Theme.lockBorder
        strokeColor: Theme.fg
        fillColor: "transparent"
        capStyle: ShapePath.FlatCap
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: Theme.lockShacklePath }
    }

    ShapePath {
        strokeWidth: -1
        fillColor: Theme.fg
        fillRule: ShapePath.WindingFill
        PathSvg { path: Theme.lockBodyPath }
    }
}

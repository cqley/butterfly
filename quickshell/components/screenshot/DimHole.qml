import "../core"
import QtQuick

Item {
    id: root
    property real holeX: 0
    property real holeY: 0
    property real holeW: 0
    property real holeH: 0
    readonly property real r: Math.min(Theme.regionRadius, holeW / 2, holeH / 2)
    readonly property real clipX: Math.max(0, Math.min(width, holeX))
    readonly property real clipY: Math.max(0, Math.min(height, holeY))
    readonly property real clipR: Math.max(0, Math.min(width, holeX + holeW))
    readonly property real clipB: Math.max(0, Math.min(height, holeY + holeH))

    anchors.fill: parent

    Rectangle { x: 0; y: 0; width: root.width; height: root.clipY; color: Theme.bg; opacity: Theme.regionDim }
    Rectangle { x: 0; y: root.clipB; width: root.width; height: root.height - root.clipB; color: Theme.bg; opacity: Theme.regionDim }
    Rectangle { x: 0; y: root.clipY; width: root.clipX; height: root.clipB - root.clipY; color: Theme.bg; opacity: Theme.regionDim }
    Rectangle { x: root.clipR; y: root.clipY; width: root.width - root.clipR; height: root.clipB - root.clipY; color: Theme.bg; opacity: Theme.regionDim }

    Rectangle {
        x: root.holeX; y: root.holeY; width: root.r; height: root.r
        color: Theme.bg; opacity: Theme.regionDim
        bottomRightRadius: root.r
    }
    Rectangle {
        x: root.holeX + root.holeW - root.r; y: root.holeY; width: root.r; height: root.r
        color: Theme.bg; opacity: Theme.regionDim
        bottomLeftRadius: root.r
    }
    Rectangle {
        x: root.holeX; y: root.holeY + root.holeH - root.r; width: root.r; height: root.r
        color: Theme.bg; opacity: Theme.regionDim
        topRightRadius: root.r
    }
    Rectangle {
        x: root.holeX + root.holeW - root.r; y: root.holeY + root.holeH - root.r; width: root.r; height: root.r
        color: Theme.bg; opacity: Theme.regionDim
        topLeftRadius: root.r
    }

    Rectangle {
        x: root.holeX; y: root.holeY; width: root.holeW; height: root.holeH
        radius: root.r
        color: "transparent"
        border.width: Theme.regionBorderWidth
        border.color: Theme.accent
        antialiasing: true
    }
}

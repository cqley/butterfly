import "../core"
import "../network"
import "../status"
import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets

ClippingRectangle {
    id: root
    property string picture: ""
    property string mark: ""
    property string letter: "?"
    property string kind: ""
    property bool critical: false
    property bool on: false
    property real level: -1
    readonly property bool battery: root.kind === "battery"
    readonly property bool net: root.kind === "net"
    readonly property bool bluetooth: root.kind === "bluetooth"
    readonly property bool dnd: root.kind === "dnd"
    readonly property bool shot: root.kind === "shot"
    readonly property bool own: root.battery || root.net || root.bluetooth || root.dnd || root.shot
    property string source: ""

    function refresh() {
        source = picture || mark
        if (img.failed)
            img.reload()
    }

    onPictureChanged: refresh()
    onMarkChanged: refresh()
    Component.onCompleted: refresh()

    width: Theme.noteIcon
    height: Theme.noteIcon
    radius: Theme.noteIconR
    color: root.critical ? Theme.red
        : root.dnd ? (root.on ? Theme.dndTone : Theme.chip)
        : root.on && (root.net || root.bluetooth) ? Theme.green
        : Theme.chip

    StableImage {
        id: img
        anchors.fill: parent
        source: root.source
        retries: 2
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(Theme.noteIcon * 2, Theme.noteIcon * 2)
        onFailedChanged: {
            if (failed && root.source === root.picture && root.mark !== "" && root.mark !== root.picture)
                root.source = root.mark
        }
    }

    BatteryIcon {
        anchors.centerIn: parent
        visible: root.battery
        shown: root.battery
        available: true
        pct: root.level >= 0 ? root.level : 1
        tone: Theme.batTone(root.level >= 0 ? root.level : 1, root.on)
        pluggedIn: root.on
        leadingGap: 0
        scale: Theme.noteBatScale
    }

    Sig {
        anchors.centerIn: parent
        visible: root.net
        level: root.on ? Theme.sigBars : 0
        scale: Theme.noteSigScale
    }

    Shape {
        anchors.centerIn: parent
        width: Theme.iconGrid
        height: Theme.iconGrid
        scale: Theme.noteBtGlyph / Theme.iconGrid
        visible: root.bluetooth
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: Theme.iconStroke
            strokeColor: Theme.fg
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M7 7L17 17L12 22L12 2L17 7L7 17" }
        }
    }

    Shape {
        anchors.centerIn: parent
        width: Theme.iconGrid
        height: Theme.iconGrid
        scale: Theme.noteMoonGlyph / Theme.iconGrid
        visible: root.dnd
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: Theme.dndGlyph
            fillRule: ShapePath.WindingFill
            PathSvg { path: Theme.moonPath }
        }
    }

    Shape {
        anchors.centerIn: parent
        width: Theme.iconGrid
        height: Theme.iconGrid
        scale: Theme.noteShotGlyph / Theme.iconGrid
        visible: root.shot
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: Theme.fg
            fillRule: ShapePath.WindingFill
            PathSvg { path: Theme.shotBodyPath }
        }

        ShapePath {
            strokeWidth: -1
            fillColor: root.color
            fillRule: ShapePath.WindingFill
            PathSvg { path: Theme.shotLensPath }
        }
    }

    Txt {
        anchors.centerIn: parent
        text: root.letter
        visible: !root.own && img.showPlaceholder && !img.loading
        font.pixelSize: Theme.fsM
        font.weight: Font.Bold
    }
}

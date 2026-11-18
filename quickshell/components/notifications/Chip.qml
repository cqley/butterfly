import "../core"
import "../network"
import "../battery"
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
    property bool linked: false
    property real level: -1
    readonly property bool battery: root.kind === "battery"
    readonly property bool net: root.kind === "net"
    readonly property bool bluetooth: root.kind === "bluetooth"
    readonly property bool dnd: root.kind === "dnd"
    readonly property bool shot: root.kind === "shot"
    readonly property bool rec: root.kind === "rec"
    readonly property bool own: root.battery || root.net || root.bluetooth || root.dnd || root.shot || root.rec
    readonly property bool toned: root.critical || root.on && (root.net || root.bluetooth || root.dnd)
    readonly property color ink: root.toned ? Theme.white : Theme.fg
    property string source: ""

    function refresh() {
        const next = picture || mark
        const same = next === root.source
        source = next
        if (same && img.failed)
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
        anchors.horizontalCenterOffset: Theme.noteBatNudge
        visible: root.battery
        pct: root.level >= 0 ? root.level : 1
        tone: root.toned ? root.ink : Theme.batTone(root.level >= 0 ? root.level : 1)
        pluggedIn: root.on
        scale: Theme.noteBatScale
    }

    Sig {
        anchors.centerIn: parent
        visible: root.net
        level: root.on ? Theme.sigBars : 0
        tint: root.ink
        off: Theme.noteSigOff
        scale: Theme.noteSigScale
    }

    Shape {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: Theme.noteBtNudge
        width: Theme.iconGrid
        height: Theme.iconGrid
        scale: Theme.noteBtGlyph / Theme.iconGrid
        visible: root.bluetooth
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: Theme.iconStroke
            strokeColor: root.ink
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.linked ? Theme.btGlyphPath + Theme.btLinkPath : Theme.btGlyphPath }
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
        anchors.verticalCenterOffset: Theme.noteShotNudge
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

    Shape {
        anchors.centerIn: parent
        width: Theme.iconGrid
        height: Theme.iconGrid
        scale: Theme.noteRecGlyph / Theme.iconGrid
        visible: root.rec
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: root.critical ? Theme.white : Theme.red
            fillRule: ShapePath.WindingFill
            PathSvg { path: Theme.recDotPath }
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

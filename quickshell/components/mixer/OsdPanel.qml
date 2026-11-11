import "../core"
import "../audio"
import QtQuick
import QtQuick.Shapes

Fade {
    id: root
    readonly property bool volume: Osd.kind === "volume"
    readonly property real level: root.volume ? Audio.outLevel : Osd.bright
    readonly property bool muted: root.volume && Audio.outMuted
    readonly property int trackW: Theme.osdW - Theme.osdTrackX - Theme.osdPctGap - Theme.osdPctW - Theme.osdPadR
    readonly property int waveTier: !root.volume || root.muted || root.level <= 0 ? 0
        : root.level < Theme.audioWaveLowAt ? 1
        : root.level < Theme.audioWaveHighAt ? 2
        : 3
    readonly property color ink: root.muted ? Theme.mix(Theme.bg, Theme.fg, Theme.dimEmpty) : Theme.fg
    readonly property color fill: root.muted ? Theme.mixerMutedFill : root.volume ? Theme.accent : Theme.fg

    width: Theme.osdW
    height: Theme.osdH

    Spring {
        id: pos
        target: root.level * root.trackW
        hold: Theme.osdHold
    }

    Shape {
        x: root.volume ? Theme.osdIconX : Theme.osdSunX
        y: Math.round((root.height - Theme.osdIcon) / 2)
        width: Theme.iconGrid
        height: Theme.iconGrid
        scale: Theme.osdIcon / Theme.iconGrid
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: Theme.glyphStroke(Theme.osdIcon)
            strokeColor: root.ink
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: root.volume ? Theme.audioSpeakerPath : Theme.brightSunPath }
        }

        ShapePath {
            strokeWidth: root.waveTier >= 1 ? Theme.glyphStroke(Theme.osdIcon) : -1
            strokeColor: root.ink
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathSvg { path: Theme.audioWave1Path }
        }

        ShapePath {
            strokeWidth: root.waveTier >= 2 ? Theme.glyphStroke(Theme.osdIcon) : -1
            strokeColor: root.ink
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathSvg { path: Theme.audioWave2Path }
        }

        ShapePath {
            strokeWidth: root.waveTier >= 3 ? Theme.glyphStroke(Theme.osdIcon) : -1
            strokeColor: root.ink
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathSvg { path: Theme.audioWave3Path }
        }

        ShapePath {
            strokeWidth: root.muted ? Theme.glyphStroke(Theme.osdIcon, 2.2) : -1
            strokeColor: root.ink
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathSvg { path: Theme.audioSlashPath }
        }
    }

    Rectangle {
        id: track
        x: Theme.osdTrackX
        y: (root.height - height) / 2
        width: root.trackW
        height: Theme.osdTrackH
        radius: height / 2
        color: Theme.tile

        Rectangle {
            width: Math.max(height, pos.shaped)
            height: parent.height
            radius: height / 2
            visible: root.level > 0
            color: root.fill
        }
    }

    InkTxt {
        x: root.width - Theme.osdPadR - width
        width: Theme.osdPctW
        height: root.height
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.level * 100) + "%"
        color: root.ink
        font.pixelSize: Theme.fsXS
        font.features: Theme.tabular
    }
}

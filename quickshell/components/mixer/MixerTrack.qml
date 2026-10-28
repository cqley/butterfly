import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    required property real value
    required property bool ready
    required property string label
    property bool muted: false
    property bool focused: false
    property bool filled: true
    property bool meter: false
    property bool waves: false
    property bool toggles: false
    property real peak: 0
    property string path: ""
    property string path2: ""
    property string icon: ""
    property bool dragging: false
    readonly property real travel: Theme.mixerTrackH - Theme.mixerHandleH
    readonly property real base: Theme.mixerHandleH / 2
    readonly property real glow: meter ? Math.pow(root.peak, Theme.audioMeterGamma) * root.value : 0
    readonly property int waveTier: !waves || muted || !ready || value <= 0 ? 0
        : value < Theme.audioWaveLowAt ? 1
        : value < Theme.audioWaveHighAt ? 2
        : 3
    signal moved(real v)
    signal stepped(int d)
    signal picked
    signal toggled

    readonly property bool live: ready && !muted
    readonly property bool silent: ready && (muted || value <= 0)
    property real dim: live ? 1 : Theme.dimEmpty
    readonly property color ink: Theme.mix(Theme.bg, Theme.fg, root.dim)
    readonly property real shown: pos.value

    width: Theme.mixerColW
    height: col.height

    function valueAt(y) {
        if (root.travel <= 0)
            return 0
        return Math.max(0, Math.min(1, (Theme.mixerTrackH - root.base - y) / root.travel))
    }

    onValueChanged: if (root.dragging) pos.land(root.value)

    Behavior on dim {
        NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
    }

    Spring {
        id: pos
        target: root.value
        response: Theme.mixerResponse
        damping: Theme.mixerDamping
    }

    Column {
        id: col
        width: Theme.mixerColW
        spacing: Theme.mixerGap

        Item {
            id: track
            width: Theme.mixerColW
            height: Theme.mixerTrackH

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: Theme.mixerTrackW
                height: parent.height
                radius: width / 2
                color: Theme.chip
                opacity: root.dim
                antialiasing: true
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: Theme.mixerTrackW
                height: root.shown > 0 ? root.base + root.shown * root.travel : 0
                radius: width / 2
                color: root.muted ? Theme.mixerMutedFill : Theme.audioFill
                opacity: root.dim
                antialiasing: true

                Behavior on color {
                    ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
                }
            }

            Rectangle {
                visible: root.meter
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: Theme.mixerTrackW
                height: root.glow > 0 ? root.base + root.glow * root.travel : 0
                radius: width / 2
                color: Theme.accent
                antialiasing: true

                Behavior on height {
                    NumberAnimation { duration: Theme.audioMeterDecay }
                }
            }

            Rectangle {
                id: handle
                anchors.horizontalCenter: parent.horizontalCenter
                y: (1 - root.shown) * root.travel
                width: Theme.mixerHandleW
                height: Theme.mixerHandleH
                radius: height / 2
                color: Theme.fg
                opacity: root.silent ? Theme.mixerZeroDim : root.live ? 1 : Theme.mixerKnobDim
                antialiasing: true

                Behavior on opacity {
                    NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.ready
                cursorShape: Qt.PointingHandCursor
                onPressed: m => {
                    root.picked()
                    root.dragging = true
                    pos.land(root.valueAt(m.y))
                    root.moved(root.valueAt(m.y))
                }
                onPositionChanged: m => {
                    if (!pressed)
                        return
                    pos.land(root.valueAt(m.y))
                    root.moved(root.valueAt(m.y))
                }
                onReleased: root.dragging = false
                onCanceled: root.dragging = false
            }
        }

        Txt {
            width: parent.width
            height: Theme.mixerPctH
            visible: Theme.mixerPct
            horizontalAlignment: Text.AlignHCenter
            text: !root.ready ? "--" : root.muted ? "off" : Math.round(root.value * 100) + "%"
            color: root.focused ? Theme.accent : Theme.fg
            opacity: root.silent ? Theme.dimMuted : root.dim
            font.pixelSize: Theme.fsS
            font.features: Theme.tabular

            Behavior on color {
                ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
            }

            Behavior on opacity {
                NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
            }
        }

        Item {
            id: iconBox
            width: parent.width
            height: Theme.mixerIconBox

            StableImage {
                anchors.centerIn: parent
                width: Theme.mixerAppIcon
                height: Theme.mixerAppIcon
                visible: root.icon !== ""
                source: root.icon
                opacity: root.dim
                sourceSize: Qt.size(Theme.mixerAppIcon * 2, Theme.mixerAppIcon * 2)
            }

            Shape {
                x: Math.round((iconBox.width - Theme.mixerIcon) / 2)
                y: Math.round((iconBox.height - Theme.mixerIcon) / 2)
                width: Theme.iconGrid
                height: Theme.iconGrid
                scale: Theme.mixerIcon / Theme.iconGrid
                visible: root.icon === ""
                transformOrigin: Item.TopLeft
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: root.filled ? -1 : Theme.glyphStroke(Theme.mixerIcon)
                    strokeColor: root.ink
                    fillColor: root.filled ? root.ink : "transparent"
                    fillRule: ShapePath.WindingFill
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathSvg { path: root.path }
                }

                ShapePath {
                    strokeWidth: root.path2 !== "" ? Theme.audioIconStroke : -1
                    strokeColor: root.ink
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathSvg { path: root.path2 }
                }

                ShapePath {
                    strokeWidth: root.waveTier >= 1 ? Theme.audioIconStroke : -1
                    strokeColor: root.ink
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathSvg { path: Theme.audioWave1Path }
                }

                ShapePath {
                    strokeWidth: root.waveTier >= 2 ? Theme.audioIconStroke : -1
                    strokeColor: root.ink
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathSvg { path: Theme.audioWave2Path }
                }

                ShapePath {
                    strokeWidth: root.waveTier >= 3 ? Theme.audioIconStroke : -1
                    strokeColor: root.ink
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathSvg { path: Theme.audioWave3Path }
                }

                ShapePath {
                    strokeWidth: root.muted ? Theme.audioSlashStroke : -1
                    strokeColor: root.filled ? Theme.bg : root.ink
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathSvg { path: Theme.audioSlashPath }
                }
            }

            Shape {
                anchors.centerIn: parent
                width: Theme.iconGrid
                height: Theme.iconGrid
                scale: Theme.mixerIcon / Theme.iconGrid
                visible: root.icon !== "" && root.muted
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: Theme.audioSlashStroke
                    strokeColor: Theme.fg
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathSvg { path: Theme.audioSlashPath }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.ready && root.toggles
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.picked()
                    root.toggled()
                }
            }
        }

        Txt {
            width: parent.width
            height: Theme.mixerLabelH
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.label
            color: Theme.fg
            opacity: Theme.dimMuted * root.dim
            font.pixelSize: Theme.fsXXS
        }
    }

    Wheel {
        anchors.fill: parent
        enabled: root.ready
        onStep: n => root.stepped(-n * Theme.mixerStep)
    }
}

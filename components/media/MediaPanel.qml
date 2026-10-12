import "../core"
import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets

Fade {
    id: root
    readonly property var p: Media.player
    readonly property bool on: p !== null && p.isPlaying
    readonly property real len: p && p.lengthSupported ? p.length : 0
    readonly property real pos: p && p.positionSupported ? p.position : 0
    readonly property real frac: len > 0 ? Math.max(0, Math.min(1, (scrubbing ? scrub : pos) / len)) : 0
    property bool scrubbing: false
    property real scrub: 0

    onPChanged: {
        scrubbing = false
        scrub = 0
    }

    onVisibleChanged: if (!visible) {
        scrubbing = false
        scrub = 0
    }

    width: Theme.mediaW
    height: col.height

    function seekTo(x, w) {
        if (!root.p || !root.p.canSeek || !root.p.positionSupported || root.len <= 0) return
        const f = Math.max(0, Math.min(1, x / w))
        root.p.position = f * root.len
    }

    FrameAnimation {
        running: root.visible && root.on && !root.scrubbing
        onTriggered: if (root.p && root.p.positionSupported) root.p.positionChanged()
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.mediaColGap

        Item {
            width: parent.width
            height: Theme.artS

            ClippingRectangle {
                id: art
                width: Theme.artS
                height: Theme.artS
                radius: Theme.artR
                color: Theme.chip

                StableImage {
                    id: img
                    anchors.fill: parent
                    source: root.p ? root.p.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(Theme.artS * 2, Theme.artS * 2)
                }

                Shape {
                    x: Math.round((art.width - width) / 2)
                    y: Math.round((art.height - height) / 2)
                    width: Theme.iconGrid
                    height: Theme.iconGrid
                    opacity: Theme.dimGhost
                    visible: img.showPlaceholder
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: Theme.iconStroke
                        strokeColor: Theme.fg
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathSvg { path: "M9 18V5L21 3V16M9 18A3 3 0 0 1 3 18A3 3 0 0 1 9 18ZM21 16A3 3 0 0 1 15 16A3 3 0 0 1 21 16Z" }
                    }
                }
            }

            Column {
                x: art.width + Theme.mediaGap
                width: parent.width - x - Theme.ctlS * 2 - Theme.playS - Theme.mediaGap * 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.mediaTextGap

                Txt {
                    width: parent.width
                    text: Media.title
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.pixelSize: Theme.fsL
                    font.weight: Font.DemiBold
                }

                Txt {
                    width: parent.width
                    text: root.p ? root.p.trackArtist : ""
                    visible: text !== ""
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    opacity: Theme.dimMuted
                    font.pixelSize: Theme.fsS
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.mediaCtlGap

                Btn {
                    anchors.verticalCenter: parent.verticalCenter
                    path: "M19 20L9 12L19 4L19 20ZM5 19L5 5"
                    enabled: root.p !== null && root.p.canGoPrevious
                    onClicked: root.p.previous()
                }

                Btn {
                    anchors.verticalCenter: parent.verticalCenter
                    solid: true
                    dx: root.on ? 0 : Theme.playNudge
                    path: root.on ? "M6 4H10V20H6ZM14 4H18V20H14Z" : "M5 3L19 12L5 21L5 3Z"
                    enabled: root.p !== null && root.p.canTogglePlaying
                    onClicked: root.p.togglePlaying()
                }

                Btn {
                    anchors.verticalCenter: parent.verticalCenter
                    path: "M5 4L15 12L5 20L5 4ZM19 5L19 19"
                    enabled: root.p !== null && root.p.canGoNext
                    onClicked: root.p.next()
                }
            }
        }

        Item {
            width: parent.width
            height: Theme.barH + Theme.barPad

            Rectangle {
                id: bar
                property bool hovered: seekArea.containsMouse
                y: Theme.barPad
                width: parent.width
                height: Theme.barH
                radius: height / 2
                color: Theme.tile
                antialiasing: true

                Rectangle {
                    width: parent.width * root.frac
                    height: parent.height
                    radius: height / 2
                    color: Theme.accent
                    antialiasing: true
                }

                Rectangle {
                    x: Math.max(0, Math.min(parent.width - width, parent.width * root.frac - width / 2))
                    y: Theme.knobY
                    width: Theme.knobS
                    height: Theme.knobS
                    radius: width / 2
                    color: Theme.accent
                    transformOrigin: Item.Center
                    scale: root.scrubbing ? Theme.knobScrub : bar.hovered ? 1 : 0
                    opacity: root.scrubbing || bar.hovered ? 1 : 0
                    antialiasing: true

                    Behavior on scale { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
                    Behavior on opacity { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
                }

                MouseArea {
                    id: seekArea
                    anchors.fill: parent
                    anchors.topMargin: -Theme.barHit
                    anchors.bottomMargin: -Theme.barHit
                    enabled: root.p !== null && root.p.canSeek && root.p.positionSupported && root.len > 0
                    cursorShape: Qt.PointingHandCursor
                    onPressed: m => {
                        root.scrubbing = true
                        root.scrub = Math.max(0, Math.min(1, m.x / width)) * root.len
                    }
                    onPositionChanged: m => {
                        if (!root.scrubbing) return
                        root.scrub = Math.max(0, Math.min(1, m.x / width)) * root.len
                    }
                    onReleased: m => {
                        root.seekTo(m.x, width)
                        root.scrubbing = false
                    }
                    onCanceled: root.scrubbing = false
                }
            }
        }
    }
}

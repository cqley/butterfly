import "../core"
import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets

Fade {
    id: root
    readonly property var p: Media.player
    readonly property real len: p && p.lengthSupported && p.length > 0 && p.length <= Theme.mediaLenCap ? p.length : 0
    readonly property real pos: p && p.positionSupported ? p.position : 0
    readonly property bool seekable: p !== null && p.canSeek && p.positionSupported && len > 0
    readonly property bool srcOn: p !== null && p.isPlaying
    readonly property string srcTitle: Media.title
    readonly property string srcArtist: p ? p.trackArtist || "" : ""
    readonly property string srcArt: Media.artUrl
    readonly property real srcFrac: len > 0 && !settle.running ? Math.max(0, Math.min(1, (scrubbing ? scrub : pos) / len)) : 0
    property bool on: false
    property string title: ""
    property string artist: ""
    property string artUrl: ""
    property real frac: 0
    property real dur: 0
    property bool scrubbing: false
    property real scrub: 0

    onLenChanged: hold()
    onSrcOnChanged: hold()
    onSrcTitleChanged: hold()
    onSrcArtistChanged: hold()
    onSrcArtChanged: hold()
    onSrcFracChanged: hold()

    onPChanged: {
        scrubbing = false
        scrub = 0
        hold()
    }

    onVisibleChanged: if (!visible) {
        scrubbing = false
        scrub = 0
    }

    Component.onCompleted: hold()

    width: Theme.mediaW
    height: Theme.artS

    function hold() {
        if (!p)
            return
        on = srcOn
        title = srcTitle
        artist = srcArtist
        artUrl = srcArt
        frac = srcFrac
        dur = len
    }

    function seekTo(x, w) {
        if (!root.seekable)
            return
        const f = Math.max(0, Math.min(1, x / w))
        root.p.position = f * root.len
    }

    function pad(n) {
        return n < 10 ? "0" + n : "" + n
    }

    function clock(t) {
        const n = Math.max(0, Math.floor(t))
        const s = n % 60
        const m = Math.floor(n / 60) % 60
        const h = Math.floor(n / 3600)
        if (h === 0)
            return pad(m) + ":" + pad(s)
        return h + ":" + pad(m) + ":" + pad(s)
    }

    Timer {
        id: settle
        interval: Theme.mediaTrackSettle
    }

    Connections {
        target: root.p
        function onTrackChanged() {
            root.scrubbing = false
            root.frac = 0
            settle.restart()
        }
    }

    FrameAnimation {
        running: root.visible && root.srcOn && !root.scrubbing
        onTriggered: if (root.p && root.p.positionSupported) root.p.positionChanged()
    }

    ClippingRectangle {
        id: art
        width: Theme.artS
        height: Theme.artS
        radius: Theme.artR
        color: Theme.chip
        transformOrigin: Item.Center
        scale: (root.on ? 1 : Theme.mediaPausedArt)
            * (artArea.pressed ? Theme.feedbackPressScale : artArea.containsMouse ? Theme.feedbackHoverScale : 1)

        Behavior on scale { NumberAnimation { duration: Theme.mediaArtDuration; easing.type: Theme.ease } }

        StableImage {
            id: img
            anchors.fill: parent
            source: root.artUrl
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(Theme.artS * 2, Theme.artS * 2)
        }

        Shape {
            x: Math.round((art.width - width) / 2)
            y: Math.round((art.height - height) / 2)
            width: Theme.iconGrid
            height: Theme.iconGrid
            scale: Theme.artGlyph / Theme.iconGrid
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

    Rectangle {
        width: art.width
        height: art.height
        radius: art.radius
        scale: art.scale
        transformOrigin: Item.Center
        color: "transparent"
        border.width: Theme.surfaceBorderWidth
        border.color: artArea.containsMouse ? Theme.mediaArtBorderHover : Theme.surfaceBorder
        antialiasing: true

        Behavior on border.color { ColorAnimation { duration: Theme.feedbackDuration } }
    }

    MouseArea {
        id: artArea
        width: art.width
        height: art.height
        enabled: root.p !== null && root.p.canRaise
        hoverEnabled: true
        onClicked: root.p.raise()
    }

    Item {
        id: side
        x: Theme.artS + Theme.mediaGap
        width: Theme.mediaW - x
        height: Theme.artS

        Column {
            id: head
            width: parent.width
            spacing: Theme.mediaTextGap

            Item {
                id: titleBox
                readonly property real over: Math.max(0, Math.floor(metrics.width - width))
                readonly property bool rolling: Theme.mediaScroll && over > 0
                readonly property int travel: Math.max(Theme.fast, Math.round(over / Theme.mediaScrollSpeed * 1000))
                property real roll: 0

                width: parent.width
                height: Theme.mediaTitleH
                clip: rolling

                TextMetrics {
                    id: metrics
                    font: label.font
                    text: root.title
                }

                Txt {
                    id: label
                    x: titleBox.rolling ? -titleBox.over * titleBox.roll : 0
                    width: parent.width
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: root.title
                    elide: titleBox.rolling ? Text.ElideNone : Text.ElideRight
                    maximumLineCount: 1
                    font.pixelSize: Theme.fsL
                    font.weight: Font.DemiBold
                }

                SequentialAnimation {
                    running: titleBox.rolling && root.visible
                    loops: Animation.Infinite

                    PauseAnimation { duration: Theme.mediaScrollHold }

                    NumberAnimation {
                        target: titleBox
                        property: "roll"
                        from: 0
                        to: 1
                        duration: titleBox.travel
                    }

                    PauseAnimation { duration: Theme.mediaScrollHold }

                    NumberAnimation {
                        target: titleBox
                        property: "roll"
                        from: 1
                        to: 0
                        duration: titleBox.travel
                    }
                }
            }

            Txt {
                width: parent.width
                height: Theme.mediaArtistH
                verticalAlignment: Text.AlignVCenter
                text: root.artist
                visible: text !== ""
                elide: Text.ElideRight
                maximumLineCount: 1
                opacity: Theme.dimMuted
                font.pixelSize: Theme.fsS
            }
        }

        Row {
            id: ctls
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round((Theme.mediaTitleH + Theme.mediaTextGap + Theme.mediaArtistH + bar.y - height) / 2)
            spacing: Theme.mediaCtlGap

            Btn {
                dir: -1
                path: "M22 5L11.25 12L22 19Z M12.75 5L2 12L12.75 19Z"
                player: root.p
                can: root.p !== null && root.p.canGoPrevious
                onClicked: if (root.p.canGoPrevious) root.p.previous()
            }

            Btn {
                primary: true
                dx: root.on ? 0 : Theme.playNudge
                path: root.on ? "M6 5.5H8.5V18.5H6Z M15.5 5.5H18V18.5H15.5Z" : "M7.5 5L20.5 12L7.5 19Z"
                player: root.p
                can: root.p !== null && root.p.canTogglePlaying
                onClicked: if (root.p.canTogglePlaying) root.p.togglePlaying()
            }

            Btn {
                dir: 1
                path: "M2 5L12.75 12L2 19Z M11.25 5L22 12L11.25 19Z"
                player: root.p
                can: root.p !== null && root.p.canGoNext
                onClicked: if (root.p.canGoNext) root.p.next()
            }
        }

        Rectangle {
            id: bar
            y: parent.height - height - (Theme.mediaTimes ? Theme.mediaTimeGap + Theme.mediaTimeH : 0)
            width: parent.width
            height: Theme.barH
            radius: height / 2
            color: Theme.mediaTrack
            antialiasing: true

            Rectangle {
                width: parent.width * root.frac
                height: parent.height
                radius: Math.min(height / 2, width / 2)
                color: Theme.accent
                antialiasing: true
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -Theme.barHit
                anchors.bottomMargin: -Theme.barHit
                enabled: root.seekable
                cursorShape: Qt.PointingHandCursor
                onPressed: m => {
                    root.scrubbing = true
                    root.scrub = Math.max(0, Math.min(1, m.x / width)) * root.len
                }
                onPositionChanged: m => {
                    if (!root.scrubbing)
                        return
                    root.scrub = Math.max(0, Math.min(1, m.x / width)) * root.len
                }
                onReleased: m => {
                    root.seekTo(m.x, width)
                    root.scrubbing = false
                }
                onCanceled: root.scrubbing = false
            }
        }

        Txt {
            y: parent.height - Theme.mediaTimeH
            height: Theme.mediaTimeH
            verticalAlignment: Text.AlignVCenter
            visible: Theme.mediaTimes
            font.pixelSize: Theme.fsXS
            opacity: root.dur > 0 ? Theme.dimMuted : 0
            text: root.clock(root.frac * root.dur)
        }

        Txt {
            anchors.right: parent.right
            y: parent.height - Theme.mediaTimeH
            height: Theme.mediaTimeH
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            visible: Theme.mediaTimes
            font.pixelSize: Theme.fsXS
            opacity: root.dur > 0 ? Theme.dimHint : 0
            text: Theme.mediaRemainChar + root.clock(root.dur - root.frac * root.dur)
        }
    }
}

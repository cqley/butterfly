import "../core"
import QtQuick

Row {
    id: root
    property bool playing: false
    property string artUrl: ""
    property real phase: 0
    property var smoothed: []
    height: Theme.h
    spacing: Theme.visGap

    function target(index) {
        return Visualizer.real
            ? (Visualizer.levels[index] || 0)
            : (0.5 + 0.5 * Math.sin(root.phase * (1 + index * Theme.visFreqStep) + index * Theme.visOffset))
    }

    ArtColors {
        id: art
        source: root.artUrl
    }

    FrameAnimation {
        running: root.playing
        onTriggered: {
            if (!Visualizer.real)
                root.phase += frameTime * (2 * Math.PI * 1000 / Theme.visCycle)
            const next = []
            for (let i = 0; i < Theme.visBars; i++) {
                const t = root.target(i)
                const prev = root.smoothed[i] || 0
                next.push(Visualizer.real ? prev + (t - prev) * Theme.visLerp : t)
            }
            root.smoothed = next
        }
    }

    Repeater {
        model: Theme.visBars

        Rectangle {
            id: bar
            required property int index
            property real live: Theme.visMinH + (Theme.visMaxH - Theme.visMinH) * (root.smoothed[index] || 0)
            property real fallback: Theme.visIdleH

            anchors.verticalCenter: parent.verticalCenter
            width: Theme.visBarW
            radius: width / 2
            color: Theme.mix(art.a, art.b, Theme.visBars > 1 ? index / (Theme.visBars - 1) : 0)
            antialiasing: true
            height: Math.round(root.playing ? live : fallback)

            Behavior on fallback {
                NumberAnimation {
                    duration: Theme.visSettle
                    easing.type: Theme.ease
                }
            }

            Connections {
                target: root
                function onPlayingChanged() {
                    if (!root.playing) {
                        bar.fallback = bar.live
                        Qt.callLater(() => bar.fallback = Theme.visIdleH)
                    }
                }
            }
        }
    }
}

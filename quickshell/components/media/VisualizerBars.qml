import "../core"
import QtQuick

Item {
    id: root
    property bool playing: false
    property bool shown: true
    property string artUrl: ""
    property real phase: 0
    property var smoothed: []
    readonly property int pitch: Theme.visBarW + Theme.visGap
    readonly property real reach: countMotion.shaped
    readonly property int restWidth: Theme.visBars * root.pitch - Theme.visGap
    width: Math.max(0, Math.ceil(root.reach * root.pitch - Theme.visGap))
    height: Theme.h

    Spring {
        id: countMotion
        target: Theme.visBars
        snap: !root.shown
        response: Theme.idlePopResponse
        damping: Theme.idlePopDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
        hold: Theme.springHold
        settle: Theme.springSettle
    }

    onPlayingChanged: if (!playing) {
        for (let i = 0; i < bars.count; i++)
            bars.itemAt(i).fallback = bars.itemAt(i).live
        Qt.callLater(() => {
            for (let i = 0; i < bars.count; i++)
                bars.itemAt(i).fallback = Theme.visIdleH
        })
    }

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
        running: root.playing && root.shown
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
        id: bars
        model: Theme.visBarsMax

        Rectangle {
            id: bar
            required property int index
            readonly property real presence: Math.max(0, Math.min(1, root.reach - index))
            property real live: Theme.visMinH + (Theme.visMaxH - Theme.visMinH) * (root.smoothed[index] || 0)
            property real fallback: Theme.visIdleH

            x: index * root.pitch
            anchors.verticalCenter: parent.verticalCenter
            visible: presence > 0
            opacity: presence
            width: Theme.visBarW
            radius: width / 2
            color: Theme.mix(art.a, art.b, root.reach > 1 ? Math.min(1, index / (root.reach - 1)) : 0)
            antialiasing: true
            height: Math.round(root.playing ? live : fallback)

            Behavior on fallback {
                NumberAnimation {
                    duration: Theme.visSettle
                    easing.type: Theme.ease
                }
            }
        }
    }
}

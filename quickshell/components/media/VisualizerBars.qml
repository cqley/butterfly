import "../core"
import QtQuick

Row {
    id: root
    property bool playing: false
    property string artUrl: ""
    property real phase: 0
    height: Theme.h
    spacing: Theme.visGap

    ArtColors {
        id: art
        source: root.artUrl
    }

    FrameAnimation {
        running: root.playing
        onTriggered: root.phase += frameTime * (2 * Math.PI * 1000 / Theme.visCycle)
    }

    Repeater {
        model: Theme.visBars

        Rectangle {
            required property int index
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.visBarW
            radius: width / 2
            color: Theme.mix(art.a, art.b, Theme.visBars > 1 ? index / (Theme.visBars - 1) : 0)
            antialiasing: true
            height: Math.round(root.playing
                ? Theme.visMinH + (Theme.visMaxH - Theme.visMinH) * (0.5 + 0.5 * Math.sin(root.phase * (1 + index * Theme.visFreqStep) + index * Theme.visOffset))
                : Theme.visIdleH)

            Behavior on height {
                NumberAnimation {
                    duration: root.playing ? 0 : Theme.visSettle
                    easing.type: Theme.ease
                }
            }
        }
    }
}

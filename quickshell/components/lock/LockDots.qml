import "../core"
import QtQuick

Item {
    id: root
    property int count: Locker.count
    property bool instant: false
    readonly property int n: Math.min(root.count, Theme.lockerDotsMax)
    readonly property real step: Theme.lockerDot + Theme.lockerDotGap
    readonly property int held: root.n > 0 ? root.n : root.lit
    readonly property real want: root.held > 0 ? root.held * root.step - Theme.lockerDotGap : 0
    readonly property real span: spanMotion.value
    property real beat: 0
    property int lit: 0
    property real throb: Locker.pulsing ? 1 : 0

    function follow(o) {
        root.lift(spanMotion, o.spanSpring)
        for (let i = 0; i < Theme.lockerDotsMax; i++)
            root.lift(dots.itemAt(i).spring, o.dotSpring(i))
    }

    function lift(a, b) {
        a.land(b.shaped)
        if (b.moving)
            a.kick(b.velocity)
    }

    function dotSpring(i) {
        return dots.itemAt(i).spring
    }

    readonly property alias spanSpring: spanMotion

    width: root.span
    height: Theme.lockerDot

    Behavior on throb {
        NumberAnimation { duration: Theme.speed; easing.type: Theme.ease }
    }

    Spring {
        id: spanMotion
        target: root.want
        response: Theme.islandResponse
        damping: Theme.islandDamping
        epsilon: Theme.settleEps
    }

    onInstantChanged: if (root.instant) spanMotion.land(spanMotion.target)

    NumberAnimation on beat {
        running: root.throb > 0
        loops: Animation.Infinite
        from: 0
        to: 2 * Math.PI
        duration: Theme.lockerBusyPulse
    }

    Repeater {
        id: dots
        model: Theme.lockerDotsMax

        Rectangle {
            id: dot
            required property int index
            readonly property bool on: dot.index < root.n
            readonly property alias spring: pop

            x: dot.index * root.step
            width: Theme.lockerDot
            height: Theme.lockerDot
            radius: width / 2
            antialiasing: true
            readonly property bool live: pop.shaped > Theme.lockerDotGone
            visible: pop.value > 0.001
            onLiveChanged: root.lit += dot.live ? 1 : -1
            color: Locker.red ? Theme.red : Theme.clockInk
            opacity: Math.min(1, 2 * pop.value) * (1 - root.throb * (1 - Theme.dimMid) * (0.5 - 0.5 * Math.cos(root.beat - dot.index * Theme.lockerBusyLag)))
            scale: Theme.lockerDotFrom + (1 - Theme.lockerDotFrom) * pop.value

            Behavior on color { ColorAnimation { duration: Theme.fall } }

            ScaleSpring {
                id: pop
                size: Theme.lockerDot
                target: dot.on ? 1 : 0
                damping: Theme.lockerDotDamping
            }

            Connections {
                target: root
                function onInstantChanged() {
                    if (root.instant)
                        pop.land(pop.target)
                }
            }
        }
    }
}

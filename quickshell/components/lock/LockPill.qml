import "../core"
import "../pill"
import QtQuick
import Quickshell.Widgets

Item {
    id: root
    readonly property real want: Math.max(Theme.lockerPillW, dots.need + 2 * Theme.pad)
    readonly property bool glyphOn: Locker.glyph && dots.lit === 0
    readonly property real topY: Theme.notch ? 0 : Theme.gap
    readonly property real wAnim: wMotion.shaped
    readonly property real bodyR: Math.min(Math.min(body.width, body.height) / 2, Theme.radius)
    readonly property real rho: Theme.notch ? -Theme.notchEar : root.bodyR
    readonly property real ear: Math.max(0, -root.rho)
    readonly property real topRadius: Math.max(0, root.rho)
    readonly property real cornerFrac: root.bodyR > 0 ? root.topRadius / root.bodyR : (Theme.notch ? 0 : 1)

    anchors.fill: parent

    property bool followed: false

    Connections {
        target: root.Window.window
        enabled: !root.followed
        function onAfterAnimating() {
            root.followed = true
            root.follow()
        }
    }

    function follow() {
        const twin = Locker.twin
        if (!twin || !Locker.staging && !Locker.preview)
            return
        wMotion.land(twin.wAnim)
        if (twin.wSpring.moving)
            wMotion.kick(twin.wSpring.velocity)
        dots.follow(twin.dotsTwin)
        glyph.follow(twin.glyphTwin)
    }

    Spring {
        id: wMotion
        target: root.want
        hold: Theme.springHold
        response: Theme.islandResponse
        damping: Theme.islandDamping
        epsilon: Theme.settleEps
    }

    Binding {
        target: Locker
        property: "stageSettled"
        value: Math.abs(wMotion.shaped - wMotion.target) < Theme.settleEps && glyph.shown === root.glyphOn && glyph.settled && dots.lit === 0
    }

    Spring {
        id: shake
        target: 0
        response: Theme.lockerShakeResponse
        damping: Theme.lockerShakeDamping
        epsilon: 0.05
        rest: 1
    }

    Connections {
        target: Locker
        function onFailsChanged() { shake.kick(Theme.lockerShakeKick) }
    }

    transform: Translate { x: shake.value }

    Item {
        id: skin
        x: (root.width - width) / 2
        y: root.topY
        width: root.wAnim
        height: Theme.h
    }

    Shadow {
        anchors.fill: skin
        radius: body.radius
    }

    Rectangle {
        anchors.fill: skin
        radius: body.radius
        topLeftRadius: root.topRadius
        topRightRadius: root.topRadius
        color: Theme.bg
        antialiasing: true
    }

    NotchEar {
        x: skin.x - root.ear
        y: skin.y
        z: 6
        size: root.ear
    }

    NotchEar {
        x: skin.x + skin.width - 1
        y: skin.y
        z: 6
        size: root.ear
        mirror: true
    }

    ClippingRectangle {
        id: body
        x: Theme.mid(root.width, width)
        y: Math.round(root.topY)
        width: Math.round(root.wAnim)
        height: Theme.h
        radius: root.bodyR
        topLeftRadius: root.topRadius
        topRightRadius: root.topRadius
        antialiasing: true
        color: "transparent"

        LockDots {
            id: dots
            count: Locker.count
            room: body.width - 2 * Theme.pad
            x: (body.width - width) / 2
            y: Theme.mid(body.height, height)
        }
    }

    LockGlyph {
        id: glyph
        x: Theme.mid(root.width, width)
        y: Math.round(root.topY) + Theme.mid(Theme.h, height)
        z: 4
        shown: root.glyphOn
        open: Locker.opened
    }

    Rectangle {
        anchors.fill: skin
        anchors.topMargin: -Theme.pillBorderWidth * (1 - root.cornerFrac)
        radius: body.radius
        topLeftRadius: root.topRadius
        topRightRadius: root.topRadius
        color: "transparent"
        border.width: Theme.pillBorderWidth
        border.color: Qt.rgba(1, 1, 1, Theme.pillBorderOpacity)
        antialiasing: true
        z: 3
    }

    Item {
        readonly property real cut: root.ear > 0 ? root.ear : -Theme.pillHaloSpread
        x: skin.x - Theme.pillHaloSpread
        y: skin.y + cut
        width: skin.width + 2 * Theme.pillHaloSpread
        height: skin.height + Theme.pillHaloSpread - cut
        clip: cut > 0
        z: 5

        Rectangle {
            y: -parent.cut - Theme.pillHaloSpread
            width: parent.width
            height: skin.height + 2 * Theme.pillHaloSpread
            radius: body.radius + Theme.corner(Theme.pillHaloSpread)
            topLeftRadius: radius * root.cornerFrac
            topRightRadius: radius * root.cornerFrac
            color: "transparent"
            border.width: Theme.pillHaloWidth
            border.color: Qt.rgba(0, 0, 0, Theme.pillHaloOpacity)
            antialiasing: true
        }
    }
}

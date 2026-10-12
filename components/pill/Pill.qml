import QtQuick
import Quickshell
import Quickshell.Widgets
import "../audio"
import "../calendar"
import "../core"
import "../launcher"
import "../media"
import "../network"
import "../notifications"
import "../polkit"
import "../power"
import "../recording"
import "../status"
import "../wallpaper"

Item {
    id: root
    property bool full: false
    readonly property bool hot: hover.hovered
    readonly property bool modal: Modal.any
    readonly property bool alert: Notifs.current !== null && !modal
    readonly property bool calm: !alert && !modal
    readonly property bool resizing:
        Math.abs(root.wAnim - root.targetW) > Theme.settleEps ||
        Math.abs(root.hAnim - root.targetH) > Theme.settleEps
    property bool media: false
    property real wAnim: Theme.w
    property real hAnim: Theme.h

    onModalChanged: full = false
    onAlertChanged: if (!alert) full = false
    onHotChanged: sync()
    Component.onCompleted: {
        sync()
        Modal.register("launcher", Launcher)
        Modal.register("power", Power)
        Modal.register("wallpaper", Wallpaper)
        Modal.register("polkit", Polkit)
        Modal.register("record", Record)
        Modal.register("net", Net)
    }

    function sync() {
        media = Media.playing || (hot && media && Media.player !== null)
    }

    Connections {
        target: Media
        function onPlayingChanged() { root.sync() }
        function onPlayerChanged() { root.sync() }
    }

    anchors.fill: parent

    property alias hitTarget: body

    TapHandler {
        id: away
        enabled: root.modal
        onTapped: p => {
            const point = root.hitTarget.mapFromItem(root, p.position)
            if (root.hitTarget.contains(point))
                return
            if (Polkit.open)
                Polkit.cancel()
            Modal.close("")
        }
    }

    Binding {
        target: Notifs
        property: "hovered"
        value: root.hot || root.modal
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property real idleTargetW: Math.max(
        Theme.w,
        clockText.implicitWidth + battery.targetWidth + mic.targetWidth + record.targetWidth + Theme.pad
    )
    readonly property real targetW: Polkit.open ? Theme.authW
        : root.alert ? (root.hot ? Theme.noteOpenW : Theme.noteW)
        : Launcher.open ? Theme.launchW
        : Power.open ? Theme.powerW
        : Wallpaper.open ? Theme.wallW
        : Record.open ? Theme.recordW
        : Net.open ? Theme.netW
        : root.hot ? (root.media && !root.full ? Theme.mediaPillW : Theme.openW)
        : root.calm ? root.idleTargetW : Theme.w

    readonly property real targetH: Polkit.open ? auth.y + auth.height + Theme.authPad
        : root.alert ? (root.hot ? note.wanted : Theme.noteH)
        : Launcher.open ? launch.y + launch.height + Theme.lpad
        : Power.open ? power.y + power.height + Theme.pwPad
        : Wallpaper.open ? wall.y + wall.height + Theme.wallPad
        : Record.open ? rec.y + rec.height + Theme.recordPad
        : Net.open ? net.y + net.height + Theme.netPad
        : root.full ? cal.y + cal.height + Theme.pad
        : root.hot ? (root.media ? tune.y + tune.height + Theme.pad : Theme.openH)
        : Theme.h

    Binding {
        target: root
        property: "wAnim"
        value: root.targetW
    }

    Binding {
        target: root
        property: "hAnim"
        value: root.targetH
    }

    Behavior on wAnim {
        NumberAnimation {
            duration: Theme.speed
            easing.type: Theme.ease
        }
    }

    Behavior on hAnim {
        NumberAnimation {
            duration: Theme.speed
            easing.type: Theme.ease
        }
    }

    ClippingRectangle {
        id: body
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.gap
        width: root.wAnim
        height: root.hAnim
        radius: Math.min(Math.min(width, height) / 2, Theme.radius)
        antialiasing: true
        color: Theme.bg

        HoverHandler {
            id: hover
            onHoveredChanged: if (!hovered) root.full = false
        }

        TapHandler {
            onTapped: {
                if (root.alert)
                    Notifs.dismiss()
                else if (!root.modal && root.hot)
                    root.full = !root.full
            }
        }

        Week {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.body
            now: clock.date
            shown: root.hot && !root.full && root.calm && !root.media
            ready: !root.resizing
        }

        MediaPanel {
            id: tune
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.body
            shown: root.hot && !root.full && root.calm && root.media
            ready: !root.resizing
        }

        Calendar {
            id: cal
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.body
            now: clock.date
            shown: root.hot && root.full && root.calm
            ready: !root.resizing
        }

        Note {
            id: note
            n: Notifs.current
            expanded: root.hot
            shown: root.alert
            ready: !root.resizing
        }

        Launch {
            id: launch
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.lpad
            shown: Launcher.open
            ready: !root.resizing
        }

        PowerMenu {
            id: power
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.pwPad
            shown: Power.open
            ready: !root.resizing
        }

        Wall {
            id: wall
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.wallPad
            shown: Wallpaper.open
            ready: !root.resizing
        }

        RecordMenu {
            id: rec
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.recordPad
            shown: Record.open
            ready: !root.resizing
        }

        NetMenu {
            id: net
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.netPad
            shown: Net.open
            ready: !root.resizing
        }

        Auth {
            id: auth
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.authPad
            shown: Polkit.open
            ready: !root.resizing
        }
    }

    Fade {
        id: idle
        anchors.horizontalCenter: body.horizontalCenter
        anchors.top: body.top
        anchors.topMargin: Theme.idleTopOffsetY
        width: row.width
        height: Theme.h
        shown: root.calm
        z: 2

        transform: Translate {
            x: Theme.idleOffsetX
            y: Theme.idleOffsetY
        }

        Row {
            id: row
            width: clockText.implicitWidth + battery.width + mic.width + record.width
            height: parent.height
            spacing: 0

            Txt {
                id: clockText
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.clockOffsetY
                anchors.alignWhenCentered: Theme.idleAlignWhenCentered
                verticalAlignment: Text.AlignVCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                font.pixelSize: Theme.clockPx

                transform: Translate {
                    x: Theme.clockOffsetX
                }
            }

            BatteryIcon {
                id: battery
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.moduleOffsetY + Theme.batteryOffsetY
                anchors.alignWhenCentered: Theme.idleAlignWhenCentered
                shown: Battery.shown
                available: Battery.available
                pct: Battery.pct
                tone: Battery.tone
                pluggedIn: Battery.pluggedIn
                leadingGap: Theme.clockGap

                transform: Translate {
                    x: Theme.batteryOffsetX
                }
            }

            Slot {
                id: mic
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.moduleOffsetY + Theme.micOffsetY
                anchors.alignWhenCentered: Theme.idleAlignWhenCentered
                shown: Mic.muted
                leadingGap: battery.active ? Theme.rowGap : Theme.clockGap
                onClicked: Mic.toggle()

                transform: Translate {
                    x: Theme.micOffsetX
                }

                MicOff {}
            }

            Slot {
                id: record
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.moduleOffsetY + Theme.recordOffsetY
                anchors.alignWhenCentered: Theme.idleAlignWhenCentered
                size: Theme.recordDot
                shown: Record.active
                leadingGap: (battery.active || mic.shown) ? Theme.rowGap : Theme.clockGap
                onClicked: Record.stop()

                transform: Translate {
                    x: Theme.recordOffsetX
                }

                Rectangle {
                    property real pulse: 1
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.red
                    antialiasing: true
                    opacity: Theme.dotLow + (1 - Theme.dotLow) * pulse

                    SequentialAnimation on pulse {
                        running: Record.active
                        loops: Animation.Infinite

                        NumberAnimation {
                            from: 1
                            to: 0
                            duration: Theme.pulse
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            from: 0
                            to: 1
                            duration: Theme.pulse
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
        }
    }
}


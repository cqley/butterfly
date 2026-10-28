import QtQuick
import Quickshell
import Quickshell.Widgets
import "../audio"
import "../bluetooth"
import "../brightness"
import "../calendar"
import "../core"
import "../launcher"
import "../media"
import "../mixer"
import "../network"
import "../notifications"
import "../polkit"
import "../power"
import "../recording"
import "../screenshot"
import "../battery"
import "../wallpaper"

Item {
    id: root

    Timer {
        id: grow
        interval: root.panelRise
        onTriggered: Modal.flush()
    }

    Timer {
        id: hold
        interval: Theme.fall
    }

    Timer {
        id: wake
        interval: Theme.idleWait
    }

    Timer {
        id: ringSettle
        interval: Theme.speed
    }

    property bool full: false
    readonly property bool hot: hover.hovered
    readonly property bool modal: Modal.any
    readonly property bool alert: Notifs.current !== null && !modal
    readonly property bool calm: !alert && !modal
    readonly property bool popout: Theme.islandMode === "popout"
    readonly property bool calOpen: root.popout ? islandPop.calendarShown : root.full
    readonly property bool mediaHover: !root.popout && root.hot && !root.full && root.calm && root.media
    readonly property bool showVisualizer: Visualizer.on || root.mediaHover
    readonly property bool hideIdleIcons: root.mediaHover || root.calOpen
    readonly property bool ringGeometryBase: root.calm && !root.hot && !root.hideIdleIcons
    readonly property bool ringBase: root.ringGeometryBase && Theme.batRingEnabled && Battery.ringShown && Battery.available
    readonly property bool resizing:
        Math.abs(root.wAnim - root.targetW) > Theme.settleEps ||
        Math.abs(root.hAnim - root.targetH) > Theme.settleEps
    readonly property string face: Modal.any ? Modal.which : root.alert ? "note" : "idle"
    readonly property bool moving: hold.running || root.resizing
    readonly property bool panelReady: !root.moving
    readonly property int panelRise: root.swapped ? Theme.swapRise : Theme.rise
    property bool wasMenu: false
    property bool swapped: false
    property real holdW: Theme.w
    property real holdH: Theme.h
    property bool media: false
    property real wAnim: Theme.w
    property real hAnim: Theme.h

    onModalChanged: full = false
    onAlertChanged: if (!alert) full = false
    onHotChanged: sync()
    onFaceChanged: {
        swapped = root.wasMenu && Modal.any
        wasMenu = Modal.any
    }
    onPanelReadyChanged: if (Theme.blockSwap && root.panelReady && Modal.any) grow.restart()
    onCalmChanged: if (calm && Theme.idleWait > 0) wake.restart()
    onRingGeometryBaseChanged: ringSettle.restart()
    onWantWChanged: root.brake()
    onWantHChanged: root.brake()

    function brake() {
        if (!Theme.holdPill || hold.running || root.resizing)
            return
        if (root.wantW < root.wAnim - Theme.settleEps || root.wantH < root.hAnim - Theme.settleEps) {
            holdW = root.wAnim
            holdH = root.hAnim
            hold.restart()
        }
    }
    IslandPop {
        id: islandPop
        enabled: root.popout
    }

    Component.onCompleted: {
        sync()
        Modal.register("island", islandPop)
        Modal.register("launcher", Launcher)
        Modal.register("power", Power)
        Modal.register("wallpaper", Wallpaper)
        Modal.register("polkit", Polkit)
        Modal.register("record", Record)
        Modal.register("screenshot", Screenshot)
        Modal.register("net", Net)
        Modal.register("mixer", Mixer)
        Modal.register("brightness", Brightness)
        Modal.register("audio", Audio)
        Modal.register("bluetooth", Bt)
        Modal.register("notifs", Notifs)
    }

    function sync() {
        media = Media.playing || (hot && media && Media.player !== null)
    }

    Connections {
        target: Media
        function onPlayingChanged() { root.sync() }
        function onPlayerChanged() { root.sync() }
    }

    Binding {
        target: Modal
        property: "busy"
        value: grow.running
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
            Modal.dismiss()
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
        clockSlot.width + battery.targetWidth + mic.targetWidth + record.targetWidth + Theme.pad
    )

    readonly property real targetW: hold.running ? root.holdW : root.wantW
    readonly property real targetH: hold.running ? root.holdH : root.wantH

    readonly property var panelSizes: [
        { cond: () => Polkit.open, w: () => Theme.authW, h: () => auth.y + auth.height + Theme.authPad },
        { cond: () => root.alert, w: () => root.hot ? Theme.noteOpenW : Theme.noteW, h: () => root.hot ? note.wanted : Theme.noteH },
        { cond: () => Launcher.open, w: () => Theme.launchW, h: () => launch.y + launch.height + Theme.lpad },
        { cond: () => Power.open, w: () => Theme.powerW, h: () => power.y + power.height + Theme.pwPad },
        { cond: () => Wallpaper.open, w: () => Theme.wallW, h: () => wall.y + wall.height + Theme.wallPad },
        { cond: () => Record.open, w: () => rec.width + 2 * Theme.pwPad, h: () => rec.y + rec.height + Theme.pwPad },
        { cond: () => Screenshot.open, w: () => shot.width + 2 * Theme.pwPad, h: () => shot.y + shot.height + Theme.pwPad },
        { cond: () => Net.open, w: () => Theme.netW, h: () => net.y + net.height + Theme.netPad },
        { cond: () => Mixer.open, w: () => mixer.width + 2 * Theme.mixerPad, h: () => mixer.y + mixer.height + Theme.mixerPad },
        { cond: () => Brightness.open, w: () => Theme.brightW, h: () => bright.y + bright.height + Theme.brightPad },
        { cond: () => Audio.open, w: () => Theme.audioW, h: () => audio.y + audio.height + Theme.audioPad },
        { cond: () => Bt.open, w: () => Theme.btW, h: () => bt.y + bt.height + Theme.btPad },
        { cond: () => Notifs.open, w: () => Theme.centerW, h: () => center.y + center.height + Theme.centerPad },
        { cond: () => root.popout && islandPop.calendarShown, w: () => Theme.islandCalW, h: () => cal.y + cal.height + Theme.islandCalPad },
        { cond: () => root.popout && islandPop.weekShown, w: () => Theme.islandWeekW, h: () => Theme.islandWeekH },
        { cond: () => root.popout && islandPop.popped, w: () => root.idleTargetW + Theme.islandPopW, h: () => Theme.h + Theme.islandPopH }
    ]

    function activePanel() {
        for (const p of root.panelSizes)
            if (p.cond())
                return p
        return null
    }

    readonly property real wantW: {
        const p = root.activePanel()
        if (p)
            return p.w()
        return root.hot ? (root.media && !root.full ? Theme.mediaPillW : Theme.openW)
            : root.calm ? root.idleTargetW : Theme.w
    }

    readonly property real wantH: {
        const p = root.activePanel()
        if (p)
            return p.h()
        if (root.full)
            return cal.y + cal.height + Theme.pad
        return root.hot ? (root.media ? tune.y + tune.height + Theme.pad : Theme.openH) : Theme.h
    }

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

    readonly property int islandResizeDuration: root.popout ? Theme.islandDuration : Theme.speed
    readonly property int islandResizeEase: root.popout ? Theme.islandEase : Theme.ease

    Behavior on wAnim {
        NumberAnimation {
            duration: root.islandResizeDuration
            easing.type: root.islandResizeEase
        }
    }

    Behavior on hAnim {
        NumberAnimation {
            duration: root.islandResizeDuration
            easing.type: root.islandResizeEase
        }
    }

    Rectangle {
        anchors.fill: body
        radius: body.radius
        color: Theme.bg
        antialiasing: true
    }

    ClippingRectangle {
        id: body
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.alignWhenCentered: false
        y: Theme.gap + (root.popout && islandPop.popped ? Theme.islandPopDrop : 0)
        width: root.wAnim
        height: root.hAnim
        radius: Math.min(Math.min(width, height) / 2,
            Launcher.open ? Theme.launchRadius :
            (root.popout && islandPop.calendarShown) ? Theme.islandCalRadius :
            (root.popout && islandPop.weekShown) ? Theme.islandWeekRadius :
            Theme.radius)
        antialiasing: true
        color: "transparent"

        Behavior on y {
            NumberAnimation {
                duration: root.islandResizeDuration
                easing.type: root.islandResizeEase
            }
        }

        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (root.popout)
                    islandPop.hovered = hovered && (!root.modal || Modal.which === "island")
                else if (!hovered)
                    root.full = false
            }
        }

        TapHandler {
            onTapped: {
                if (root.alert)
                    Notifs.dismiss()
                else if (root.popout) {
                    if (!root.modal || Modal.which === "island")
                        islandPop.click()
                } else if (!root.modal && root.hot)
                    root.full = !root.full
            }
        }

        Week {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.popout ? Theme.islandWeekStripY : Theme.body
            now: clock.date
            width: root.popout ? Theme.islandWeekW : Theme.gridW
            cells: root.popout ? Theme.islandWeekCells : Theme.weekCells
            lead: root.popout ? Theme.islandWeekLead : Theme.weekLead
            fadeSpan: root.popout ? Theme.islandWeekFadeSpan : Theme.weekFadeSpan
            fadeMin: root.popout ? Theme.islandWeekFadeMin : Theme.weekFadeMin
            shown: root.popout ? islandPop.depth === 2 : (root.hot && !root.full && root.calm && !root.media)
            ready: root.panelReady
            rise: root.panelRise
        }

        MediaPanel {
            id: tune
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.body
            shown: !root.popout && root.hot && !root.full && root.calm && root.media
            ready: root.panelReady
            rise: root.panelRise
        }

        Calendar {
            id: cal
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.popout ? Theme.islandCalPad : Theme.pad
            now: clock.date
            cw: root.popout ? Theme.islandCalCellW : Theme.cellW
            ch: root.popout ? Theme.islandCalCellH : Theme.cellH
            px: root.popout ? Theme.fsL : Theme.fsM
            shown: root.popout ? islandPop.calendarShown : (root.hot && root.full && root.calm)
            ready: root.panelReady
            rise: root.panelRise
            focus: shown
            Keys.onEscapePressed: Modal.dismiss()
        }

        Note {
            id: note
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.alignWhenCentered: false
            y: 0
            n: Notifs.current
            expanded: root.hot
            shown: root.alert
            ready: root.panelReady
            rise: root.panelRise
        }

        LauncherMenu {
            id: launch
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.lpad
            shown: Launcher.open
            ready: root.panelReady && launch.settled
            rise: root.panelRise
        }

        PowerMenu {
            id: power
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.pwPad
            shown: Power.open
            ready: root.panelReady
            rise: root.panelRise
        }

        WallpaperMenu {
            id: wall
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.wallPad
            shown: Wallpaper.open
            ready: root.panelReady
            rise: root.panelRise
        }

        RecordMenu {
            id: rec
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.pwPad
            shown: Record.open
            ready: root.panelReady
            rise: root.panelRise
        }

        ScreenshotMenu {
            id: shot
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.pwPad
            shown: Screenshot.open
            ready: root.panelReady
            rise: root.panelRise
        }

        NetMenu {
            id: net
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.netPad
            shown: Net.open
            ready: root.panelReady
            rise: root.panelRise
        }

        MixerMenu {
            id: mixer
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.mixerPad
            shown: Mixer.open
            ready: root.panelReady
            rise: root.panelRise
        }

        BrightnessMenu {
            id: bright
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.brightPad
            shown: Brightness.open
            ready: root.panelReady
            rise: root.panelRise
        }

        AudioMenu {
            id: audio
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.audioPad
            shown: Audio.open
            ready: root.panelReady
            rise: root.panelRise
        }

        BtMenu {
            id: bt
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.btPad
            shown: Bt.open
            ready: root.panelReady
            rise: root.panelRise
        }

        Center {
            id: center
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.centerPad
            shown: Notifs.open
            ready: root.panelReady && center.settled
            rise: root.panelRise
        }

        Auth {
            id: auth
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.authPad
            shown: Polkit.open
            ready: root.panelReady
            rise: root.panelRise
        }
    }

    Fade {
        id: idle
        anchors.horizontalCenter: body.horizontalCenter
        anchors.alignWhenCentered: false
        anchors.top: body.top
        anchors.topMargin: Theme.idleTopOffsetY + (root.popout && islandPop.weekShown ? Theme.islandWeekClockY : 0)
        width: row.width

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: root.islandResizeDuration
                easing.type: root.islandResizeEase
            }
        }

        height: Theme.h
        shown: root.calm
        ready: !wake.running
        rise: Theme.idleRise
        fall: Theme.idleFall
        scale: active ? 1 : Theme.slotScale
        z: 2

        transform: Translate {
            x: Theme.idleOffsetX
            y: Theme.idleOffsetY
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.idlePopDuration
                easing.type: Theme.ease
            }
        }

        Row {
            id: row
            width: clockSlot.width + battery.width + mic.width + record.width
            height: parent.height
            spacing: 0

            Item {
                id: clockSlot
                width: Math.max(clockText.implicitWidth, vbars.width)
                height: parent.height

                Fade {
                    id: clockFade
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Theme.clockOffsetY
                    anchors.alignWhenCentered: Theme.idleAlignWhenCentered
                    width: clockText.implicitWidth
                    height: parent.height
                    shown: !root.showVisualizer && !root.calOpen
                    scale: (active ? 1 : Theme.slotScale) * (root.popout && islandPop.weekShown ? Theme.islandWeekClockScale : 1)

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.idlePopDuration
                            easing.type: Theme.ease
                        }
                    }

                    Txt {
                        id: clockText
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        font.pixelSize: Theme.clockPx

                        transform: Translate {
                            x: Theme.clockOffsetX
                        }
                    }
                }

                Fade {
                    id: visFade
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: vbars.width
                    height: parent.height
                    shown: root.showVisualizer && !root.calOpen
                    ready: root.panelReady
                    rise: root.panelRise
                    scale: active ? 1 : Theme.slotScale

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.idlePopDuration
                            easing.type: Theme.ease
                        }
                    }

                    VisualizerBars {
                        id: vbars
                        anchors.centerIn: parent
                        playing: Media.playing
                        shown: visFade.visible
                        artUrl: Media.artUrl
                    }
                }
            }

            BatteryIcon {
                id: battery
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.moduleOffsetY + Theme.batteryOffsetY
                anchors.alignWhenCentered: Theme.idleAlignWhenCentered
                shown: Battery.shown && !root.hideIdleIcons
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
                shown: Mic.muted && !root.hideIdleIcons
                leadingGap: Theme.clockGap + (Theme.rowGap - Theme.clockGap) * battery.enter
                settledGap: battery.active ? Theme.rowGap : Theme.clockGap
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
                shown: Record.active && !root.hideIdleIcons
                leadingGap: Theme.clockGap + (Theme.rowGap - Theme.clockGap) * Math.max(battery.enter, mic.enter)
                settledGap: (battery.active || mic.shown) ? Theme.rowGap : Theme.clockGap
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

    Rectangle {
        anchors.fill: body
        radius: body.radius
        color: "transparent"
        border.width: Theme.pillBorderWidth
        border.color: Qt.rgba(1, 1, 1, Theme.pillBorderOpacity)
        antialiasing: true
        z: 3
    }

    Fade {
        id: ringFade
        anchors.top: body.top
        anchors.horizontalCenter: body.horizontalCenter
        width: body.width
        height: body.height
        shown: root.ringBase
        ready: !ringSettle.running
        rise: Theme.batRingRise
        fall: Theme.batRingFall
        z: 4

        BatteryRing {
            anchors.centerIn: parent
            pillW: body.width
            pillH: body.height
            pillRadius: body.radius
            pct: Battery.pct
        }
    }

    Rectangle {
        anchors.fill: body
        anchors.margins: -Theme.pillHaloSpread
        radius: body.radius + Theme.pillHaloSpread
        color: "transparent"
        border.width: Theme.pillHaloWidth
        border.color: Qt.rgba(0, 0, 0, Theme.pillHaloOpacity)
        antialiasing: true
        z: 5
    }
}


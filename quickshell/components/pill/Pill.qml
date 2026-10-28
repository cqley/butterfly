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
    readonly property bool classicHot: root.hot && !root.popout
    readonly property bool panelOpen: root.popout ? islandPop.open : root.full
    readonly property bool islandOwn: root.popout && Modal.which === "island"
    readonly property bool engaged: root.popout ? islandPop.popped : root.hot
    readonly property bool mediaHover: root.classicHot && !root.full && root.calm && root.media
    readonly property bool mediaPeek: root.popout && islandPop.popped && !islandPop.open && root.media
    readonly property bool showVisualizer: Visualizer.on || root.mediaHover || root.mediaPeek
    readonly property bool hideIdleIcons: root.mediaHover || root.panelOpen
    readonly property bool ringGeometryBase: root.calm && !root.hot && !root.hideIdleIcons
    readonly property bool ringBase: root.ringGeometryBase && Theme.batRingEnabled && Battery.ringShown && Battery.available
    readonly property bool resizing:
        Math.abs(root.wAnim - root.targetW) > Theme.settleEps ||
        Math.abs(root.hAnim - root.targetH) > Theme.settleEps
    readonly property string face: Modal.any ? Modal.which : root.alert ? "note" : "idle"
    readonly property bool moving: hold.running || root.resizing
    readonly property bool panelReady: !root.moving
    readonly property bool panelReveal: !Theme.holdPanels || root.panelReady
    readonly property int panelRise: root.swapped ? Theme.swapRise : Theme.rise
    property bool wasMenu: false
    property bool swapped: false
    property real holdW: Theme.w
    property real holdH: Theme.h
    property bool media: false
    readonly property real wAnim: wMotion.value
    readonly property real hAnim: hMotion.value

    onModalChanged: full = false
    onAlertChanged: if (!alert) full = false
    onEngagedChanged: sync()
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
    Timer {
        id: stage
        interval: Theme.islandContentStage
    }

    IslandPop {
        id: islandPop
        enabled: root.popout
        media: root.media
        onDepthChanged: if (root.popout) stage.restart()
    }

    readonly property bool islandReady: !stage.running

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
        media = Media.playing || (engaged && media && Media.player !== null)
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

    property alias hitTarget: hit

    Item {
        id: hit
        readonly property real popW: root.idleTargetW + Theme.islandPopW + 2 * Theme.islandHitGrow
        readonly property real popH: Theme.islandPopDrop + Theme.h + Theme.islandPopH + Theme.islandHitGrow
        x: (root.width - width) / 2
        y: Theme.gap
        width: root.popout ? Math.max(body.width, popW) : body.width
        height: root.popout ? Math.max(body.y - Theme.gap + body.height, popH) : body.height

        HoverHandler { id: halo }
    }

    Binding {
        target: islandPop
        property: "hovered"
        value: root.popout && (hover.hovered || halo.hovered) && !root.alert && (!root.modal || Modal.which === "island")
    }

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

    readonly property real idleRowW: clockSlot.width + battery.targetWidth + mic.targetWidth + record.targetWidth
    readonly property real idleTargetW: Math.max(Theme.w, root.idleRowW + Theme.pad)
    readonly property real idleSnap: Math.round((root.width - root.idleRowW) / 2) - (root.width - root.idleRowW) / 2
    readonly property real idleX: (root.width - row.width) / 2 + root.idleSnap

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
        { cond: () => root.popout && islandPop.mediaShown, w: () => Theme.islandMediaW, h: () => Theme.islandMediaH },
        { cond: () => root.popout && islandPop.popped, w: () => root.idleTargetW + Theme.islandPopW, h: () => Theme.h + Theme.islandPopH }
    ]

    function activePanel() {
        for (const p of root.panelSizes)
            if (p.cond())
                return p
        return null
    }

    function centerX(w) {
        return Math.round((root.width - w) / 2) - body.x
    }

    readonly property real wantW: {
        const p = root.activePanel()
        if (p)
            return p.w()
        return root.classicHot ? (root.media && !root.full ? Theme.mediaPillW : Theme.openW)
            : root.calm ? root.idleTargetW : Theme.w
    }

    readonly property real wantH: {
        const p = root.activePanel()
        if (p)
            return p.h()
        if (root.full)
            return cal.y + cal.height + Theme.pad
        return root.classicHot ? (root.media ? tune.y + tune.height + Theme.pad : Theme.openH) : Theme.h
    }

    readonly property int islandResizeDuration: root.popout ? Theme.islandDuration : Theme.speed
    readonly property int islandResizeEase: root.popout ? Theme.islandEase : Theme.ease
    readonly property real idleCenterDrop: dropMotion.value
    readonly property real bodyDrop: Theme.gap + (root.popout && islandPop.popped ? Theme.islandPopDrop : 0)

    Spring {
        id: wMotion
        target: root.targetW
        response: Theme.islandResponse
        damping: Theme.islandDamping
        duration: root.islandResizeDuration
        easing: root.islandResizeEase
    }

    Spring {
        id: hMotion
        target: root.targetH
        response: Theme.islandResponse
        damping: Theme.islandDamping
        duration: root.islandResizeDuration
        easing: root.islandResizeEase
    }

    Spring {
        id: yMotion
        target: root.bodyDrop
        response: Theme.islandDropResponse
        damping: Theme.islandDropDamping
        duration: root.islandResizeDuration
        easing: root.islandResizeEase
    }

    Spring {
        id: dropMotion
        target: root.popout && islandPop.popped ? Theme.islandPopH / 2 : 0
        response: Theme.islandResponse
        damping: Theme.islandDamping
        duration: root.islandResizeDuration
        easing: root.islandResizeEase
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
        y: yMotion.value
        width: root.wAnim
        height: root.hAnim
        radius: Math.min(Math.min(width, height) / 2, Launcher.open ? Theme.launchRadius : Theme.radius)
        antialiasing: true
        color: "transparent"

        HoverHandler {
            id: hover
            onHoveredChanged: if (!root.popout && !hovered) root.full = false
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
            id: strip
            x: root.centerX(width)
            y: root.popout ? Theme.islandWeekPad : Theme.body
            now: clock.date
            width: root.popout ? Theme.islandWeekW : Theme.gridW
            cells: root.popout ? Theme.islandWeekCells : Theme.weekCells
            lead: root.popout ? Theme.islandWeekLead : Theme.weekLead
            fadeSpan: root.popout ? Theme.islandWeekFadeSpan : Theme.weekFadeSpan
            fadeMin: root.popout ? Theme.islandWeekFadeMin : Theme.weekFadeMin
            fadeCurve: root.popout ? Theme.islandWeekFadeCurve : Theme.weekFadeCurve
            slide: root.popout ? Theme.islandContentSlide : 0
            shown: root.popout ? islandPop.weekShown : (root.classicHot && !root.full && root.calm && !root.media)
            ready: root.popout ? root.islandReady : root.panelReveal
            rise: root.popout ? Theme.islandDuration : root.panelRise
            focus: root.popout && shown
            onShownChanged: if (root.popout && shown) strip.forceActiveFocus()
            Keys.onEscapePressed: Modal.dismiss()
        }

        MediaPanel {
            id: tune
            x: root.centerX(width)
            y: root.popout ? Theme.islandMediaPad : Theme.body
            slide: root.popout ? Theme.islandContentSlide : 0
            shown: root.popout ? islandPop.mediaShown : (root.classicHot && !root.full && root.calm && root.media)
            ready: root.popout ? root.islandReady : root.panelReveal
            rise: root.popout ? Theme.islandDuration : root.panelRise
            focus: root.popout && shown
            onShownChanged: if (root.popout && shown) tune.forceActiveFocus()
            Keys.onEscapePressed: Modal.dismiss()
        }

        Calendar {
            id: cal
            x: root.centerX(width)
            y: root.popout ? Theme.islandCalPad : Theme.pad
            now: clock.date
            cw: root.popout ? Theme.islandCalCellW : Theme.cellW
            ch: root.popout ? Theme.islandCalCellH : Theme.cellH
            px: root.popout ? Theme.fsL : Theme.fsM
            slide: root.popout ? Theme.islandContentSlide : 0
            shown: root.popout ? islandPop.calendarShown : (root.hot && root.full && root.calm)
            ready: root.popout ? root.islandReady : root.panelReveal
            rise: root.popout ? Theme.islandDuration : root.panelRise
            focus: shown
            onShownChanged: if (root.popout && shown) cal.forceActiveFocus()
            Keys.onEscapePressed: Modal.dismiss()
        }

        Note {
            id: note
            x: root.centerX(width)
            y: 0
            n: Notifs.current
            expanded: root.hot
            shown: root.alert
            ready: root.panelReveal
            rise: root.panelRise
        }

        LauncherMenu {
            id: launch
            x: root.centerX(width)
            y: Theme.lpad
            shown: Launcher.open
            ready: root.panelReveal && launch.settled
            rise: root.panelRise
        }

        PowerMenu {
            id: power
            x: root.centerX(width)
            y: Theme.pwPad
            shown: Power.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        WallpaperMenu {
            id: wall
            x: root.centerX(width)
            y: Theme.wallPad
            shown: Wallpaper.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        RecordMenu {
            id: rec
            x: root.centerX(width)
            y: Theme.pwPad
            shown: Record.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        ScreenshotMenu {
            id: shot
            x: root.centerX(width)
            y: Theme.pwPad
            shown: Screenshot.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        NetMenu {
            id: net
            x: root.centerX(width)
            y: Theme.netPad
            shown: Net.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        MixerMenu {
            id: mixer
            x: root.centerX(width)
            y: Theme.mixerPad
            shown: Mixer.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        BrightnessMenu {
            id: bright
            x: root.centerX(width)
            y: Theme.brightPad
            shown: Brightness.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        AudioMenu {
            id: audio
            x: root.centerX(width)
            y: Theme.audioPad
            shown: Audio.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        BtMenu {
            id: bt
            x: root.centerX(width)
            y: Theme.btPad
            shown: Bt.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        Center {
            id: center
            x: root.centerX(width)
            y: Theme.centerPad
            shown: Notifs.open
            ready: root.panelReveal && center.settled
            rise: root.panelRise
        }

        Auth {
            id: auth
            x: root.centerX(width)
            y: Theme.authPad
            shown: Polkit.open
            ready: root.panelReveal
            rise: root.panelRise
        }
    }

    Fade {
        id: idle
        x: root.idleX
        anchors.top: body.top
        anchors.topMargin: Theme.idleTopOffsetY + root.idleCenterDrop
        width: row.width
        height: Theme.h
        shown: root.calm || root.islandOwn
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
                width: Math.ceil(Math.max(clockText.implicitWidth, vbars.width))
                height: parent.height

                Fade {
                    id: clockFade
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Theme.clockOffsetY
                    anchors.alignWhenCentered: Theme.idleAlignWhenCentered
                    width: clockText.implicitWidth
                    height: parent.height
                    shown: !root.showVisualizer && !root.panelOpen
                    scale: active ? 1 : Theme.slotScale

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
                        font.features: Theme.tabular

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
                    shown: root.showVisualizer && !root.panelOpen
                    ready: root.panelReveal
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
        anchors.fill: body
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


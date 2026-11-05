import QtQuick
import Quickshell
import Quickshell.Widgets
import "../audio"
import "../bluetooth"
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
import "../tray"
import "../wallpaper"
import "../workspaces"

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

    readonly property bool hot: hover.hovered
    readonly property bool modal: Modal.any
    readonly property bool alert: Notifs.current !== null && !modal
    readonly property bool calm: !alert && !modal
    readonly property bool panelOpen: islandPop.open
    readonly property bool islandOwn: Modal.which === "island"
    readonly property bool engaged: islandPop.popped
    readonly property bool mediaPeek: islandPop.popped && !islandPop.open && root.media
    readonly property bool mediaPanelShown: islandPop.mediaShown
    readonly property bool showVisualizer: Visualizer.on || root.mediaPeek || root.mediaPanelShown
    readonly property bool wsAvailable: Theme.wsOn && Workspaces.available
    readonly property bool wsOnly: root.wsAvailable && Theme.wsPlace === "only"
    readonly property bool wsLeft: root.wsAvailable && Theme.wsPlace !== "only" && Theme.wsPlace !== "right"
    readonly property bool wsRight: root.wsAvailable && Theme.wsPlace === "right"
    readonly property bool idleRowActive: root.calm || root.islandOwn
    readonly property bool idleSlotVisible: root.idleRowActive && (!root.panelOpen || root.mediaPanelShown)
    readonly property bool hideIdleIcons: !root.idleRowActive || root.panelOpen
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
    property bool launchRevealed: false
    property bool wasMenu: false
    property bool swapped: false
    property real holdW: Theme.w
    property real holdH: Theme.h
    property bool media: false
    readonly property real wAnim: wMotion.value
    readonly property real hAnim: hMotion.value

    onEngagedChanged: sync()
    onShowVisualizerChanged: swapGate.restart()
    onWsOnlyChanged: swapGate.restart()
    onFaceChanged: {
        swapped = root.wasMenu && Modal.any
        wasMenu = Modal.any
    }
    onPanelReadyChanged: if (Theme.blockSwap && root.panelReady && Modal.any) grow.restart()
    onCalmChanged: if (calm && Theme.idleWait > 0) wake.restart()
    onRingGeometryBaseChanged: ringSettle.restart()
    onPanelRevealChanged: if (Launcher.open && root.panelReveal) root.launchRevealed = true

    Connections {
        target: Launcher
        function onOpenChanged() { if (!Launcher.open) root.launchRevealed = false }
    }
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
        media: root.media
        onDepthChanged: stage.restart()
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
        Modal.register("bluetooth", Bt)
        Modal.register("tray", Tray)
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
        readonly property real restW: root.idleTargetW + 2 * Theme.islandHitGrow
        readonly property real restH: Theme.h + Theme.islandHitGrow
        x: (root.width - width) / 2
        y: Theme.gap
        width: Math.max(body.width, restW)
        height: Math.max(body.y - Theme.gap + body.height, restH)

        HoverHandler { id: halo }
    }

    Binding {
        target: islandPop
        property: "hovered"
        value: (hover.hovered || halo.hovered) && !root.alert && (!root.modal || Modal.which === "island")
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

    readonly property real idleRowW: leftRow.targetWidth + clockSlot.width + rightRow.targetWidth

    readonly property var leftModules: [
        {
            key: "ws", clip: false, component: wsLeftContent,
            shownFn: () => root.wsLeft && !root.hideIdleIcons,
            sizeFn: () => Theme.h, contentWidthFn: () => Workspaces.span,
            clockGapFn: () => Theme.wsClockGap,
            offsetXFn: () => Theme.wsOffsetX, offsetYFn: () => Theme.wsOffsetY
        },
        {
            key: "battery", component: batteryContent,
            shownFn: () => Battery.shown && Battery.available && Theme.batPlace === "left" && !root.hideIdleIcons,
            sizeFn: () => Theme.h, contentWidthFn: () => Theme.batW + Theme.batNubGap + Theme.batNubW,
            offsetXFn: () => Theme.batteryOffsetX, offsetYFn: () => Theme.batteryOffsetY
        },
        {
            key: "mic", component: micContent,
            shownFn: () => Mic.muted && Theme.micPlace === "left" && !root.hideIdleIcons,
            sizeFn: () => Theme.micS,
            offsetXFn: () => Theme.micOffsetX, offsetYFn: () => Theme.micOffsetY
        },
        {
            key: "record", component: recordContent,
            shownFn: () => Record.active && Theme.recPlace === "left" && !root.hideIdleIcons,
            sizeFn: () => Theme.recordDot,
            offsetXFn: () => Theme.recordOffsetX, offsetYFn: () => Theme.recordOffsetY
        }
    ]

    readonly property var rightModules: [
        {
            key: "ws", clip: false, component: wsRightContent,
            shownFn: () => root.wsRight && !root.hideIdleIcons,
            sizeFn: () => Theme.h, contentWidthFn: () => Workspaces.span,
            clockGapFn: () => Theme.wsClockGap,
            offsetXFn: () => Theme.wsOffsetX, offsetYFn: () => Theme.wsOffsetY
        },
        {
            key: "battery", component: batteryContent,
            shownFn: () => Battery.shown && Battery.available && Theme.batPlace === "right" && !root.hideIdleIcons,
            sizeFn: () => Theme.h, contentWidthFn: () => Theme.batW + Theme.batNubGap + Theme.batNubW,
            offsetXFn: () => Theme.batteryOffsetX, offsetYFn: () => Theme.batteryOffsetY
        },
        {
            key: "mic", component: micContent,
            shownFn: () => Mic.muted && Theme.micPlace === "right" && !root.hideIdleIcons,
            sizeFn: () => Theme.micS,
            offsetXFn: () => Theme.micOffsetX, offsetYFn: () => Theme.micOffsetY
        },
        {
            key: "record", component: recordContent,
            shownFn: () => Record.active && Theme.recPlace === "right" && !root.hideIdleIcons,
            sizeFn: () => Theme.recordDot,
            offsetXFn: () => Theme.recordOffsetX, offsetYFn: () => Theme.recordOffsetY
        }
    ]

    Component {
        id: wsLeftContent
        WorkspaceStrip {
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            opacity: (root.wsLeft && !root.hideIdleIcons) ? 1 : 0
            index: Workspaces.index
            count: Workspaces.count
            page: Workspaces.page
            filled: Workspaces.filled

            Behavior on opacity {
                NumberAnimation {
                    duration: (root.wsLeft && !root.hideIdleIcons) ? 0 : Theme.fall
                    easing.type: Theme.ease
                }
            }
        }
    }

    Component {
        id: wsRightContent
        WorkspaceStrip {
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            opacity: (root.wsRight && !root.hideIdleIcons) ? 1 : 0
            index: Workspaces.index
            count: Workspaces.count
            page: Workspaces.page
            filled: Workspaces.filled

            Behavior on opacity {
                NumberAnimation {
                    duration: (root.wsRight && !root.hideIdleIcons) ? 0 : Theme.fall
                    easing.type: Theme.ease
                }
            }
        }
    }

    Component {
        id: batteryContent
        BatteryIcon {
            pct: Battery.pct
            tone: Battery.tone
            pluggedIn: Battery.pluggedIn
        }
    }

    Component {
        id: micContent
        MicOff {}
    }

    Component {
        id: recordContent
        RecordDot {}
    }
    readonly property real idleTargetW: Math.max(Theme.w, root.idleRowW + Theme.pad + (root.wsAvailable ? 2 * Theme.wsPad : 0))
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
        { cond: () => Bt.open, w: () => Theme.btW, h: () => bt.y + bt.height + Theme.btPad },
        { cond: () => Tray.open && Tray.menuItem, w: () => Theme.trayMenuW, h: () => trayCtx.y + trayCtx.height + Theme.trayMenuPad },
        { cond: () => Tray.open, w: () => tray.width + 2 * Theme.trayPad, h: () => tray.y + tray.height + Theme.trayPad },
        { cond: () => Notifs.open, w: () => Theme.centerW, h: () => center.y + center.height + Theme.centerPad },
        { cond: () => islandPop.calendarShown, w: () => Theme.islandCalW, h: () => cal.y + cal.height + Theme.islandCalPad },
        { cond: () => islandPop.weekShown, w: () => Theme.islandWeekW, h: () => Theme.islandWeekH },
        { cond: () => islandPop.mediaShown, w: () => Theme.islandMediaW, h: () => Theme.islandMediaH },
        { cond: () => islandPop.popped, w: () => root.idleTargetW + Theme.islandPopW, h: () => Theme.h + Theme.islandPopH }
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
        return root.calm ? root.idleTargetW : Theme.w
    }

    readonly property real wantH: {
        const p = root.activePanel()
        if (p)
            return p.h()
        return Theme.h
    }

    readonly property real idleCenterDrop: dropMotion.value
    readonly property real bodyDrop: Theme.gap + (islandPop.popped ? Theme.islandPopDrop : 0)

    Spring {
        id: wMotion
        target: root.targetW
        response: Theme.islandResponse
        damping: Theme.islandDamping
        epsilon: Theme.settleEps
    }

    Spring {
        id: hMotion
        target: root.targetH
        response: Theme.islandResponse
        damping: Theme.islandDamping
        epsilon: Theme.settleEps
    }

    Spring {
        id: yMotion
        target: root.bodyDrop
        response: Theme.islandDropResponse
        damping: Theme.islandDropDamping
        epsilon: Theme.settleEps
    }

    Spring {
        id: dropMotion
        target: islandPop.popped ? Theme.islandPopH / 2 : 0
        response: Theme.islandDropResponse
        damping: Theme.islandDropDamping
        epsilon: Theme.settleEps
    }

    Item {
        id: skin
        x: (root.width - width) / 2
        y: yMotion.value
        width: root.wAnim
        height: root.hAnim
    }

    Shadow {
        anchors.fill: skin
        radius: body.radius
    }

    Rectangle {
        anchors.fill: skin
        radius: body.radius
        color: Theme.bg
        antialiasing: true
    }

    ClippingRectangle {
        id: body
        x: Math.round((root.width - width) / 2)
        y: Math.round(yMotion.value)
        width: Math.round(root.wAnim)
        height: Math.round(root.hAnim)
        radius: Math.min(Math.min(width, height) / 2, Launcher.open ? Theme.launchRadius : Theme.radius)
        antialiasing: true
        color: "transparent"

        HoverHandler {
            id: hover
        }

        TapHandler {
            onTapped: {
                if (root.alert)
                    Notifs.dismiss()
                else if (!root.modal || Modal.which === "island")
                    islandPop.click()
            }
        }

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: {
                if (!root.alert && !root.modal)
                    Tray.toggle()
            }
        }

        Week {
            id: strip
            x: root.centerX(width)
            y: Theme.islandWeekPad
            now: clock.date
            width: Theme.islandWeekW
            cells: Theme.islandWeekCells
            lead: Theme.islandWeekLead
            fadeSpan: Theme.islandWeekFadeSpan
            fadeMin: Theme.islandWeekFadeMin
            fadeCurve: Theme.islandWeekFadeCurve
            slide: Theme.islandContentSlide
            shown: islandPop.weekShown
            ready: root.islandReady
            rise: Theme.islandDuration
            focus: shown
            onShownChanged: if (shown) strip.forceActiveFocus()
            Keys.onEscapePressed: Modal.dismiss()
        }

        MediaPanel {
            id: tune
            x: root.centerX(width)
            y: Theme.islandMediaTopPad
            shown: islandPop.mediaShown
            ready: root.panelReveal
            rise: root.panelRise
            focus: shown
            onShownChanged: if (shown) tune.forceActiveFocus()
            Keys.onEscapePressed: Modal.dismiss()
        }

        Calendar {
            id: cal
            x: root.centerX(width)
            y: Theme.islandCalPad
            now: clock.date
            cw: Theme.islandCalCellW
            ch: Theme.islandCalCellH
            px: Theme.fsL
            slide: Theme.islandContentSlide
            shown: islandPop.calendarShown
            ready: root.islandReady
            rise: Theme.islandDuration
            focus: shown
            onShownChanged: if (shown) cal.forceActiveFocus()
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
            ready: root.launchRevealed || root.panelReveal
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

        BtMenu {
            id: bt
            x: root.centerX(width)
            y: Theme.btPad
            shown: Bt.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        TrayMenu {
            id: tray
            x: root.centerX(width)
            y: Theme.trayPad
            shown: Tray.open && !Tray.menuItem
            ready: root.panelReveal
            rise: root.panelRise
        }

        TrayContextMenu {
            id: trayCtx
            x: root.centerX(width)
            y: Theme.trayMenuPad
            shown: Tray.open && !!Tray.menuItem
            ready: root.panelReveal && trayCtx.settled
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
        shown: root.idleRowActive
        ready: !wake.running
        rise: Theme.idleRise
        fall: Theme.idleFall
        scale: Theme.slotScale + (1 - Theme.slotScale) * idleScale.value
        z: 2

        Spring {
            id: idleScale
            target: idle.active ? 1 : 0
            response: Theme.idlePopResponse
            damping: Theme.idlePopDamping
            epsilon: Theme.springUnitEps
            rest: Theme.springUnitStop
        }

        transform: Translate {
            x: Theme.idleOffsetX
            y: Theme.idleOffsetY
        }

        Row {
            id: row
            width: leftRow.width + clockSlot.width + rightRow.width
            height: parent.height
            spacing: 0

            IconRow {
                id: leftRow
                clockEnd: true
                modules: root.leftModules
            }

            Item {
                id: clockSlot
                width: Math.ceil(Math.max(root.wsOnly ? wsOnlyStrip.span : clockText.implicitWidth, vbars.width))
                height: parent.height

                Timer {
                    id: swapGate
                    interval: Theme.fall
                }

                Fade {
                    id: clockFade
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Theme.clockOffsetY
                    anchors.alignWhenCentered: Theme.idleAlignWhenCentered
                    width: clockText.implicitWidth
                    height: parent.height
                    shown: !root.showVisualizer && !root.wsOnly && root.idleSlotVisible
                    ready: !swapGate.running
                    scale: Theme.slotScale + (1 - Theme.slotScale) * clockScale.value

                    Spring {
                        id: clockScale
                        target: clockFade.active ? 1 : 0
                        response: Theme.idlePopResponse
                        damping: Theme.idlePopDamping
                        epsilon: Theme.springUnitEps
                        rest: Theme.springUnitStop
                    }

                    OpticalCenter {
                        id: clockOptical
                        targetFont: clockText.font
                        text: clockText.text
                    }

                    Txt {
                        id: clockText
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: Theme.clockText(clock.date)
                        font.pixelSize: Theme.clockPx
                        font.features: Theme.tabular

                        transform: Translate {
                            x: Theme.clockOffsetX
                            y: clockOptical.shift
                        }
                    }
                }

                Fade {
                    id: wsOnlyFade
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.alignWhenCentered: Theme.idleAlignWhenCentered
                    width: wsOnlyStrip.span
                    height: parent.height
                    shown: root.wsOnly && !root.showVisualizer && root.idleSlotVisible
                    ready: !swapGate.running
                    scale: Theme.slotScale + (1 - Theme.slotScale) * wsOnlyScale.value

                    Spring {
                        id: wsOnlyScale
                        target: wsOnlyFade.active ? 1 : 0
                        response: Theme.idlePopResponse
                        damping: Theme.idlePopDamping
                        epsilon: Theme.springUnitEps
                        rest: Theme.springUnitStop
                    }

                    transform: Translate {
                        x: Theme.wsOffsetX
                    }

                    WorkspaceStrip {
                        id: wsOnlyStrip
                        anchors.centerIn: parent
                        index: Workspaces.index
                        count: Workspaces.count
                        page: Workspaces.page
                        filled: Workspaces.filled
                    }
                }

                Fade {
                    id: visFade
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: vbars.width
                    height: parent.height
                    shown: root.showVisualizer && root.idleSlotVisible
                    ready: root.panelReveal && !swapGate.running
                    rise: root.panelRise
                    scale: Theme.slotScale + (1 - Theme.slotScale) * visScale.value

                    Spring {
                        id: visScale
                        target: visFade.active ? 1 : 0
                        response: Theme.idlePopResponse
                        damping: Theme.idlePopDamping
                        epsilon: Theme.springUnitEps
                        rest: Theme.springUnitStop
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

            IconRow {
                id: rightRow
                clockEnd: false
                modules: root.rightModules
            }
        }
    }

    Rectangle {
        anchors.fill: skin
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
        anchors.fill: skin
        anchors.margins: -Theme.pillHaloSpread
        radius: body.radius + Theme.pillHaloSpread
        color: "transparent"
        border.width: Theme.pillHaloWidth
        border.color: Qt.rgba(0, 0, 0, Theme.pillHaloOpacity)
        antialiasing: true
        z: 5
    }
}

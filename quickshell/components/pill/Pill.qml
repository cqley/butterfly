import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
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

    Timer {
        id: dashExit
        interval: Theme.fall
    }

    readonly property bool hot: hover.hovered
    readonly property bool modal: Modal.any && Modal.which !== "settings"
    readonly property bool alert: Notifs.current !== null && !modal
    readonly property bool calm: !alert && !modal
    readonly property bool panelOpen: islandPop.open
    readonly property bool islandOwn: Modal.which === "island"
    readonly property bool engaged: islandPop.popped
    readonly property bool mediaPeek: root.media && islandPop.hovered && islandPop.armed
    readonly property bool mediaPanelShown: islandPop.mediaShown
    readonly property bool dashFace: islandPop.dashShown
    property bool wasClosed: true
    property bool openedFromIdle: true
    property bool heldVis: false
    readonly property bool idleShowing: root.idleRowActive && (!root.panelOpen || root.mediaPanelShown)
    readonly property bool idleBare: root.idleRowActive && !root.panelOpen
    readonly property bool morphRuns: root.openedFromIdle && (root.dashFace || root.idleBare)
    readonly property bool dashStaged: root.dashFace && !root.morphRuns
    readonly property real morphT: root.morphRuns ? morph.value : 1
    readonly property bool morphing: root.morphRuns && (root.dashFace || morph.moving)
    readonly property bool dashLive: root.dashFace || root.morphing || dashExit.running
    readonly property bool dashLeaving: root.dashLive && !root.dashFace && !root.morphing
    readonly property real idleRowCy: Theme.idleTopOffsetY + root.idleCenterDrop + Theme.h / 2
    readonly property bool showVisualizer: Visualizer.on || root.mediaPeek || root.mediaPanelShown
    readonly property bool wifiShown: Theme.wifiOn && (Net.linkKnown || Net.available)
    readonly property bool wsAvailable: Theme.wsOn && Workspaces.available
    readonly property bool wsOnly: root.wsAvailable && Workspaces.place === "only"
    readonly property bool wsLeft: root.wsAvailable && Workspaces.place !== "only" && Workspaces.place !== "right"
    readonly property bool wsRight: root.wsAvailable && Workspaces.place === "right"
    readonly property bool idleRowActive: root.calm || root.islandOwn
    readonly property bool idleHeld: root.morphing
    readonly property bool idleVeiled: root.morphing || dash.visible
    readonly property real morphVeil: root.morphRuns ? (root.idleVeiled ? 0 : 1) : root.orphanVeil
    property real orphanVeil: 1
    readonly property bool wsMorphs: Theme.dashWs && Workspaces.available
    readonly property real wsVeil: root.wsMorphs ? root.morphVeil : root.orphanVeil
    readonly property bool idleSlotVisible: root.idleHeld || root.idleShowing
    readonly property bool hideIdleIcons: !root.idleHeld && (!root.idleRowActive || root.panelOpen)
    readonly property bool slotVis: root.idleHeld ? root.heldVis : root.showVisualizer
    readonly property bool idleClock: !root.slotVis && !root.wsOnly
    readonly property bool ringGeometryBase: root.calm && !root.hot && !root.hideIdleIcons
    readonly property bool ringBase: root.ringGeometryBase && Theme.batRingEnabled && Battery.ringShown && Battery.available
    readonly property bool resizing:
        Math.abs(root.wAnim - root.targetW) > Theme.settleEps ||
        Math.abs(root.hAnim - root.targetH) > Theme.settleEps
    readonly property string face: root.modal ? Modal.which : root.alert ? "note" : "idle"
    readonly property bool moving: hold.running || root.resizing
    readonly property bool panelReady: !root.moving
    readonly property bool panelReveal: !Theme.holdPanels || root.panelReady
    readonly property int panelRise: root.swapped ? Theme.swapRise : Theme.rise
    property string revealedFace: ""
    property bool wasMenu: false
    property bool swapped: false
    property real holdW: Theme.w
    property real holdH: Theme.h
    property bool media: false
    readonly property real wAnim: wMotion.value
    readonly property real hAnim: hMotion.value

    onEngagedChanged: sync()
    onSlotVisChanged: swapGate.restart()
    onWsOnlyChanged: swapGate.restart()
    onFaceChanged: {
        swapped = root.wasMenu && root.modal
        wasMenu = root.modal
        revealedFace = ""
    }
    onPanelReadyChanged: if (Theme.blockSwap && root.panelReady && root.modal) grow.restart()
    onCalmChanged: if (calm && Theme.idleWait > 0) wake.restart()
    onRingGeometryBaseChanged: ringSettle.restart()
    onPanelRevealChanged: if (root.panelReveal) root.revealedFace = root.face
    onDashFaceChanged: {
        if (!root.dashFace) {
            dashExit.restart()
            return
        }
        root.openedFromIdle = root.wasClosed
        dashExit.stop()
    }
    onIdleVeiledChanged: {
        veilRun.stop()
        veilRun.duration = root.idleVeiled ? Theme.fall : Theme.rise
        veilRun.to = root.idleVeiled ? 0 : 1
        veilRun.start()
    }

    NumberAnimation {
        id: veilRun
        target: root
        property: "orphanVeil"
        easing.type: Theme.ease
    }
    onWantWChanged: root.brake()
    onWantHChanged: root.brake()

    function faceReady(name) {
        return root.revealedFace === name || root.panelReveal
    }

    function pop(mode) {
        if (root.alert)
            return
        if (root.modal && !root.islandOwn)
            return
        root.armMorph()
        islandPop.show(mode)
    }

    function showFace(name) {
        root.armMorph()
        return islandPop.toggleFace(name)
    }

    Spring {
        id: morph
        target: root.dashFace ? 1 : 0
        response: root.dashFace ? Theme.dashMorphResponse : Theme.islandResponse
        damping: root.dashFace ? Theme.dashMorphDamping : Theme.islandDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    readonly property real dashLeft: Math.round((root.width - dash.width) / 2)
    readonly property real slotX: root.idleX + leftRow.width
    readonly property real clockHomeX: root.slotX + clockFade.x + clockFade.width / 2
    readonly property real wsOnlyHomeX: root.slotX + wsOnlyFade.x + wsOnlyFade.width / 2

    function slotLocal(key) {
        if (key === "ws" && root.wsOnly)
            return root.wsOnlyHomeX - root.dashLeft
        const l = leftRow.slotCenter(key)
        if (l !== null)
            return root.idleX + l - root.dashLeft
        const r = rightRow.slotCenter(key)
        if (r !== null)
            return root.slotX + clockSlot.width + r - root.dashLeft
        return null
    }

    readonly property var dashOrigins: ({
        clock: (root.idleClock ? root.clockHomeX : root.width / 2) - root.dashLeft,
        ws: root.slotLocal("ws"),
        wifi: root.slotLocal("wifi"),
        battery: root.slotLocal("battery")
    })

    function armMorph() {
        root.wasClosed = !islandPop.open
        root.heldVis = root.showVisualizer
        if (!root.dashFace)
            morph.land(0)
    }

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
        onFaceChanged: stage.restart()
    }

    IpcHandler {
        target: "island"

        function week(): string { return root.showFace("week") }
        function calendar(): string { return root.showFace("calendar") }
        function media(): string { return root.showFace("media") }
        function dash(): string { return root.showFace("dash") }
        function status(): string { return islandPop.report }
    }

    readonly property var dashParts: ["workspaces", "date", "weekday", "notifications", "network", "bluetooth", "power"]

    function dashKey(part) {
        return "dash" + ({
            workspaces: "Ws", date: "Date", weekday: "Weekday", notifications: "Notes",
            network: "Net", bluetooth: "Bt", power: "Power"
        })[part]
    }

    function dashShows(part) {
        return Theme[root.dashKey(part)]
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): string { return root.showFace("dash") }

        function part(part: string): string {
            if (root.dashParts.indexOf(part) < 0)
                return "expected one of " + root.dashParts.join("|")
            const on = !root.dashShows(part)
            Cfg.set(root.dashKey(part), on)
            Cfg.flush()
            return part + " " + (on ? "shown" : "hidden")
        }

        function width(px: int): string {
            if (px < Theme.dashMinW || px > Theme.dashMaxW)
                return "expected " + Theme.dashMinW + "-" + Theme.dashMaxW
            Cfg.set("dashW", px)
            Cfg.flush()
            return Theme.dashW + " px"
        }

        function status(): string {
            const parts = root.dashParts.map(p => p + " " + (root.dashShows(p) ? "on" : "off"))
            return (islandPop.face === "dash" ? "open" : "closed")
                 + " · " + Theme.dashW + " px · " + parts.join(", ")
        }
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
        value: root.hot && root.alert
    }

    Binding {
        target: Notifs
        property: "veiled"
        value: root.modal
    }

    Binding {
        target: Net
        property: "pinLink"
        value: Theme.wifiOn
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property real idleRowW: leftRow.targetWidth + clockSlot.width + rightRow.targetWidth

    readonly property var leftModules: [
        {
            key: "ws", component: wsLeftContent,
            shownFn: () => root.wsLeft && !root.hideIdleIcons,
            morphsFn: () => root.wsMorphs,
            sizeFn: () => Theme.h, contentWidthFn: () => Workspaces.span,
            clockGapFn: () => Theme.wsClockGap,
            offsetXFn: () => Theme.wsOffsetX, offsetYFn: () => Theme.wsOffsetY
        },
        {
            key: "battery", component: batteryContent,
            shownFn: () => Battery.shown && Battery.available && Theme.batPlace === "left" && !root.hideIdleIcons,
            morphsFn: () => Theme.dashPower && Battery.available,
            sizeFn: () => Theme.h, contentWidthFn: () => Theme.batW + Theme.batNubGap + Theme.batNubW,
            offsetXFn: () => Theme.batteryOffsetX, offsetYFn: () => Theme.batteryOffsetY
        },
        {
            key: "wifi", component: wifiContent,
            shownFn: () => root.wifiShown && Theme.wifiPlace === "left" && !root.hideIdleIcons,
            morphsFn: () => Theme.dashNet,
            sizeFn: () => Theme.sigRowH, contentWidthFn: () => Theme.sigRowW,
            offsetXFn: () => Theme.wifiOffsetX, offsetYFn: () => Theme.wifiOffsetY
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
            key: "record", component: recordContent,
            shownFn: () => Record.active && Theme.recPlace === "right" && !root.hideIdleIcons,
            sizeFn: () => Theme.recordDot,
            offsetXFn: () => Theme.recordOffsetX, offsetYFn: () => Theme.recordOffsetY
        },
        {
            key: "mic", component: micContent,
            shownFn: () => Mic.muted && Theme.micPlace === "right" && !root.hideIdleIcons,
            sizeFn: () => Theme.micS,
            offsetXFn: () => Theme.micOffsetX, offsetYFn: () => Theme.micOffsetY
        },
        {
            key: "wifi", component: wifiContent,
            shownFn: () => root.wifiShown && Theme.wifiPlace === "right" && !root.hideIdleIcons,
            morphsFn: () => Theme.dashNet,
            sizeFn: () => Theme.sigRowH, contentWidthFn: () => Theme.sigRowW,
            offsetXFn: () => Theme.wifiOffsetX, offsetYFn: () => Theme.wifiOffsetY
        },
        {
            key: "battery", component: batteryContent,
            shownFn: () => Battery.shown && Battery.available && Theme.batPlace === "right" && !root.hideIdleIcons,
            morphsFn: () => Theme.dashPower && Battery.available,
            sizeFn: () => Theme.h, contentWidthFn: () => Theme.batW + Theme.batNubGap + Theme.batNubW,
            offsetXFn: () => Theme.batteryOffsetX, offsetYFn: () => Theme.batteryOffsetY
        },
        {
            key: "ws", component: wsRightContent,
            shownFn: () => root.wsRight && !root.hideIdleIcons,
            morphsFn: () => root.wsMorphs,
            sizeFn: () => Theme.h, contentWidthFn: () => Workspaces.span,
            clockGapFn: () => Theme.wsClockGap,
            offsetXFn: () => Theme.wsOffsetX, offsetYFn: () => Theme.wsOffsetY
        }
    ]

    Component {
        id: wsLeftContent
        WorkspaceStrip {
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            live: root.wsLeft && !root.hideIdleIcons
            vert: Workspaces.vertical
            layoutFade: Workspaces.layoutFade
            index: Workspaces.index
            count: Workspaces.count
            page: Workspaces.page
            filled: Workspaces.filled
        }
    }

    Component {
        id: wsRightContent
        WorkspaceStrip {
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            live: root.wsRight && !root.hideIdleIcons
            vert: Workspaces.vertical
            layoutFade: Workspaces.layoutFade
            index: Workspaces.index
            count: Workspaces.count
            page: Workspaces.page
            filled: Workspaces.filled
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
        id: wifiContent
        Sig {
            anchors.centerIn: parent
            level: Net.bars
            tint: Net.enabled ? Theme.fg : Theme.mix(Theme.bg, Theme.fg, Theme.dimMid)

            Behavior on tint {
                ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
            }
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
        { cond: () => islandPop.dashShown, w: () => Theme.dashW, h: () => dash.y + dash.height + Theme.dashPad },
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
                else
                    root.pop(islandPop.primary)
            }
        }

        TapHandler {
            acceptedButtons: Qt.MiddleButton
            onTapped: root.pop("dates")
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

        Dash {
            id: dash
            x: root.centerX(width)
            y: Theme.dashPad
            now: clock.date
            shown: islandPop.dashShown
            present: root.dashLive
            leaving: root.dashLeaving
            staged: root.dashStaged
            ready: root.islandReady
            t: root.morphT
            hands: root.idleClock
            live: root.dashFace && !root.resizing
            origins: root.dashOrigins
            originCy: root.idleRowCy
            focus: shown
            onShownChanged: if (shown) dash.forceActiveFocus()
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
            ready: root.panelReveal && note.settled
            rise: root.panelRise
        }

        LauncherMenu {
            id: launch
            x: root.centerX(width)
            y: Theme.lpad
            shown: Launcher.open
            ready: root.faceReady("launcher")
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
            ready: root.faceReady("net")
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
            ready: root.faceReady("bluetooth")
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

    Item {
        id: idleHost
        anchors.fill: parent
        visible: root.morphVeil > 0 || root.orphanVeil > 0
        z: 2

    Fade {
        id: idle
        x: body.x
        y: body.y + Theme.idleTopOffsetY + root.idleCenterDrop
        width: body.width
        height: Theme.h
        clip: true
        shown: root.idleRowActive
        ready: !wake.running
        rise: Theme.idleRise
        fall: Theme.idleFall
        scale: Theme.slotScale + (1 - Theme.slotScale) * idleScale.value

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
            x: root.idleX - body.x
            width: leftRow.width + clockSlot.width + rightRow.width
            height: parent.height
            spacing: 0

            IconRow {
                id: leftRow
                clockEnd: true
                modules: root.leftModules
                morphVeil: root.morphVeil
                orphanVeil: root.orphanVeil
            }

            Item {
                id: clockSlot
                readonly property real restW: root.wsOnly ? wsOnlyStrip.span : clockText.implicitWidth
                width: Math.ceil(Math.max(clockSlot.restW, vbars.width,
                    clockFade.visible ? clockText.implicitWidth : 0,
                    wsOnlyFade.visible ? wsOnlyStrip.span : 0))
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
                    shown: !root.slotVis && !root.wsOnly && root.idleSlotVisible
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

                    InkTxt {
                        id: clockText
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: Theme.clockText(clock.date)
                        font.pixelSize: Theme.clockPx
                        font.features: Theme.tabular
                        dx: Theme.clockOffsetX
                        opacity: root.morphVeil
                    }
                }

                Fade {
                    id: wsOnlyFade
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.alignWhenCentered: Theme.idleAlignWhenCentered
                    width: wsOnlyStrip.span
                    height: parent.height
                    shown: root.wsOnly && !root.slotVis && root.idleSlotVisible
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
                        veil: root.wsVeil
                        live: wsOnlyFade.shown
                        vert: Workspaces.vertical
                        layoutFade: Workspaces.layoutFade
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
                    shown: root.slotVis && root.idleSlotVisible
                    ready: root.idleHeld || (root.panelReveal && !swapGate.running)
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
                        opacity: root.orphanVeil
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
                morphVeil: root.morphVeil
                orphanVeil: root.orphanVeil
            }
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

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
import "../settings"
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

    Morph {
        id: morph
        face: root.dashFace
        bare: root.idleBare
        islandOpen: islandPop.open
        dashVisible: dash.visible
        visualizer: root.showVisualizer
        wsAvailable: Workspaces.available
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
    readonly property bool idleShowing: root.idleRowActive && (!root.panelOpen || root.mediaPanelShown)
    readonly property bool idleBare: root.idleRowActive && !root.panelOpen
    readonly property real idleRowCy: Theme.idleTopOffsetY + root.idleCenterDrop + Theme.h / 2
    readonly property bool showVisualizer: Visualizer.on || (root.mediaPeek && Theme.visPeek) || root.mediaPanelShown
    readonly property bool wifiShown: Theme.wifiOn && (Net.linkKnown || Net.available)
    readonly property bool wsAvailable: Theme.wsOn && Workspaces.available
    readonly property bool wsOnly: root.wsAvailable && Workspaces.place === "only"
    readonly property bool wsLeft: root.wsAvailable && Workspaces.place !== "only" && Workspaces.place !== "right"
    readonly property bool wsRight: root.wsAvailable && Workspaces.place === "right"
    readonly property bool idleRowActive: root.calm || root.islandOwn
    readonly property bool idleHeld: morph.morphing
    readonly property bool idleSlotVisible: root.idleHeld || root.idleShowing
    readonly property bool hideIdleIcons: !root.idleHeld && (!root.idleRowActive || root.panelOpen)
    readonly property bool slotVis: root.idleHeld ? morph.heldVis : root.showVisualizer
    readonly property bool idleClock: !root.slotVis && !root.wsOnly
    readonly property bool ringGeometryBase: root.calm && !root.hot && !root.hideIdleIcons
    readonly property bool ringBase: root.ringGeometryBase && Theme.batRingEnabled && Battery.ringShown && Battery.available
    readonly property bool resizing:
        Math.abs(root.wAnim - root.targetW) > Theme.settleEps && !root.arrived(wMotion) ||
        Math.abs(root.hAnim - root.targetH) > Theme.settleEps && !root.arrived(hMotion)
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
    readonly property real wAnim: wMotion.shaped
    readonly property real hAnim: hMotion.shaped

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
        morph.arm()
        islandPop.show(mode)
    }

    function showFace(name) {
        morph.arm()
        return islandPop.toggleFace(name)
    }

    readonly property real dashLeft: Theme.mid(root.width, dash.width)
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

    function idleWsHit(p) {
        if (!Theme.wsClick || !root.wsAvailable || root.alert || root.panelOpen || root.modal || root.idleHeld)
            return null
        const strips = [root.wsOnly ? wsOnlyStrip : null, leftRow.content("ws"), rightRow.content("ws")]
        for (const s of strips) {
            if (!s || !s.live)
                continue
            const q = body.mapToItem(s, p.x, p.y)
            if (q.x >= 0 && q.x <= s.width && q.y >= 0 && q.y <= s.height)
                return { strip: s, slot: s.slotAt(q.x) }
        }
        return null
    }

    readonly property var idleWsHot: hover.hovered ? root.idleWsHit(hover.point.position) : null

    function idleHotIn(s) {
        return root.idleWsHot && root.idleWsHot.strip === s ? root.idleWsHot.slot : -1
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

    readonly property var dashParts: ["workspaces", "date", "weekday", "notifications", "network", "bluetooth", "volume", "battery"]

    function dashKey(part) {
        return "dash" + ({
            workspaces: "Ws", date: "Date", weekday: "Weekday", notifications: "Notes",
            network: "Net", bluetooth: "Bt", volume: "Volume", battery: "Battery"
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

    property bool hidden: false
    readonly property bool tucked: root.hidden && !Modal.any && Notifs.current === null
    readonly property bool tucking: root.tucked || tuckMotion.moving

    IpcHandler {
        target: "bar"

        function toggle(): string {
            root.hidden = !root.hidden
            return root.hidden ? "hidden" : "shown"
        }

        function status(): string { return root.hidden ? "hidden" : "shown" }
    }

    Spring {
        id: tuckMotion
        target: root.tucked ? 1 : 0
        hold: Theme.springHold
        response: Theme.barResponse
        damping: Theme.barDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    opacity: root.tucked && !tuckMotion.moving ? 0 : 1
    transform: Translate { y: -tuckMotion.shaped * (yMotion.value + root.hAnim + Theme.barClear) }

    readonly property bool islandReady: !stage.running

    Component.onCompleted: {
        sync()
        Modal.register("island", islandPop)
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
        value: Theme.wifiOn && Net.available
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property real idleRowW: leftRow.targetWidth + clockSlot.wantW + rightRow.targetWidth

    function modulesFor(side) {
        const on = (ok, place) => ok && place === side && !root.hideIdleIcons
        const list = [
            {
                key: "ws", component: side === "left" ? wsLeftContent : wsRightContent,
                shownFn: () => (side === "left" ? root.wsLeft : root.wsRight) && !root.hideIdleIcons,
                morphsFn: () => morph.wsMorphs,
                sizeFn: () => Theme.h, contentWidthFn: () => Workspaces.span,
                clockGapFn: () => Theme.wsClockGap,
                offsetXFn: () => Theme.wsOffsetX, offsetYFn: () => Theme.wsOffsetY
            },
            {
                key: "battery", component: batteryContent,
                shownFn: () => on(Battery.shown && Battery.available, Theme.batPlace),
                morphsFn: () => Theme.dashBattery && Battery.available,
                sizeFn: () => Theme.h, contentWidthFn: () => Theme.batW + Theme.batNubGap + Theme.batNubW,
                offsetXFn: () => Theme.batteryOffsetX, offsetYFn: () => Theme.batteryOffsetY
            },
            {
                key: "wifi", component: wifiContent,
                shownFn: () => on(root.wifiShown, Theme.wifiPlace),
                morphsFn: () => Theme.dashNet,
                sizeFn: () => Theme.sigRowH, contentWidthFn: () => Theme.sigRowW,
                offsetXFn: () => Theme.wifiOffsetX, offsetYFn: () => Theme.wifiOffsetY
            },
            {
                key: "mic", component: micContent,
                shownFn: () => on(Mic.muted, Theme.micPlace),
                sizeFn: () => Theme.micS,
                offsetXFn: () => Theme.micOffsetX, offsetYFn: () => Theme.micOffsetY
            },
            {
                key: "record", component: recordContent,
                shownFn: () => on(Record.active, Theme.recPlace),
                sizeFn: () => Theme.recordDot,
                offsetXFn: () => Theme.recordOffsetX, offsetYFn: () => Theme.recordOffsetY
            }
        ]
        return side === "left" ? list : list.reverse()
    }

    readonly property var leftModules: root.modulesFor("left")
    readonly property var rightModules: root.modulesFor("right")

    Component {
        id: wsLeftContent
        WsModule {
            id: leftStrip
            x: (parent.width - width) / 2
            y: Theme.mid(parent.height, height)
            hot: root.idleHotIn(leftStrip)
            live: root.wsLeft && !root.hideIdleIcons
        }
    }

    Component {
        id: wsRightContent
        WsModule {
            id: rightStrip
            x: (parent.width - width) / 2
            y: Theme.mid(parent.height, height)
            hot: root.idleHotIn(rightStrip)
            live: root.wsRight && !root.hideIdleIcons
        }
    }

    Component {
        id: batteryContent
        BatteryModule {}
    }

    Component {
        id: wifiContent
        WifiModule {
            anchors.centerIn: parent
            tint: Net.enabled ? Theme.accent : Theme.mix(Theme.bg, Theme.accent, Theme.dimMid)

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

    readonly property var panels: [auth, note, launch, power, wall, rec, shot, net, mixer, bt, trayCtx, tray, center, cal, strip, tune, dash]
    readonly property Item activePanel: root.panels.find(p => p.shown) || null

    function centerX(w) {
        return Theme.mid(root.width, w) - body.x
    }

    readonly property real wantW: root.activePanel ? root.activePanel.wantW
        : islandPop.popped ? root.idleTargetW + Theme.islandPopW
        : root.calm ? root.idleTargetW : Theme.w

    readonly property real wantH: root.activePanel ? root.activePanel.wantH
        : islandPop.popped ? Theme.h + Theme.islandPopH
        : Theme.h

    property bool panelMotion: false
    readonly property bool idleSettled: root.activePanel === null && !wMotion.moving && !hMotion.moving

    onActivePanelChanged: if (root.activePanel !== null) root.panelMotion = true
    onIdleSettledChanged: if (root.idleSettled) root.panelMotion = false

    readonly property real roomW: root.activePanel ? 2 * (root.activePanel.padX || 0) : 0
    readonly property real roomH: root.activePanel ? root.activePanel.padBottom || 0 : 0

    function bounces(m, room) {
        return Theme.menuBounce && root.panelMotion
            && (root.activePanel === null || m.target > m.origin || Theme.menuSwitchDip && room > 0)
    }

    function arrived(m) {
        return m.crossed && (m.target > m.origin || m.peak !== 0)
    }

    function reach(m, room) {
        if (m.target > m.origin)
            return Theme.menuBounceReach
        const dip = Math.min(Theme.menuBounceReach, m.target * Theme.menuBounceDip)
        return root.activePanel === null ? dip : Math.min(dip, room)
    }

    readonly property real idleCenterDrop: dropMotion.value
    readonly property real bodyDrop: Theme.gap + (islandPop.popped ? Theme.islandPopDrop : 0)

    Spring {
        id: wMotion
        target: root.targetW
        hold: Theme.springHold
        response: root.bounces(wMotion, root.roomW) ? Theme.menuBounceResponse : Theme.islandResponse
        damping: root.bounces(wMotion, root.roomW) ? Theme.menuBounceDamping : Theme.islandDamping
        reach: root.reach(wMotion, root.roomW)
        epsilon: Theme.settleEps
    }

    Spring {
        id: hMotion
        target: root.targetH
        hold: Theme.springHold
        response: root.bounces(hMotion, root.roomH) ? Theme.menuBounceResponse : Theme.islandResponse
        damping: root.bounces(hMotion, root.roomH) ? Theme.menuBounceDamping : Theme.islandDamping
        reach: root.reach(hMotion, root.roomH)
        epsilon: Theme.settleEps
    }

    Spring {
        id: noteFlat
        target: note.wantW
        hold: Theme.dashMorphHold
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

    readonly property int cornerCap: Launcher.open ? Theme.launchRadius : Theme.radius
    readonly property real skinRadius: Math.min(Math.min(skin.width, skin.height) / 2, root.cornerCap)

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
        x: Theme.mid(root.width, width)
        y: Math.round(yMotion.value)
        width: Math.round(root.wAnim)
        height: Math.round(root.hAnim)
        radius: Math.min(Math.min(width, height) / 2, root.cornerCap)
        antialiasing: true
        color: "transparent"
        Component.onCompleted: body.contentItem.transform = [bodyShift]

        Translate {
            id: bodyShift
            y: yMotion.value - body.y
        }

        HoverHandler {
            id: hover
            cursorShape: root.idleWsHot ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        TapHandler {
            onTapped: p => {
                if (root.alert) {
                    Notifs.dismiss()
                    return
                }
                const hit = root.idleWsHit(p.position)
                if (hit) {
                    Workspaces.focus(hit.slot + 1)
                    return
                }
                root.pop(islandPop.primary)
            }
        }

        TapHandler {
            acceptedButtons: Qt.MiddleButton
            onTapped: {
                if (islandPop.dashShown) {
                    Settings.open = true
                    return
                }
                root.pop("dates")
            }
        }

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: {
                if (root.alert) {
                    Notifs.focusCurrent()
                    return
                }
                if (islandPop.dashShown) {
                    if (root.media) {
                        morph.arm()
                        islandPop.go("home", 2)
                    }
                    return
                }
                if (islandPop.mediaShown) {
                    morph.arm()
                    islandPop.go("home", 1)
                    return
                }
                if (!root.modal)
                    Tray.toggle()
            }
        }

        Week {
            id: strip
            x: root.centerX(width)
            pad: Theme.islandWeekPad
            padX: 0
            now: root.clockNow
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
            now: root.clockNow
            shown: islandPop.dashShown
            present: morph.live
            leaving: morph.leaving
            staged: morph.staged
            ready: root.islandReady
            t: morph.t
            tFlat: morph.tFlat
            hands: root.idleClock
            live: root.dashFace && !root.resizing
            morphs: morph.runs
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
            padX: Theme.islandMediaPad
            padBottom: Theme.islandMediaPad
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
            pad: Theme.islandCalPad
            now: root.clockNow
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
            n: Notifs.current
            expanded: root.hot
            width: noteFlat.shaped
            sized: !root.resizing
            shown: root.alert
            ready: root.faceReady("note") && note.settled
            rise: root.panelRise
        }

        LauncherMenu {
            id: launch
            x: root.centerX(width)
            shown: Launcher.open
            ready: root.faceReady("launcher")
            rise: root.panelRise
        }

        PowerMenu {
            id: power
            x: root.centerX(width)
            shown: Power.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        WallpaperMenu {
            id: wall
            x: root.centerX(width)
            shown: Wallpaper.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        RecordMenu {
            id: rec
            x: root.centerX(width)
            shown: Record.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        ScreenshotMenu {
            id: shot
            x: root.centerX(width)
            shown: Screenshot.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        NetMenu {
            id: net
            x: root.centerX(width)
            shown: Net.open
            ready: root.faceReady("net")
            rise: root.panelRise
        }

        MixerMenu {
            id: mixer
            x: root.centerX(width)
            shown: Mixer.open
            ready: root.panelReveal
            rise: root.panelRise
        }

        BtMenu {
            id: bt
            x: root.centerX(width)
            shown: Bt.open
            ready: root.faceReady("bluetooth")
            rise: root.panelRise
        }

        TrayMenu {
            id: tray
            x: root.centerX(width)
            shown: Tray.open && !Tray.menuItem
            ready: root.panelReveal
            rise: root.panelRise
        }

        TrayContextMenu {
            id: trayCtx
            x: root.centerX(width)
            shown: Tray.open && !!Tray.menuItem
            ready: root.panelReveal && trayCtx.settled
            rise: root.panelRise
        }

        Center {
            id: center
            x: root.centerX(width)
            shown: Notifs.open
            ready: root.panelReveal && center.settled
            rise: root.panelRise
        }

        Auth {
            id: auth
            x: root.centerX(width)
            shown: Polkit.open
            ready: root.panelReveal
            rise: root.panelRise
        }
    }

    Item {
        id: idleHost
        anchors.fill: parent
        visible: morph.veil > 0 || morph.orphanVeil > 0
        z: 2

    Fade {
        id: idle
        x: body.x
        y: yMotion.value + Theme.idleTopOffsetY + root.idleCenterDrop
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
                morphVeil: morph.veil
                orphanVeil: morph.orphanVeil
            }

            Item {
                id: clockSlot
                readonly property real restW: root.wsOnly ? wsOnlyStrip.span : clockText.implicitWidth
                readonly property real wantW: Math.ceil(Math.max(clockSlot.restW, vbars.width,
                    clockFade.visible ? clockText.implicitWidth : 0,
                    wsOnlyFade.visible ? wsOnlyStrip.span : 0))
                width: slotMotion.value
                height: parent.height

                Spring {
                    id: slotMotion
                    target: clockSlot.wantW
                    response: Theme.idlePopResponse
                    damping: Theme.idlePopDamping
                    epsilon: Theme.settleEps
                }

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

                    RollTxt {
                        id: clockText
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: Theme.clockText(root.clockNow)
                        color: Theme.clockInk
                        font.pixelSize: Theme.clockPx
                        font.features: Theme.tabular
                        dx: Theme.clockOffsetX
                        opacity: morph.veil
                    }
                }

                Fade {
                    id: wsOnlyFade
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.alignWhenCentered: Theme.idleAlignWhenCentered
                    width: wsOnlyStrip.width
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

                    WsModule {
                        id: wsOnlyStrip
                        anchors.centerIn: parent
                        hot: root.idleHotIn(wsOnlyStrip)
                        veil: morph.wsVeil
                        live: wsOnlyFade.shown
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
                        opacity: morph.orphanVeil
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
                morphVeil: morph.veil
                orphanVeil: morph.orphanVeil
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
        anchors.fill: skin
        shown: root.ringBase
        ready: !ringSettle.running
        rise: Theme.batRingRise
        fall: Theme.batRingFall
        z: 4

        BatteryRing {
            anchors.centerIn: parent
            pillW: skin.width
            pillH: skin.height
            pillRadius: root.skinRadius
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

    readonly property date clockNow: clock.date
}

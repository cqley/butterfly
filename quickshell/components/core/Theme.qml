pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // core
    readonly property string screen: cfg("screen", "HDMI-A-1")
    readonly property var shellScreens: {
        const m = Quickshell.screens.filter(s => s.name === root.screen)
        return m.length ? m : Quickshell.screens.slice(0, 1)
    }
    readonly property string shellScreen: shellScreens.length ? shellScreens[0].name : ""
    readonly property string font: "Inter"
    readonly property real fontScale: cfg("fontScale", 1)
    readonly property var tabular: ({ "tnum": 1 })
    readonly property int fsXXS: fs(9)
    readonly property int fsXS: fs(10)
    readonly property int fsS: fs(11)
    readonly property int fsM: fs(12)
    readonly property int fsL: fs(13)
    readonly property int fsXL: fs(14)

    function fs(px) {
        return Math.max(1, Math.round(px * fontScale))
    }

    function inner(outer, inset) {
        return Math.max(0, outer - inset)
    }

    function mid(outer, size) {
        return Math.round((outer - size) / 2)
    }

    function cfg(key, fallback) {
        Cfg.remember(key, fallback)
        const store = Cfg.v
        const x = store ? store[key] : undefined
        return x === undefined || x === null ? fallback : x
    }

    readonly property var terminal: ["sh", "-c", 'for t in "$TERMINAL" alacritty kitty foot ghostty wezterm xterm; do command -v "$t" >/dev/null 2>&1 || continue; case $t in kitty) exec kitty "$@";; wezterm) exec wezterm start -- "$@";; *) exec "$t" -e "$@";; esac; done', "sh"]
    readonly property int imageRetry: 200
    readonly property string stampFormat: "yy-MM-dd_HH-mm-ss"

    function pctOrUnavailable(ready, pct, suffix) {
        return ready ? Math.round(pct * 100) + "%" + (suffix || "") : "unavailable"
    }

    function stableReorder(items, prevOrder, keyFn, cmp) {
        const pos = Object.create(null)
        for (let i = 0; i < prevOrder.length; i++)
            pos[prevOrder[i]] = i
        const kept = []
        const fresh = []
        for (const it of items) {
            if (pos[keyFn(it)] === undefined)
                fresh.push(it)
            else
                kept.push(it)
        }
        kept.sort((a, b) => pos[keyFn(a)] - pos[keyFn(b)])
        fresh.sort(cmp)
        const out = kept.concat(fresh)
        return { order: out.map(keyFn), items: out }
    }

    function url(path) {
        const value = String(path || "")
        if (value === "" || /^[a-z][a-z0-9+.-]*:/i.test(value))
            return value
        return "file://" + value.split("/").map(encodeURIComponent).join("/")
    }

    function dir(path, fallback) {
        const value = String(path || "").trim()
        if (value === "")
            return fallback
        const abs = value.charAt(0) === "~" ? Quickshell.env("HOME") + value.slice(1) : value
        return abs.length > 1 && abs.charAt(abs.length - 1) === "/" ? abs.slice(0, -1) : abs
    }

    function tilde(path) {
        return String(path || "").replace(Quickshell.env("HOME"), "~")
    }

    // colors
    property var pal: null
    readonly property color bgAuto: pal && pal.special ? pal.special.background : "#000000"
    readonly property string primaryOverride: cfg("primary", "")
    readonly property color bg: isHex(primaryOverride) ? primaryOverride : bgAuto
    readonly property color fg: pal && pal.special ? pal.special.foreground : "#ffffff"
    readonly property color chip: mix(bg, fg, 0.11)
    readonly property color tile: mix(bg, fg, 0.172)
    readonly property color accentAuto: pal && pal.special && pal.special.accent ? pal.special.accent : "#f2b8e2"
    readonly property string accentOverride: cfg("accent", "")
    readonly property color accent: isHex(accentOverride) ? accentOverride : accentAuto
    readonly property bool whiteKnobs: cfg("whiteKnobs", true)
    readonly property bool whiteClock: cfg("whiteClock", true)
    readonly property color knobInk: whiteKnobs ? white : accent
    readonly property color clockInk: whiteClock ? white : fg
    readonly property bool whiteText: cfg("whiteText", true)
    readonly property color settingsInk: whiteText ? white : fg
    readonly property var primarySwatches: [bgAuto, "#000000", "#0d0d0f", "#17171a", "#202024", "#141a22", "#1c1526", "#101c17"]
    readonly property var accentSwatches: [accentAuto, "#de8383", "#f2be8c", "#eef27c", "#bdfcc4", "#a3e4e8", "#9cb4d9", "#f2b8e2"]

    function onTone(c) {
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b > 0.5 ? "#000000" : "#ffffff"
    }

    function isHex(s) {
        return /^#[0-9a-fA-F]{6}$/.test(String(s || ""))
    }
    readonly property color white: "#ffffff"
    readonly property color red: "#e5534b"
    readonly property color redSoft: mix(red, white, 0.35)
    readonly property color green: "#34c759"
    readonly property color greenSoft: mix(green, white, 0.35)

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
    }

    FileView {
        path: Quickshell.env("HOME") + "/.colors/colors.json"
        preload: true
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: root.pal = null
        onLoaded: {
            try {
                root.pal = JSON.parse(text())
            } catch (e) {
                root.pal = null
            }
        }
    }

    // motion
    readonly property int speed: cfg("speed", 300)
    readonly property int fade: 60
    readonly property int rise: speed
    readonly property int fall: fade
    readonly property int swapRise: rise
    readonly property int idleRise: speed
    readonly property int idleFall: fade
    readonly property int idleWait: 0
    readonly property bool holdPill: false
    readonly property bool holdPanels: true
    readonly property bool blockSwap: false
    readonly property int glide: cfg("glide", 240)
    readonly property int fast: 60
    readonly property int feedbackDuration: 120
    readonly property real feedbackHoverScale: 1.03
    readonly property real feedbackPressScale: 0.97
    readonly property real feedbackFocusBorder: 1
    readonly property int ease: Easing.OutCubic
    readonly property real springResponse: cfg("springResponse", 0.26)
    readonly property real springDamping: cfg("springDamping", 1)
    readonly property real springEps: 0.1
    readonly property real springStop: 3
    readonly property real springUnitEps: 0.002
    readonly property real springUnitStop: 0.05
    readonly property real springMaxFrame: 1 / 30
    readonly property real springHold: 0.01
    readonly property real springSettle: 0.5
    readonly property real springMatch: 0.866
    readonly property real feedbackResponse: springFor(feedbackDuration)
    readonly property real glideResponse: springFor(glide)
    readonly property real speedResponse: springFor(speed)
    readonly property int pulse: 1400

    function springFor(ms) {
        return ms / 1000 * root.springMatch
    }

    function scaleSettle(size) {
        return 2 * root.springSettle / Math.max(1, size)
    }

    function turnSettle(size) {
        return root.scaleSettle(size) * 180 / Math.PI
    }
    readonly property real settleEps: 0.5

    // dim & opacity
    readonly property real dimHint: 0.35
    readonly property real dimGhost: 0.4
    readonly property real dimEmpty: 0.45
    readonly property real dimMid: 0.5
    readonly property real dimMuted: 0.55
    readonly property real dimSoft: 0.6
    readonly property real dotLow: 0.65

    // icons
    readonly property int iconGrid: 24
    readonly property real iconStroke: 1.8

    function glyphStroke(size, base) {
        const w = base || iconStroke
        return size < iconGrid ? w * iconGrid / size : w
    }

    function roundRectPath(w, h, radius) {
        const r = Math.max(0, Math.min(radius, Math.min(w, h) / 2))
        if (r <= 0)
            return "M0 0H" + w + "V" + h + "H0Z"
        const a = "A" + r + " " + r + " 0 0 1 "
        let p = "M" + r + " 0"
        if (w > 2 * r)
            p += "H" + (w - r)
        p += a + w + " " + r
        if (h > 2 * r)
            p += "V" + (h - r)
        p += a + (w - r) + " " + h
        if (w > 2 * r)
            p += "H" + r
        p += a + "0 " + (h - r)
        if (h > 2 * r)
            p += "V" + r
        return p + a + r + " 0Z"
    }

    function capsulePath(w, h) {
        return roundRectPath(w, h, Math.min(w, h) / 2)
    }
    readonly property real btnStroke: 5
    readonly property color mediaIconColor: "#ffffff"
    readonly property string lockGlyphPath: "M5 11H19A2 2 0 0 1 21 13V20A2 2 0 0 1 19 22H5A2 2 0 0 1 3 20V13A2 2 0 0 1 5 11ZM7 11V7A5 5 0 0 1 17 7V11"

    // lists
    readonly property int selInset: 4
    readonly property int selGap: 2
    readonly property color selFill: Qt.rgba(1, 1, 1, 0.06)
    readonly property int surfaceBorderWidth: 1
    readonly property color surfaceBorder: Qt.rgba(1, 1, 1, 0.16)
    readonly property color surfaceBorderHover: Qt.rgba(1, 1, 1, 0.34)
    readonly property int selDuration: feedbackDuration
    readonly property int listGap: 6
    readonly property int rowX: 18
    readonly property int rowR: 14
    readonly property int rowTextY: 0
    readonly property int rowGap: 8
    readonly property int emptyPad: 8

    // pill
    readonly property int gap: cfg("gap", 6)
    readonly property int pad: cfg("pad", 16)
    readonly property int w: cfg("w", 64)
    readonly property int h: cfg("h", 28)
    readonly property int radius: cfg("radius", 28)
    readonly property int pillBorderWidth: 1
    readonly property real pillBorderOpacity: 0.08
    readonly property int pillHaloWidth: 1
    readonly property real pillHaloOpacity: 0.18
    readonly property int pillHaloSpread: 1
    readonly property int zone: gap + h

    // shadow
    readonly property bool shadowOn: cfg("shadowOn", true)
    readonly property color shadowColor: "#000000"
    readonly property real shadowOpacity: cfg("shadowOpacity", 0.42)
    readonly property int shadowBlur: cfg("shadowBlur", 30)
    readonly property int shadowSpread: cfg("shadowSpread", 0)
    readonly property int shadowOffsetY: cfg("shadowOffsetY", 4)
    readonly property real shadowContact: cfg("shadowContact", 0.6)
    readonly property int shadowContactBlur: 4
    readonly property int shadowContactOffsetY: 1

    // bar
    readonly property real barResponse: islandResponse
    readonly property real barDamping: islandDamping
    readonly property int barClear: shadowBlur + shadowOffsetY + pillHaloSpread
    readonly property bool barFreesZone: true

    // idle row
    readonly property int clockPx: fs(cfg("clockPx", 14))
    readonly property string clockFormat: cfg("clockFormat", "HH:mm")

    function clockText(date) {
        if (clockFormat !== "hh:mm")
            return Qt.formatDateTime(date, clockFormat)
        const h = date.getHours() % 12 || 12
        const m = date.getMinutes()
        return h + ":" + (m < 10 ? "0" + m : m)
    }
    readonly property int idleOffsetX: 0
    readonly property int idleOffsetY: 0
    readonly property int idleTopOffsetY: 0
    readonly property int clockOffsetX: 0
    readonly property int clockOffsetY: 0
    readonly property int clockRoll: 480
    readonly property real clockRollLift: 0.9
    readonly property real clockRollBand: 1.05
    readonly property real clockRollBlur: 0.55
    readonly property int clockRollBlurMax: 12
    readonly property int clockRollCells: 8
    readonly property int moduleOffsetY: 0
    readonly property bool idleAlignWhenCentered: true
    readonly property int batteryOffsetX: 0
    readonly property int batteryOffsetY: 0
    readonly property int micOffsetX: 0
    readonly property int micOffsetY: 0
    readonly property int recordOffsetX: 0
    readonly property int recordOffsetY: 0
    readonly property int clockGap: cfg("clockGap", 8)
    readonly property real idlePopResponse: springResponse
    readonly property real idlePopDamping: springDamping
    readonly property real slotScale: 0.7
    readonly property real slotExitAt: 0.75
    readonly property bool wifiOn: cfg("wifiOn", false)
    readonly property string wifiPlace: cfg("wifiPlace", "right")
    readonly property int wifiOffsetX: 0
    readonly property int wifiOffsetY: 0
    readonly property string batPlace: cfg("batPlace", "right")
    readonly property string micPlace: cfg("micPlace", "right")
    readonly property string recPlace: cfg("recPlace", "right")

    // workspaces
    readonly property bool wsOn: cfg("wsOn", false)
    readonly property string wsPlace: cfg("wsPlace", "left")
    readonly property bool wsVertical: cfg("wsVertical", false)
    readonly property bool wsAccent: cfg("wsAccent", true)
    readonly property bool wsClick: cfg("wsClick", false)
    readonly property real wsHotLift: 0.45
    readonly property int wsCountMax: 5
    readonly property int wsCount: Math.min(cfg("wsCount", 5), wsCountMax)
    readonly property int wsGap: cfg("wsGap", 8)
    readonly property int wsPad: cfg("wsPad", 7)
    readonly property int wsClockGap: cfg("wsClockGap", 11)
    readonly property real wsDotDim: cfg("wsDotDim", 0.3)
    readonly property real wsDotLive: cfg("wsDotLive", 0.62)
    readonly property int wsDot: cfg("wsDot", 4)
    readonly property int wsActiveW: cfg("wsActiveW", 18)
    readonly property int wsActiveH: cfg("wsActiveH", 6)
    readonly property int wsBarW: cfg("wsBarW", 6)
    readonly property int wsBarH: cfg("wsBarH", 10)
    readonly property int wsBarActiveW: cfg("wsBarActiveW", 8)
    readonly property int wsBarActiveH: cfg("wsBarActiveH", 16)
    readonly property int wsBarGap: cfg("wsBarGap", 5)
    readonly property real wsResponse: springResponse
    readonly property real wsDamping: springDamping
    readonly property real wsSpread: cfg("wsSpread", 0.3)
    readonly property int wsSpreadCap: 8
    readonly property int wsMax: 24
    readonly property int wsBleed: 2
    readonly property int wsSwap: cfg("wsSwap", 150)
    readonly property int wsOffsetX: 0
    readonly property int wsOffsetY: 0

    // battery
    readonly property int batW: 18
    readonly property int batH: 10
    readonly property real batRadius: 3
    readonly property int batNubW: 2
    readonly property int batNubH: 4
    readonly property int batNubGap: 1
    readonly property int batFillMin: 2
    readonly property real batTrack: 0.3
    readonly property int batBoltW: 9
    readonly property int batBoltH: 12
    readonly property string batBoltPath: "M5.66 0L1.2 6.7H3.94L2.91 12L7.37 5.3H4.63Z"
    readonly property real batGlyphStroke: 1.4
    readonly property real batGlyphSoften: 0.9
    readonly property real batBoltYOffset: 0.1
    readonly property color batBoltColor: accent
    readonly property color batBoltOutline: bg
    readonly property real batBoltScale: 0.75
    readonly property real batBoltResponse: springResponse
    readonly property real batBoltDamping: springDamping
    readonly property color batRed: "#ff3b30"
    readonly property color batYellow: "#ffcc00"
    readonly property color batOk: accent
    readonly property real batRedAt: cfg("batRedAt", 0.15)
    readonly property real batYellowAt: cfg("batYellowAt", 0.25)
    readonly property bool batOn: cfg("batOn", true)
    readonly property bool batRingEnabled: cfg("batRingEnabled", true)
    readonly property real batRingWidth: cfg("batRingWidth", 2.0)
    readonly property int batRingGap: 0
    readonly property color batRingTrack: Qt.rgba(accent.r, accent.g, accent.b, 0.22)
    readonly property int batRingRise: idleRise
    readonly property int batRingFall: 0

    function batTone(pct) {
        return pct <= batRedAt ? batRed : pct <= batYellowAt ? batYellow : batOk
    }

    // notifications
    readonly property int noteW: cfg("noteW", 264)
    readonly property int noteH: 48
    readonly property int noteOpenW: 300
    readonly property int noteTop: (noteH - noteIcon) / 2
    readonly property int noteIcon: 28
    readonly property int noteIconR: 14
    readonly property int noteIconX: 10
    readonly property int noteTextGap: 10
    readonly property int noteTextRight: 14
    readonly property int noteBodyLines: cfg("noteBodyLines", 1)
    readonly property int noteOpenBodyLines: 3
    readonly property int noteLineGap: 1
    readonly property real noteSigScale: 0.8
    readonly property int noteBtGlyph: 16
    readonly property real noteBatScale: 0.88
    readonly property int noteBtBadge: 18
    readonly property real noteBtRingWidth: 1.5
    readonly property color noteBtTrack: Qt.rgba(green.r, green.g, green.b, 0.22)
    readonly property int noteMoonGlyph: 15
    readonly property int noteShotGlyph: 16
    readonly property int noteRecGlyph: 18
    readonly property int dwell: cfg("dwell", 5000)
    readonly property int dwellCritical: cfg("dwellCritical", 10000)
    readonly property int dwellMax: 15000
    readonly property int dwellMin: 500
    readonly property int dwellNever: 5000
    readonly property int notificationQueueMax: 32
    readonly property int notificationHistoryMax: cfg("notificationHistoryMax", 50)

    // notification center
    readonly property int centerW: 320
    readonly property int centerPad: 14
    readonly property int centerHeadH: 28
    readonly property int centerBtn: 28
    readonly property int centerBtnGap: 8
    readonly property int centerGlyph: 15
    readonly property int centerRowH: 56
    readonly property int centerRows: cfg("centerRows", 3)
    readonly property int centerAxis: selInset + (centerRowH - selGap) / 2
    readonly property int centerIconX: centerAxis - noteIcon / 2
    readonly property int centerHeadInset: centerAxis - centerBtn / 2
    readonly property int centerDot: 8
    readonly property int centerDotRight: centerAxis - centerDot / 2
    readonly property int centerTextGap: 10
    readonly property int centerDotGap: 10
    readonly property int centerLineGap: 2
    readonly property int centerFresh: 180000
    readonly property int centerTick: 1000
    readonly property int centerBodyLines: 2
    readonly property int centerEmptyH: 72
    readonly property int centerEmptyGlyph: 32
    readonly property color centerEmptyTone: mix(bg, fg, dimHint)
    readonly property string bellPath: "M18 8.5A6 6 0 0 0 6 8.5C6 15 3 17 3 17H21S18 15 18 8.5Z"
    readonly property string bellClapperPath: "M13.7 20.5A2 2 0 0 1 10.3 20.5"
    readonly property string trashPath: "M3.5 6.5H20.5 M18.5 6.5V19.5A2 2 0 0 1 16.5 21.5H7.5A2 2 0 0 1 5.5 19.5V6.5 M9 6.5V4.5A2 2 0 0 1 11 2.5H13A2 2 0 0 1 15 4.5V6.5"
    readonly property string moonPath: "M21 12.8A9 9 0 1 1 11.2 3A7 7 0 0 0 21 12.8Z"
    readonly property color dndTone: "#ff9f0a"
    readonly property color dndToneHover: mix(dndTone, white, 0.16)
    readonly property color dndGlyph: white

    // launcher
    readonly property int launchW: cfg("launchW", 340)
    readonly property int launchRadius: 24
    readonly property int lpad: 8
    readonly property int rowH: cfg("rowH", 38)
    readonly property int rows: cfg("rows", 5)
    readonly property int searchH: 32
    readonly property real launchSearchOpacity: 0.22
    readonly property real launchSearchFocusOpacity: 0.42
    readonly property int launchSearchIconX: 12
    readonly property int launchSearchIconBox: 16
    readonly property real launchSearchIconOpacity: 0.62
    readonly property real launchSearchIconBorder: 1.3
    readonly property int launchSearchLensInset: 1
    readonly property int launchSearchLensSize: 10
    readonly property int launchSearchHandleX: 9
    readonly property int launchSearchHandleY: 9
    readonly property int launchSearchHandleW: 5
    readonly property real launchSearchHandleH: 1.3
    readonly property int launchSearchHandleRot: 45
    readonly property int launchSearchTextX: 40
    readonly property int launchSearchTextRight: 12
    readonly property int launchIconX: 10
    readonly property int launchIconBox: 24
    readonly property int launchIconSize: cfg("launchIconSize", 16)
    readonly property int launchIconSourceSize: 32
    readonly property int launchIconRadius: 10
    readonly property int launchIconBorderWidth: surfaceBorderWidth
    readonly property real launchIconSelectedScale: 1.02
    readonly property color launchIconFill: Qt.rgba(chip.r, chip.g, chip.b, 0.36)
    readonly property color launchIconSelectedFill: chip
    readonly property color launchIconBorder: surfaceBorder
    readonly property color launchIconHoverBorder: surfaceBorderHover
    readonly property int launchTextGap: 10
    readonly property int launchTextRowGap: 1
    readonly property int launchFallbackPx: fs(10)

    // tile menus (power, recording, screenshot)
    readonly property int pwW: 68
    readonly property int pwH: 66
    readonly property int pwGap: 8
    readonly property int pwPad: 10
    readonly property int pwN: 5
    readonly property int powerW: pwW * pwN + pwGap * (pwN - 1) + pwPad * 2
    readonly property string pwSuspendPath: "M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"
    readonly property string pwLogoutPath: "M9 21H5A2 2 0 0 1 3 19V5A2 2 0 0 1 5 3H9M16 17L21 12L16 7M21 12L9 12"
    readonly property string pwRebootPath: "M23 4L23 10L17 10M20.49 15a9 9 0 1 1-2.12-9.36L23 10"
    readonly property string pwOffPath: "M18.36 6.64a9 9 0 1 1-12.73 0M12 2L12 12"

    // wallpaper
    readonly property string wallPath: dir(cfg("wallPath", ""), Quickshell.env("HOME") + "/pictures/wallpaper")
    readonly property string wallPathShort: tilde(wallPath)
    readonly property string wallDir: url(wallPath)
    readonly property var wallCmd: [Quickshell.shellPath("components/core/scripts/colors.sh")]
    readonly property int wallPad: 16
    readonly property int thumbW: 132
    readonly property int thumbH: 75
    readonly property int thumbGap: 12
    readonly property int wallFocusGap: 7
    readonly property int wallN: 5
    readonly property int wallPreload: 5
    readonly property int wallTrackH: thumbH + 22
    readonly property int wallRadius: 9
    readonly property int wallRing: 1
    readonly property int wallBleed: 1
    readonly property color wallIdleBorder: surfaceBorder
    readonly property int wallVelocity: 600
    readonly property int wallCatchup: 20
    readonly property int wallCatchupSteps: 3
    readonly property int wallRetries: 2
    readonly property int wallSourceW: thumbW * 2
    readonly property int wallSourceH: thumbH * 2
    readonly property real wallFocusScale: 1.15
    readonly property int wallW: thumbW * wallN + thumbGap * (wallN - 1) + wallFocusGap * 2 + wallPad * 2

    // auth
    readonly property int authW: 340
    readonly property int authPad: 16
    readonly property int authFieldH: 38
    readonly property int authFieldR: 12
    readonly property int authBtnH: 38
    readonly property int authIcon: 36
    readonly property int authSpacing: 12
    readonly property int authHeadGap: 12
    readonly property int authHeadTextGap: 3
    readonly property int authTitleH: 16
    readonly property int authMsgLines: 3
    readonly property int authStatusGap: 6
    readonly property int authStatusH: 13
    readonly property real authLockShut: 11
    readonly property real authLockOpen: 6
    readonly property string authShackleHead: "M7 11V7A5 5 0 0 1 17 7V"
    readonly property int authLockGlide: 260
    readonly property int authBtnGap: 8
    readonly property int authGlyph: 18
    readonly property int authIconR: 12
    readonly property int authFieldTextX: 14
    readonly property int authDots: 3
    readonly property int authDotS: 4
    readonly property int authDotGap: 4
    readonly property int authDotStep: 260
    readonly property int authDotStagger: 130
    readonly property string authBodyPath: "M5 11H19A2 2 0 0 1 21 13V20A2 2 0 0 1 19 22H5A2 2 0 0 1 3 20V13A2 2 0 0 1 5 11Z"
    readonly property string authCrossPath: "M6.5 6.5L17.5 17.5M17.5 6.5L6.5 17.5"
    readonly property int authShake: 6
    readonly property int authShakeStep: 35
    readonly property real authPressed: 0.82
    readonly property real authDisabled: 0.45
    readonly property string passChar: "•"

    // media
    readonly property int mediaPillW: cfg("mediaPillW", 324)
    readonly property int mediaW: mediaPillW - 2 * pad
    readonly property int mediaGap: 12
    readonly property int artS: cfg("artS", 88)
    readonly property int ctlS: 30
    readonly property int playS: 30
    readonly property int glyphS: 20
    readonly property int playGlyph: 23
    readonly property int barH: 5
    readonly property int mediaLenCap: 86400
    readonly property int mediaTextGap: 2
    readonly property int mediaCtlGap: 15
    readonly property int mediaTitleH: 16
    readonly property int mediaArtistH: 13
    readonly property int mediaTrackSettle: 400
    readonly property int mediaTimeGap: 5
    readonly property int mediaTimeH: 11
    readonly property string mediaRemainChar: "−"
    readonly property int artFade: 220
    readonly property int artR: 18
    readonly property int artGlyph: 32
    readonly property string artNotePath: "M9 18V5L21 3V16M9 18A3 3 0 0 1 3 18A3 3 0 0 1 9 18ZM21 16A3 3 0 0 1 15 16A3 3 0 0 1 21 16Z"
    readonly property bool mediaTimes: cfg("mediaTimes", false)
    readonly property bool mediaScroll: cfg("mediaScroll", false)
    readonly property bool mediaCover: cfg("mediaCover", false)
    readonly property bool mediaWhiteText: cfg("mediaWhiteText", true)
    readonly property color mediaInk: mediaWhiteText ? white : fg
    readonly property int mediaCoverSource: 128
    readonly property int mediaCoverBlurMax: 48
    readonly property int mediaCoverBleed: 48
    readonly property real mediaCoverDim: 0.45
    readonly property int mediaCoverInset: 8
    readonly property int mediaCoverR: radius - (islandMediaPad - mediaCoverInset)
    readonly property int mediaCoverBarInset: 12
    readonly property int mediaScrollSpeed: 24
    readonly property int mediaScrollHold: 1600
    readonly property real mediaPausedArt: 0.97
    readonly property int mediaArtDuration: 260
    readonly property color mediaArtBorderHover: surfaceBorderHover
    readonly property int mediaMorph: 150
    readonly property int mediaNudge: 2
    readonly property int mediaNudgeDuration: 110
    readonly property int playNudge: 0
    readonly property int barHit: 7
    readonly property color mediaTrack: tile
    readonly property real btnHoverScale: 1.06
    readonly property real btnPressScale: 0.94

    // network
    readonly property int netW: 320
    readonly property int netPad: 12
    readonly property int netRowH: 36
    readonly property int netRows: 6
    readonly property int netTimeout: 30000
    readonly property int netFieldH: 34
    readonly property int netPromptGap: 10
    readonly property int netPromptRise: 6
    readonly property int blink: 700
    readonly property int sigBars: 4
    readonly property int sigGap: 2
    readonly property int sigW: 3
    readonly property int sigH: 4
    readonly property int sigStep: 2
    readonly property real sigOn: 0.9
    readonly property real sigOff: 0.2
    readonly property int sigRowW: sigBars * sigW + (sigBars - 1) * sigGap
    readonly property int sigRowH: sigH + (sigBars - 1) * sigStep
    readonly property int lockW: 14
    readonly property int lockH: 12
    readonly property real lockBorder: 1.4
    readonly property string lockShacklePath: "M3.7 5.5V3.7A3.3 3.3 0 0 1 10.3 3.7V5.5"
    readonly property string lockBodyPath: "M4 4H10A2 2 0 0 1 12 6V10A2 2 0 0 1 10 12H4A2 2 0 0 1 2 10V6A2 2 0 0 1 4 4Z"
    readonly property int netMetaR: 12
    readonly property int netSettle: 600
    readonly property int netKill: 3000
    readonly property int netVerify: 600
    readonly property int netPollBusy: 1500
    readonly property int netPoll: 4000
    readonly property int netLinkPoll: 2000
    readonly property int netLinkIdlePoll: 10000
    readonly property real netLinkMax: 70
    readonly property int netRescanWait: 2500
    readonly property int netMonitorRestart: 2000
    readonly property int netProbe: 2000
    readonly property int netCoalesce: 250
    readonly property int markX: 7
    readonly property int markW: 3
    readonly property int markH: 11
    readonly property real markY: 0.5
    readonly property int markCapH: 12
    readonly property int markCapY: -1

    // bluetooth
    readonly property int btW: 320
    readonly property int btPad: netPad
    readonly property int btRowH: netRowH
    readonly property int btRows: netRows
    readonly property int btMetaR: netMetaR
    readonly property string btGlyphPath: "M7 7L17 17L12 22L12 2L17 7L7 17"
    readonly property int btTimeout: 15000
    readonly property int btBatteryWait: 1200
    readonly property int btPowerSettle: 4000

    // tray
    readonly property int trayPad: 6
    readonly property int trayChipD: 22
    readonly property int trayGlyphD: 14
    readonly property int traySelD: 30
    readonly property int trayRowPad: 2
    readonly property int trayCellW: traySelD + 2 * trayPad
    readonly property int trayRowH: traySelD + 2 * trayRowPad
    readonly property int trayRows: netRows
    readonly property int trayEmptyW: 110
    readonly property int trayAttentionD: 6
    readonly property int trayMenuW: 240
    readonly property int trayMenuPad: netPad
    readonly property int trayMenuRowH: netRowH
    readonly property int trayMenuRows: netRows
    readonly property int trayMenuMarkD: 6
    readonly property int trayMenuChevronGap: 10
    readonly property int trayMenuSepW: 172
    readonly property int trayMenuSettle: 200

    // brightness
    readonly property int brightMin: 1
    readonly property int brightSettle: 1200
    readonly property int brightRetry: 400
    readonly property string brightSunPath: "M12 7A5 5 0 1 1 12 17A5 5 0 1 1 12 7ZM12 1V3M12 21V23M4.22 4.22L5.64 5.64M18.36 18.36L19.78 19.78M1 12H3M21 12H23M4.22 19.78L5.64 18.36M18.36 5.64L19.78 4.22"

    // audio
    readonly property color audioFill: Qt.rgba(accent.r, accent.g, accent.b, 0.45)
    readonly property real audioIconStroke: glyphStroke(mixerIcon)
    readonly property real audioSlashStroke: glyphStroke(mixerIcon, 2.2)
    readonly property string audioInPath: "M12 3A3.25 3.25 0 0 1 15.25 6.25V9.25A3.25 3.25 0 0 1 8.75 9.25V6.25A3.25 3.25 0 0 1 12 3Z"
    readonly property string audioInCradlePath: "M18 10.5A6 6 0 0 1 6 10.5 M12 16.5V20.5"
    readonly property string audioSlashPath: "M4 4L20 20"
    readonly property string audioSpeakerPath: "M3 9H8L16 3V21L8 15H3Z"
    readonly property string audioWave1Path: "M20.3 10.4A2.3 2.3 0 0 1 20.3 13.6"
    readonly property string audioWave2Path: "M23.5 8.2A4.5 4.5 0 0 1 23.5 15.8"
    readonly property string audioWave3Path: "M28 6A7 7 0 0 1 28 18"
    readonly property real audioWaveLowAt: 0.25
    readonly property real audioWaveHighAt: 0.5
    readonly property int micS: 12

    // mixer
    readonly property int mixerPad: 16
    readonly property int mixerColW: 54
    readonly property int mixerColGap: 16
    readonly property int mixerTrackH: cfg("mixerTrackH", 96)
    readonly property int mixerTrackW: 3
    readonly property real mixerKnobDim: 0.85
    readonly property int mixerHandleW: 13
    readonly property int mixerHandleH: 3
    readonly property int mixerIconBox: 24
    readonly property int mixerIcon: 16
    readonly property int mixerGap: 10
    readonly property int mixerPctH: fsS + 2
    readonly property int mixerLabelH: fsXXS + 2
    readonly property bool mixerPct: cfg("mixerPct", false)
    readonly property bool mixerApps: cfg("mixerApps", false)
    readonly property bool mixerLabels: cfg("mixerLabels", Quickshell.screens.length > 1)
    readonly property int mixerStep: cfg("mixerStep", 5)
    readonly property int mixerFineStep: 1
    readonly property int mixerBigStep: 10
    readonly property real mixerResponse: springResponse
    readonly property real mixerDamping: springDamping
    readonly property int mixerAppIcon: 18
    readonly property color mixerMutedFill: mix(bg, fg, 0.22)
    readonly property real mixerZeroDim: 0.3

    // screenshot
    readonly property string screenshotDir: Quickshell.env("HOME") + "/pictures/screenshots"
    readonly property int screenshotCheckDelay: 300
    readonly property int screenshotSettleDelay: fall + speed + 40
    readonly property int regionMinSize: 4
    readonly property int regionShotWait: 34
    readonly property real regionDim: 0.8
    readonly property int regionBorderWidth: 2
    readonly property int regionLabelGap: 8
    readonly property int regionLabelPadX: 8
    readonly property int regionLabelPadY: 4
    readonly property int regionLabelR: 8
    readonly property real regionGuideOpacity: 0.6
    readonly property int regionGuideWidth: 1
    readonly property string shotBodyPath: "M5 8H10L12 6H16L18 8H19A2 2 0 0 1 21 10V17A2 2 0 0 1 19 19H5A2 2 0 0 1 3 17V10A2 2 0 0 1 5 8Z"
    readonly property string shotLensPath: "M8 13A4 4 0 1 0 16 13A4 4 0 1 0 8 13Z"
    readonly property string shotRegionPath: "M4 9V5A1 1 0 0 1 5 4H9 M15 4H19A1 1 0 0 1 20 5V9 M20 15V19A1 1 0 0 1 19 20H15 M9 20H5A1 1 0 0 1 4 19V15"
    readonly property string shotWindowPath: "M4 6.5A2.5 2.5 0 0 1 6.5 4H17.5A2.5 2.5 0 0 1 20 6.5V17.5A2.5 2.5 0 0 1 17.5 20H6.5A2.5 2.5 0 0 1 4 17.5V6.5Z M4 8H20"
    readonly property string shotActiveBadgePath: "M4 6.5A2.5 2.5 0 0 1 6.5 4H17.5A2.5 2.5 0 0 1 20 6.5V8H4V6.5Z"
    readonly property string monitorPath: "M3 8.5A2.5 2.5 0 0 1 5.5 6H18.5A2.5 2.5 0 0 1 21 8.5V15.5A2.5 2.5 0 0 1 18.5 18H5.5A2.5 2.5 0 0 1 3 15.5V8.5Z M12 18V20 M8 20H16"
    readonly property int monitorNumPx: fs(10)
    readonly property int monitorNumY: 0
    readonly property real monitorNumAxis: 12

    // recording
    readonly property string recordDir: dir(cfg("recordDir", ""), Quickshell.env("HOME") + "/videos/records")
    readonly property string recordDirShort: tilde(recordDir)
    readonly property string recordBin: ""
    readonly property string recordBackend: ""
    readonly property int recordFps: cfg("recordFps", 60)
    readonly property bool recordDesktopAudio: cfg("recordDesktopAudio", true)
    readonly property bool recordMic: cfg("recordMic", false)
    readonly property bool recordCursor: cfg("recordCursor", true)
    readonly property int recordDot: 8
    readonly property int recordBadge: 6
    readonly property int recordBadgeInset: 7
    readonly property int recordStopGrace: 3000
    readonly property int recordTick: 1000
    readonly property string recStopPath: "M8 6H16A2 2 0 0 1 18 8V16A2 2 0 0 1 16 18H8A2 2 0 0 1 6 16V8A2 2 0 0 1 8 6Z"
    readonly property string recPortalPath: "M6 16H5A2 2 0 0 1 3 14V6A2 2 0 0 1 5 4H19A2 2 0 0 1 21 6V14A2 2 0 0 1 19 16H18 M12 14L17 20H7L12 14Z"
    readonly property string recDotPath: "M12 4A8 8 0 1 0 12 20A8 8 0 1 0 12 4Z"

    // calendar
    readonly property int weekCells: cfg("weekCells", 9)
    readonly property int weekLead: 1
    readonly property int weekDays: 7
    readonly property int weekGap: 4
    readonly property int weekTodayR: 11
    readonly property real weekFadeMin: 0.12
    readonly property real weekFadeSpan: 4.7
    readonly property real weekFadeCurve: 1
    readonly property real todayFill: cfg("todayFill", 0.15)
    readonly property real outMonth: cfg("outMonth", 0.25)
    readonly property int calSlide: 10
    readonly property int calGap: 6
    readonly property int calTitleX: 4
    readonly property int calHeadH: 16
    readonly property real calTodayScale: 0.86
    readonly property int cellW: 30
    readonly property int cellH: 24
    readonly property int stripH: 40
    readonly property int gridW: cellW * 7

    // island
    readonly property int islandDuration: 200
    readonly property real islandResponse: springResponse
    readonly property real islandDamping: springDamping
    readonly property bool menuBounce: cfg("menuBounce", true)
    readonly property real menuBounceResponse: cfg("menuBounceResponse", 0.42)
    readonly property real menuBounceDamping: cfg("menuBounceDamping", 0.6)
    readonly property real menuBounceReach: cfg("menuBounceReach", 28)
    readonly property real menuBounceDip: cfg("menuBounceDip", 0.08)
    readonly property bool menuSwitchDip: cfg("menuSwitchDip", true)
    readonly property real islandDropResponse: 0.24
    readonly property real islandDropDamping: 0.92
    readonly property real islandContentResponse: islandResponse
    readonly property real islandContentDamping: springDamping
    readonly property int islandPopW: cfg("islandPopW", 12)
    readonly property int islandPopH: cfg("islandPopH", 6)
    readonly property int islandPopDrop: cfg("islandPopDrop", 5)
    readonly property int islandHitGrow: cfg("islandHitGrow", 4)
    readonly property int islandContentSlide: 6
    readonly property int islandContentStage: 40
    readonly property int islandWeekCells: weekCells
    readonly property int islandWeekLead: cfg("islandWeekLead", 0)
    readonly property real islandWeekFadeSpan: 5.4
    readonly property real islandWeekFadeMin: 0.08
    readonly property real islandWeekFadeCurve: 2
    readonly property int islandWeekPad: 14
    readonly property int islandWeekW: cellW * islandWeekCells
    readonly property int islandWeekH: stripH + 2 * islandWeekPad
    readonly property int islandCalCellW: 38
    readonly property int islandCalCellH: 28
    readonly property int islandCalPad: 16
    readonly property int islandCalW: islandCalCellW * weekDays + 2 * islandCalPad
    readonly property int islandMediaPad: 16
    readonly property int islandMediaTopPad: idleTopOffsetY + islandPopH / 2 + h + rowGap
    readonly property int islandMediaW: mediaW + 2 * islandMediaPad
    readonly property int islandMediaH: islandMediaTopPad + artS + islandMediaPad

    // dashboard
    readonly property int dashW: cfg("dashW", 360)
    readonly property int dashMinW: 360
    readonly property int dashMaxW: 760
    readonly property int dashPad: 12
    readonly property int dashPadX: cfg("dashPadX", 26)
    readonly property int dashRowH: 24
    readonly property int dashRow2H: 14
    readonly property int dashRowGap: 4
    readonly property int dashGap: 8
    readonly property int dashStatusGap: cfg("dashStatusGap", 10)
    readonly property int dashGlyph: 14
    readonly property real dashSwapScale: 0.6
    readonly property int dashSwapTurn: -40
    readonly property real dashNoteDot: 4
    readonly property real dashNoteDotRing: 1.4
    readonly property int dashBtGlyph: 15
    readonly property string dashBtSlashPath: "M6 6L18 18"
    readonly property int dashVolW: 17
    readonly property int dashClockPx: fs(cfg("dashClockPx", 22))
    readonly property int dashDatePx: fsM
    readonly property string dashDateFormat: cfg("dashDateFormat", "MMM d")
    readonly property string dashWeekdayFormat: cfg("dashWeekdayFormat", "ddd")
    readonly property bool dashWeekday: cfg("dashWeekday", true)
    readonly property real dashDim: dimSoft
    readonly property real dashMorphResponse: cfg("dashMorphResponse", 0.42)
    readonly property real dashMorphDamping: cfg("dashMorphDamping", 0.6)
    readonly property real dashRevealAt: 0.35
    readonly property real dashLateAt: 0.85
    readonly property real dashSizeHold: 0.06
    readonly property real dashMorphHold: 0.06
    readonly property real dashBounceHold: 0.004
    readonly property real dashPopFrom: 0.5
    readonly property real dashColumnLock: 3
    readonly property bool dashWs: cfg("dashWs", true)
    readonly property bool dashDate: cfg("dashDate", true)
    readonly property bool dashNotes: cfg("dashNotes", true)
    readonly property bool dashNet: cfg("dashNet", true)
    readonly property bool dashBt: cfg("dashBt", true)
    readonly property bool dashVolume: cfg("dashVolume", cfg("dashPower", true))
    readonly property bool dashBattery: cfg("dashBattery", cfg("dashPower", true))

    // visualizer
    readonly property bool visPeek: cfg("visPeek", false)
    readonly property int visBars: cfg("visBars", 6)
    readonly property int visBarW: cfg("visBarW", 3)
    readonly property int visGap: 3
    readonly property int visMinH: 4
    readonly property int visMaxH: cfg("visMaxH", 14)
    readonly property int visIdleH: 4
    readonly property int visCycle: 900
    readonly property real visFreqStep: 0.35
    readonly property real visOffset: 1.1
    readonly property int visSettle: speed
    readonly property color visFallback: accent
    readonly property int visSampleSize: 32
    readonly property int visSampleAlpha: 128
    readonly property int visSampleWait: 1200
    readonly property real visSatFloor: 0.12
    readonly property real visSpread: 0.35
    readonly property real visLift: 1.45
    readonly property real visDim: 0.3
    readonly property int visTint: speed
    readonly property int visOffDelay: 8000
    readonly property int visFps: cfg("visFps", 60)
    readonly property int visNoiseReduction: 77
    readonly property real visLerp: 0.3

    // settings
    readonly property int settingsW: cfg("settingsW", 860)
    readonly property int settingsRadius: launchRadius
    readonly property int settingsPad: 14
    readonly property int settingsPadBottom: 16
    readonly property int settingsCardRadius: inner(settingsRadius, 6)
    readonly property int settingsSidebarW: 156
    readonly property int settingsGap: 24
    readonly property int settingsBorderWidth: pillBorderWidth
    readonly property real settingsBorderOpacity: pillBorderOpacity
    readonly property color settingsBg: bg
    readonly property real settingsBgOpacity: 1
    readonly property int settingsEdgeFade: 36
    readonly property color settingsCard: mix(settingsBg, fg, 0.07)
    readonly property color settingsHover: mix(settingsBg, fg, 0.13)
    readonly property color settingsTrack: mix(settingsBg, fg, 0.2)
    readonly property color settingsDivider: Qt.rgba(1, 1, 1, 0.07)
    readonly property color settingsRowHover: Qt.rgba(1, 1, 1, 0.045)
    readonly property color settingsValueInk: mix(settingsInk, settingsBg, 0.45)
    readonly property int settingsRowH: 35
    readonly property int settingsSectionPx: fs(10)
    readonly property color settingsSectionInk: mix(settingsInk, settingsBg, 0.5)
    readonly property int settingsRowPadX: 12
    readonly property int settingsValueGap: 6
    readonly property int settingsGroupGap: 9
    readonly property int settingsTitleInset: 4
    readonly property int settingsTitleLift: 2
    readonly property int settingsSidebarItemH: 34
    readonly property int settingsSidebarItemRadius: settingsSidebarItemH / 2
    readonly property int settingsSidebarPadX: 7
    readonly property int settingsSidebarGap: 3
    readonly property int settingsLabelPx: fs(12)
    readonly property int settingsValuePx: fs(12)
    readonly property int settingsSidebarPx: fs(12)
    readonly property int settingsSidebarIconD: 22
    readonly property int settingsSidebarIcon: 13
    readonly property real settingsIconStroke: 1.7
    readonly property color settingsIconOnBg: accent
    readonly property color settingsIconOnInk: settingsBg
    readonly property color settingsIconOffBg: mix(settingsBg, accent, 0.22)
    readonly property color settingsIconOffInk: mix(accent, settingsBg, 0.16)
    readonly property int settingsArrowSize: 13
    readonly property color settingsArrowInk: settingsValueInk
    readonly property string settingsArrowPath: "M5 12H19M13 6L19 12L13 18"
    readonly property string settingsSlidersPath: "M21 4H14M10 4H3M21 12H12M8 12H3M21 20H16M12 20H3M14 2V6M8 10V14M16 18V22"
    readonly property string settingsDashboardPath: "M3.5 5.5H20.5A1 1 0 0 1 21.5 6.5V17.5A1 1 0 0 1 20.5 18.5H3.5A1 1 0 0 1 2.5 17.5V6.5A1 1 0 0 1 3.5 5.5Z M2.5 12H21.5 M9 12V18.5"
    readonly property string settingsIslandPath: "M7.5 7H16.5A5 5 0 0 1 16.5 17H7.5A5 5 0 0 1 7.5 7Z"
    readonly property string settingsClockPath: "M12 3A9 9 0 1 1 12 21A9 9 0 1 1 12 3ZM12 7.5V12L15.5 14.5"
    readonly property string settingsMediaPath: "M8 5L19 12L8 19Z"
    readonly property string settingsLauncherPath: "M4 4H10.5V10.5H4ZM13.5 4H20V10.5H13.5ZM4 13.5H10.5V20H4ZM13.5 13.5H20V20H13.5Z"
    readonly property string settingsBellPath: "M18 8.5A6 6 0 0 0 6 8.5C6 15 3 17 3 17H21S18 15 18 8.5ZM13.7 20.5A2 2 0 0 1 10.3 20.5"
    readonly property string settingsSystemPath: "M3 5H21V16H3ZM8.5 20H15.5M12 16V20"
    readonly property string settingsWorkspacesPath: "M4 12H4.01M20 12H20.01M9.5 12H14.5"
    readonly property string settingsIconsPath: "M4 4H10.5V20H4ZM13.5 4H20V20H13.5Z"
    readonly property string settingsStylePath: "M9.06 11.9L17.13 3.84A2.85 2.85 0 1 1 21.16 7.87L13.1 15.95M7.07 14.94C5.41 14.94 4.07 16.29 4.07 17.96C4.07 19.29 1.57 19.48 2.07 19.98C3.15 21.08 4.56 22 6.07 22C8.27 22 10.07 20.2 10.07 17.96A3.01 3.01 0 0 0 7.07 14.94Z"
    readonly property string settingsMotionPath: "M3 12C5 6 7 6 9 12C11 18 13 18 15 12C17 6 19 6 21 12"
    readonly property string settingsRecordPath: "M6 6H13A3 3 0 0 1 16 9V15A3 3 0 0 1 13 18H6A3 3 0 0 1 3 15V9A3 3 0 0 1 6 6Z M16 11L21 8V16L16 13"
    readonly property real settingsScaleFrom: 0.9
    readonly property real settingsPopResponse: 0.3
    readonly property real settingsPopDamping: springDamping
    readonly property real settingsSettleHold: 0.02
    readonly property real settingsCloseHold: 0.06
    readonly property real settingsBoxFadeIn: 0.3
    readonly property real settingsContentDelay: 0.35
    readonly property real settingsContentScaleFrom: 0.97
    readonly property real settingsMoveResponse: 0.2
    readonly property real settingsMoveDamping: springDamping
    readonly property int settingsToggleW: 34
    readonly property int settingsToggleH: 20
    readonly property int settingsToggleKnob: 16
    readonly property int settingsDotD: 16
    readonly property int settingsDotGap: 10
    readonly property int settingsDotRingPad: 3
    readonly property int settingsSliderH: 4
    readonly property int settingsSliderKnobD: 10
    readonly property int settingsSliderHitPad: 8
    readonly property int settingsFieldH: 26
    readonly property int settingsFieldW: 140
    readonly property int settingsPathW: 200
    readonly property color settingsFieldBg: mix(settingsBg, fg, 0.13)
    readonly property int settingsSliderW: 120
    readonly property int settingsSegW: 190
    readonly property int settingsSegH: settingsRowH - 10
    readonly property int settingsSegRadius: inner(settingsCardRadius, 4)
    readonly property int settingsSegPadX: 10
    readonly property color settingsSegBg: mix(settingsBg, fg, 0.04)
    readonly property real settingsFocusWidth: 1.5
    readonly property int settingsFocusPad: 3
    readonly property int settingsFocusRadius: 7
    readonly property color settingsFocusInk: accent
    readonly property int settingsModDot: 5
    readonly property int settingsModHit: 16
    readonly property int settingsModGap: 8
    readonly property real settingsStepKey: 0.05
}

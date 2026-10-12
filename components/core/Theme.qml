pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string screen: "HDMI-A-1"
    readonly property string font: "sans-serif"
    readonly property var terminal: ["sh", "-c", 'for t in "$TERMINAL" alacritty kitty foot ghostty wezterm xterm; do command -v "$t" >/dev/null 2>&1 || continue; case $t in kitty) exec kitty "$@";; wezterm) exec wezterm start -- "$@";; *) exec "$t" -e "$@";; esac; done', "sh"]
    readonly property string wallDir: "file:///home/cat/pictures/wallpapers"
    readonly property var wallCmd: ["colors"]
    readonly property string recordDir: "/home/cat/videos/records"
    readonly property string recordBin: ""
    readonly property string recordBackend: ""
    readonly property int recordFps: 60
    readonly property int recordDot: 7
    readonly property int recordW: 300
    readonly property int recordPad: 12
    readonly property int recordRowH: 34
    readonly property int recordRows: 6
    readonly property int recordStopGrace: 3000
    readonly property int netW: 320
    readonly property int netPad: 12
    readonly property int netRowH: 36
    readonly property int netRows: 6
    readonly property int netTimeout: 30000
    readonly property int netFieldH: 34
    readonly property int netToggleW: 36
    readonly property int netToggleH: 20
    readonly property int netKnob: 14
    readonly property int netFocusInset: 4
    readonly property int netFocusInsetY: 1
    readonly property int netFocusMarkX: 7
    readonly property int netFocusMarkW: 3
    readonly property int netFocusMarkH: netRowH / 2 - 1
    readonly property color netFocusFill: chip
    readonly property color bg: "#000000"
    readonly property color fg: "#ffffff"
    readonly property color chip: "#1c1c1e"
    readonly property color tile: "#2c2c2e"
    readonly property color accent: "#f2b8e2"
    readonly property color red: "#e5534b"

    readonly property int listGap: 6
    readonly property int rowX: 18
    readonly property int rowR: 14
    readonly property int markW: 3
    readonly property int markX: 5
    readonly property int fsXS: 10
    readonly property int fsS: 11
    readonly property int fsM: 12
    readonly property int fsL: 13

    readonly property int gap: 6
    readonly property int pad: 16
    readonly property int w: 64
    readonly property int h: 28
    readonly property int openW: 252
    readonly property int openH: 80
    readonly property int noteW: 264
    readonly property int noteH: 48
    readonly property int noteOpenW: 300
    readonly property int noteTop: (noteH - noteIcon) / 2
    readonly property int noteIcon: 28
    readonly property int noteIconR: 14
    readonly property int noteIconX: 10
    readonly property int noteTextGap: 10
    readonly property int noteTextRight: 14
    readonly property int noteBodyLines: 1
    readonly property int noteOpenBodyLines: 3
    readonly property int radius: 28

    readonly property int launchW: 340
    readonly property int lpad: 8
    readonly property int rowH: 38
    readonly property int rows: 5
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
    readonly property int launchSearchTextX: 40
    readonly property int launchSearchTextRight: 12
    readonly property int launchIconX: 10
    readonly property int launchIconBox: 24
    readonly property int launchIconSize: 16
    readonly property int launchIconSourceSize: 32
    readonly property int launchIconRadius: 7
    readonly property int launchIconBorderWidth: 1
    readonly property real launchIconSelectedScale: 1.02
    readonly property int launchSelectionX: 4
    readonly property int launchSelectionRight: 4
    readonly property int launchSelectionH: rowH - 2
    readonly property int launchSelectionRadius: launchSelectionH / 2
    readonly property color launchSelectionFill: Qt.rgba(1, 1, 1, 0.06)
    readonly property int launchSelectionDuration: feedbackDuration
    readonly property color launchIconFill: Qt.rgba(chip.r, chip.g, chip.b, 0.36)
    readonly property color launchIconSelectedFill: chip
    readonly property color launchIconBorder: Qt.rgba(1, 1, 1, 0.16)
    readonly property color launchIconHoverBorder: Qt.rgba(1, 1, 1, 0.34)
    readonly property int launchTextGap: 10
    readonly property int launchFallbackPx: 10

    readonly property int pwW: 68
    readonly property int pwH: 66
    readonly property int pwGap: 8
    readonly property int pwPad: 10
    readonly property int pwN: 5
    readonly property int powerW: pwW * pwN + pwGap * (pwN - 1) + pwPad * 2

    readonly property int wallPad: 14
    readonly property int thumbW: 120
    readonly property int thumbH: 68
    readonly property int thumbGap: 16
    readonly property int wallN: 5
    readonly property int wallPreload: 3
    readonly property int wallTrackH: thumbH + 20
    readonly property int wallRadius: 8
    readonly property int wallRing: 2
    readonly property int wallSourceW: thumbW * 2
    readonly property int wallSourceH: thumbH * 2
    readonly property real wallFocusScale: 1.15
    readonly property int wallW: thumbW * wallN + thumbGap * (wallN - 1) + wallPad * 2

    readonly property int authW: 380
    readonly property int authPad: 16
    readonly property int authFieldH: 40
    readonly property int authFieldR: 12
    readonly property int authBtnH: 34
    readonly property int authIcon: 32

    readonly property int mediaPillW: 268
    readonly property int mediaW: mediaPillW - 2 * pad
    readonly property int mediaGap: 8
    readonly property int artS: 40
    readonly property int ctlS: 26
    readonly property int playS: 30
    readonly property int glyphS: 14
    readonly property int playGlyph: 14
    readonly property int barH: 3
    readonly property int micS: 12
    readonly property int clockPx: 14
    readonly property int idleOffsetX: 0
    readonly property int idleOffsetY: 0
    readonly property int idleTopOffsetY: 0
    readonly property int clockOffsetX: 0
    readonly property int clockOffsetY: 0
    readonly property int moduleOffsetY: 0
    readonly property bool idleAlignWhenCentered: true
    readonly property int batteryOffsetX: 0
    readonly property int batteryOffsetY: 0
    readonly property int micOffsetX: 0
    readonly property int micOffsetY: 0
    readonly property int recordOffsetX: 0
    readonly property int recordOffsetY: 0
    readonly property int batRowH: 16
    readonly property int batW: 21
    readonly property int batH: 11
    readonly property int batBorder: 1
    readonly property int batNubW: 2
    readonly property int batNubH: 5
    readonly property int batNubGap: 1
    readonly property color batNubColor: fg
    readonly property int batGap: clockGap
    readonly property int batIconW: batGap + batW + batNubGap + batNubW
    readonly property int batRadius: 4
    readonly property int batFillRadius: 3
    readonly property int batBoltW: 5
    readonly property int batBoltH: 7
    readonly property real batPopScale: slotScale
    readonly property real batBoltScale: 0.75
    readonly property int batBoltDuration: 140
    readonly property int noteBatW: 16
    readonly property int noteBatH: 10
    readonly property int noteBatNubW: 2
    readonly property int noteBatNubH: 4
    readonly property int noteBatGap: 1
    readonly property color noteBatNubColor: fg
    readonly property int noteBatBorder: 1
    readonly property int noteBatRadius: 3
    readonly property int noteBatBoltW: 4
    readonly property int noteBatBoltH: 6
    readonly property color batRed: "#ff3b30"
    readonly property color batYellow: "#ffcc00"
    readonly property color batGreen: "#34c759"
    readonly property int clockGap: 4
    readonly property int rowGap: 8
    readonly property int idlePopDuration: speed
    readonly property int pulse: 1400
    readonly property int blink: 700
    readonly property int slotHit: 6
    readonly property real slotScale: 0.7
    readonly property real dotLow: 0.65

    readonly property int cellW: 30
    readonly property int cellH: 24
    readonly property int stripH: 40
    readonly property int gridW: cellW * 7
    readonly property int body: h + 2
    readonly property int zone: gap + h

    readonly property int speed: 300
    readonly property int fade: 60
    readonly property int glide: 240
    readonly property int fast: 60
    readonly property int feedbackDuration: 120
    readonly property real feedbackHoverScale: 1.03
    readonly property real feedbackPressScale: 0.97
    readonly property real feedbackHoverFill: 0.06
    readonly property real feedbackPressFill: 0.1
    readonly property real feedbackFocusBorder: 1
    readonly property int dwell: 3000
    readonly property int dwellCritical: 5000
    readonly property int dwellMax: 15000
    readonly property int notificationQueueMax: 32
    readonly property real batRedAt: 0.15
    readonly property real batYellowAt: 0.25
    readonly property int ease: Easing.OutCubic

    readonly property int fsXXS: 9
    readonly property int fsXL: 14
    readonly property int fsXXL: 15
    readonly property int iconGrid: 24
    readonly property real iconStroke: 1.8
    readonly property real btnStroke: 2
    readonly property real dimHint: 0.35
    readonly property real dimGhost: 0.4
    readonly property real dimEmpty: 0.45
    readonly property real dimMid: 0.5
    readonly property real dimMuted: 0.55
    readonly property real dimSoft: 0.6
    readonly property int ruleH: 1
    readonly property real ruleOpacity: 0.1
    readonly property real settleEps: 0.5
    readonly property int noteLineGap: 1

    readonly property int authSpacing: 12
    readonly property int authHeadGap: 10
    readonly property int authBtnGap: 8
    readonly property int authGlyph: 16
    readonly property int authIconR: authFieldR - 2
    readonly property int authFieldIconX: 12
    readonly property int authFieldTextX: 40
    readonly property int authFieldTextPad: 52
    readonly property int authBtnPadX: 28
    readonly property real authPressed: 0.82
    readonly property real authDisabled: 0.45

    readonly property int pwIconY: 11
    readonly property int pwLabelY: 42

    readonly property int weekCells: 9
    readonly property int weekCenter: 4
    readonly property int weekLead: 1
    readonly property int weekDays: 7
    readonly property int weekGap: 4
    readonly property int weekTodayR: 11
    readonly property real weekFadeMin: 0.12
    readonly property real weekFadeSpan: 4.7
    readonly property real todayFill: 0.15
    readonly property real outMonth: 0.25
    readonly property int calSlide: 10
    readonly property int calGap: 6
    readonly property int calTitleX: 4
    readonly property int calHeadH: 16

    readonly property int mediaColGap: 6
    readonly property int mediaTextGap: 2
    readonly property int mediaCtlGap: 4
    readonly property int artR: 10
    readonly property int playNudge: 1
    readonly property int barPad: 4
    readonly property int barHit: 6
    readonly property int knobS: 7
    readonly property int knobY: -2
    readonly property real knobScrub: 1.15
    readonly property real btnDisabled: 0.3
    readonly property real btnIdle: 0.75
    readonly property real btnPressed: 0.85

    readonly property int sigBars: 4
    readonly property int sigGap: 2
    readonly property int sigW: 3
    readonly property int sigH: 4
    readonly property int sigStep: 2
    readonly property int sigR: 1
    readonly property real sigOn: 0.9
    readonly property real sigOff: 0.2
    readonly property int lockW: 14
    readonly property int lockH: 12
    readonly property int lockArcW: 8
    readonly property int lockArcH: 6
    readonly property int lockArcR: 4
    readonly property real lockBorder: 1.4
    readonly property int lockBodyY: 4
    readonly property int lockBodyW: 10
    readonly property int lockBodyH: 8
    readonly property int lockBodyR: 2
    readonly property int netTitleX: 4
    readonly property int netToggleInset: 2
    readonly property int netMetaR: 12
    readonly property int netEmptyPad: 8
    readonly property int netSettle: 600
    readonly property int netPollBusy: 1500
    readonly property int netPoll: 4000
    readonly property int netRescanWait: 2500

    readonly property int wallGap: 10
    readonly property real wallHoverOpacity: 0.82
    readonly property real wallIdleOpacity: 0.7
    readonly property int launchSearchHandleRot: 45
    readonly property int launchTextRowGap: 1
    readonly property int recordTick: 1000
    readonly property int imageRetry: 200

    readonly property int dwellMin: 500
    readonly property int dwellNever: 5000

    function url(path) {
        const value = String(path || "")
        if (value === "" || /^[a-z][a-z0-9+.-]*:/i.test(value))
            return value
        return "file://" + value.split("/").map(encodeURIComponent).join("/")
    }
}


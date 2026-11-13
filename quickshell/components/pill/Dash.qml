import "../audio"
import "../battery"
import "../bluetooth"
import "../core"
import "../mixer"
import "../network"
import "../notifications"
import "../workspaces"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property date now
    property bool shown: false
    property bool present: false
    property bool leaving: false
    property bool staged: false
    property bool ready: true
    property real t: 0
    property real tFlat: 0
    property bool live: false
    property bool morphs: false
    property real calm: 0
    property bool hands: true
    property real originCy: 0
    property var origins: ({})

    readonly property real originY: root.originCy - Theme.dashPad
    readonly property real revealRaw: Math.max(0, Math.min(1, (root.t - Theme.dashRevealAt) / (1 - Theme.dashRevealAt)))
    readonly property real reveal: root.revealRaw * root.revealRaw * (3 - 2 * root.revealRaw)
    readonly property real lateRaw: Math.max(0, Math.min(1, (root.t - Theme.dashLateAt) / (1 - Theme.dashLateAt)))
    readonly property real late: root.lateRaw * root.lateRaw * (3 - 2 * root.lateRaw)
    readonly property bool composed: !root.morphs || root.live
    readonly property color dim: Theme.mix(Theme.bg, Theme.fg, Theme.dashDim)

    readonly property int row1y: 0
    readonly property int row2y: Theme.dashRowH + Theme.dashRowGap
    readonly property real clockT: Math.max(0, Math.min(1, root.tFlat))
    readonly property real sizeT: Math.max(0, Math.min(1,
        (root.clockT - Theme.dashSizeHold) / (1 - 2 * Theme.dashSizeHold)))
    readonly property real clockSize: Theme.clockPx + (Theme.dashClockPx - Theme.clockPx) * root.sizeT
    readonly property int clockPixel: root.hands && root.clockT < 0.5 ? Theme.clockPx : Theme.dashClockPx
    readonly property real clockScale: root.clockSize / root.clockPixel

    function origin(key) {
        const v = root.origins[key]
        return v === undefined ? null : v
    }

    // content

    readonly property int notes: Notifs.history.length

    readonly property string dateText: {
        const w = Theme.dashWeekday ? Qt.formatDate(root.now, Theme.dashWeekdayFormat).toLowerCase() : ""
        const d = Theme.dashDate ? Qt.formatDate(root.now, Theme.dashDateFormat).toLowerCase() : ""
        return w !== "" && d !== "" ? w + ", " + d : w + d
    }

    readonly property bool wifiHands: root.origin("wifi") !== null
    property real netLit: Net.enabled ? 1 : 0
    readonly property color wifiInk: Theme.mix(root.dim, Theme.accent, root.netLit)
    readonly property color wifiIdleInk: Theme.mix(Theme.mix(Theme.bg, Theme.accent, Theme.dimMid), Theme.accent, root.netLit)

    Behavior on netLit {
        NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
    }

    readonly property bool onBattery: Battery.available
    readonly property int waveTier: Audio.outMuted || !Audio.outReady || Audio.outLevel <= 0 ? 0
        : Audio.outLevel < Theme.audioWaveLowAt ? 1
        : Audio.outLevel < Theme.audioWaveHighAt ? 2
        : 3

    width: Theme.dashW - 2 * Theme.dashPadX
    height: Theme.dashRowH + Theme.dashRowGap + Theme.dashRow2H
    readonly property real wantW: width + 2 * Theme.dashPadX
    readonly property real wantH: y + height + Theme.dashPad
    visible: root.present && root.opacity > 0.004
    opacity: 0

    function retarget(to, ms) {
        wash.stop()
        wash.duration = ms
        wash.to = to
        wash.start()
    }

    function sync() {
        if (!root.present) {
            wash.stop()
            root.opacity = 1
            return
        }
        if (root.leaving || !root.staged && !root.morphs) {
            root.retarget(0, Theme.fall)
            return
        }
        if (root.staged && !root.ready) {
            wash.stop()
            root.opacity = 0
            return
        }
        root.retarget(1, root.staged ? Theme.rise : 0)
    }

    onPresentChanged: root.sync()
    onLeavingChanged: root.sync()
    onStagedChanged: root.sync()
    onReadyChanged: root.sync()
    onMorphsChanged: root.sync()

    onComposedChanged: {
        calmRun.stop()
        calmRun.duration = root.composed ? Theme.rise : Theme.fall
        calmRun.to = root.composed ? 1 : 0
        calmRun.start()
    }

    Component.onCompleted: {
        root.calm = root.composed ? 1 : 0
        clockLift.land(clockLift.target)
        root.sync()
    }

    NumberAnimation {
        id: calmRun
        target: root
        property: "calm"
        easing.type: Theme.ease
    }

    NumberAnimation {
        id: wash
        target: root
        property: "opacity"
        easing.type: Theme.ease
    }

    Binding {
        target: Net
        property: "watchLink"
        value: root.visible
    }

    Spring {
        id: clockLift
        target: root.dateText === "" ? Math.round((root.height - Theme.dashRowH) / 2) : root.row1y
        hold: Theme.dashMorphHold
    }

    Txt {
        id: ghost
        visible: false
        text: Theme.clockText(root.now)
        font.pixelSize: Theme.dashClockPx
        font.features: Theme.tabular
    }

    // left

    DashRow {
        x: 0
        y: root.row1y
        height: Theme.dashRowH

        DashCell {
            shown: Theme.dashBattery && root.onBattery
            contentW: bat.width
            origin: root.origin("battery")
            lead: wsCell
            hoverable: true
            onActivated: Mixer.open = true

            BatteryModule {
                id: bat
                anchors.centerIn: parent
                height: Theme.h
            }
        }
    }

    DashRow {
        x: 0
        y: root.row2y
        height: Theme.dashRow2H

        DashCell {
            id: wsCell
            shown: Theme.dashWs && Workspaces.available
            contentW: Workspaces.span
            origin: root.origin("ws")

            WsModule {
                id: strip
                x: (parent.width - width) / 2
                y: Theme.mid(parent.height, height)
                live: Theme.dashWs && Workspaces.available

                MouseArea {
                    anchors.fill: parent
                    visible: Theme.wsClick && wsCell.shown && wsCell.live
                    hoverEnabled: visible
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: m => strip.hot = strip.slotAt(m.x)
                    onExited: strip.hot = -1
                    onVisibleChanged: if (!visible) strip.hot = -1
                    onClicked: m => Workspaces.focus(strip.slotAt(m.x) + 1)
                }
            }
        }
    }

    // centre

    DashRow {
        id: centre
        x: Theme.mid(root.width, width)
        y: clockLift.shaped
        height: Theme.dashRowH

        DashCell {
            contentW: 2 * Math.ceil(ghost.width / 2)
            origin: root.origin("clock")
            fades: !root.hands
            bounces: false
            stages: false

            RollTxt {
                id: clockText
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                text: Theme.clockText(root.now)
                color: Theme.clockInk
                font.pixelSize: root.clockPixel
                font.features: Theme.tabular
                scale: root.clockScale
            }
        }
    }

    DashRow {
        x: Theme.mid(root.width, width)
        y: root.row2y
        height: Theme.dashRow2H

        DashCell {
            shown: root.dateText !== ""
            stages: false
            contentW: 2 * Math.ceil(date.implicitWidth / 2)

            InkTxt {
                id: date
                width: parent.width
                height: parent.height
                horizontalAlignment: Text.AlignHCenter
                text: root.dateText
                color: root.dim
                font.pixelSize: Theme.dashDatePx
            }
        }
    }

    // right

    DashRow {
        anchors.right: parent.right
        y: root.row1y
        height: Theme.dashRowH

        DashCell {
            shown: Theme.dashNotes
            contentW: Theme.dashGlyph
            hoverable: true
            togglable: true
            onActivated: Notifs.open = true
            onToggled: Notifs.toggleDnd(true)

            DashGlyph {
                id: bell
                anchors.centerIn: parent
                size: Theme.dashGlyph
                ink: Theme.accent
                paths: [Theme.bellPath, Theme.bellClapperPath]
                opacity: Notifs.dnd ? 0 : 1
                scale: bellScale.shaped

                ScaleSpring {
                    id: bellScale
                    size: Theme.dashGlyph
                    response: Theme.glideResponse
                    target: Notifs.dnd ? Theme.dashSwapScale : 1
                }

                Behavior on opacity {
                    NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                }

                Rectangle {
                    width: Theme.dashNoteDot + 2 * Theme.dashNoteDotRing
                    height: width
                    radius: width / 2
                    x: bell.width - width
                    y: -Theme.dashNoteDotRing
                    color: Theme.bg
                    opacity: root.notes > 0 ? 1 : 0
                    visible: opacity > 0.004
                    antialiasing: true

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: Theme.dashNoteDot
                        height: width
                        radius: width / 2
                        color: Theme.accent
                        antialiasing: true
                    }
                }
            }

            DashGlyph {
                anchors.centerIn: parent
                size: Theme.dashGlyph
                ink: Theme.accent
                fill: true
                paths: [Theme.moonPath]
                opacity: Notifs.dnd ? 1 : 0
                scale: moonScale.shaped
                rotation: moonTurn.shaped

                ScaleSpring {
                    id: moonScale
                    size: Theme.dashGlyph
                    response: Theme.glideResponse
                    target: Notifs.dnd ? 1 : Theme.dashSwapScale
                }

                Spring {
                    id: moonTurn
                    response: Theme.glideResponse
                    settle: Theme.turnSettle(Theme.dashGlyph)
                    target: Notifs.dnd ? 0 : Theme.dashSwapTurn
                }

                Behavior on opacity {
                    NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                }
            }
        }
    }

    DashRow {
        anchors.right: parent.right
        y: root.row2y
        height: Theme.dashRow2H

        DashCell {
            shown: Theme.dashNet
            gap: Theme.dashStatusGap
            contentW: sig.width
            origin: root.origin("wifi")
            hoverable: true
            togglable: true
            onActivated: Net.open = true
            onToggled: Net.requestPower()

            WifiModule {
                id: sig
                anchors.centerIn: parent
                tint: Theme.mix(root.wifiIdleInk, root.wifiInk, root.wifiHands ? root.clockT : 1)
            }
        }

        DashCell {
            shown: Theme.dashBt
            gap: Theme.dashStatusGap
            contentW: Theme.dashGlyph
            hoverable: true
            togglable: true
            onActivated: Bt.open = true
            onToggled: Bt.toggleAdapter()

            DashGlyph {
                anchors.centerIn: parent
                size: Theme.dashBtGlyph
                ink: Bt.enabled ? Theme.accent : root.dim
                paths: Bt.enabled ? [Theme.btGlyphPath] : [Theme.btGlyphPath, Theme.dashBtSlashPath]
            }
        }

        DashCell {
            shown: Theme.dashVolume
            gap: Theme.dashStatusGap
            contentW: Theme.dashVolW
            hoverable: true
            onActivated: Mixer.open = true

            DashGlyph {
                anchors.verticalCenter: parent.verticalCenter
                x: 0
                size: Theme.dashGlyph
                ink: Theme.accent
                fill: true
                paths: [Theme.audioSpeakerPath]
                strokePaths: {
                    const out = []
                    if (root.waveTier >= 1) out.push(Theme.audioWave1Path)
                    if (root.waveTier >= 2) out.push(Theme.audioWave2Path)
                    if (Audio.outMuted) out.push(Theme.audioSlashPath)
                    return out
                }
            }
        }
    }
}

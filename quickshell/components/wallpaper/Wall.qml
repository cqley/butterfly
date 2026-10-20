import "../core"
import Qt.labs.folderlistmodel
import QtQuick
import Quickshell
import Quickshell.Widgets

Fade {
    id: root
    property int cursor: 0
    property bool snap: false
    property real trackX: 0
    property real focusPos: cursor
    property real vel: Theme.wallVelocity
    property int trackDur: Theme.glide
    property var files: []
    readonly property int n: files.length
    readonly property int sel: n ? ((cursor % n) + n) % n : 0
    readonly property int step: Theme.thumbW + Theme.thumbGap
    readonly property real viewW: Theme.wallW - 2 * Theme.wallPad
    readonly property int win: Theme.wallN + Theme.wallPreload * 2
    readonly property real centerIndex: n ? ((viewW - Theme.thumbW) / 2 - trackX) / step : 0
    readonly property int winStart: n ? Math.round(centerIndex) - Math.floor(win / 2) : 0

    Behavior on trackX {
        NumberAnimation {
            duration: root.snap ? 0 : root.trackDur
            easing.type: Theme.ease
        }
    }

    Behavior on focusPos {
        NumberAnimation {
            duration: root.snap ? 0 : Theme.feedbackDuration
            easing.type: Theme.ease
        }
    }

    width: viewW
    height: Theme.wallTrackH
    focus: shown

    FolderListModel {
        id: folder
        folder: Theme.wallDir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif"]
        showDirs: false
        showDotAndDotDot: false
        caseSensitive: false
        sortField: FolderListModel.Name
        onCountChanged: root.rebuild()
    }

    function centerFor(i) {
        return Math.round((viewW - Theme.thumbW) / 2 - i * step)
    }

    function rebuild() {
        const a = []
        for (let i = 0; i < folder.count; i++)
            a.push({ path: folder.get(i, "filePath"), name: folder.get(i, "fileName") })
        if (a.length === files.length && a.every((f, i) => f.path === files[i].path))
            return
        const keep = a.length === files.length && a.length > 0
        files = a
        if (!keep)
            reset()
    }

    function go(i, instant) {
        snap = instant
        cursor = i
        const x = centerFor(i)
        const dist = Math.abs(x - trackX)
        vel = Math.max(Theme.wallVelocity, (dist - 3 * step) * Theme.wallCatchup)
        trackDur = dist > 0 ? Math.round(dist / vel * 1000) : Theme.fast
        trackX = x
        snap = false
    }

    function move(d) {
        if (!n) return
        go(cursor + d, false)
    }

    function jump(i) {
        if (!n) return
        go(Math.max(0, Math.min(n - 1, i)), false)
    }

    function apply() {
        if (!n) return
        Quickshell.execDetached(Theme.wallCmd.concat([files[sel].path]))
        Wallpaper.open = false
    }

    function reset() {
        go(0, true)
    }

    onVisibleChanged: {
        if (visible) {
            rebuild()
            forceActiveFocus()
            reset()
        } else {
            reset()
        }
    }

    Connections {
        target: Wallpaper
        function onOpenChanged() {
            if (!Wallpaper.open) return
            root.reset()
            root.forceActiveFocus()
        }
    }

    Keys.onPressed: e => {
        if (e.isAutoRepeat) {
            e.accepted = true
            return
        }
        const k = e.key
        const s = e.modifiers & Qt.ShiftModifier
        if (k === Qt.Key_Escape) Wallpaper.open = false
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) root.apply()
        else if (k === Qt.Key_Right || k === Qt.Key_Down || k === Qt.Key_L || k === Qt.Key_J || k === Qt.Key_Tab) root.move(1)
        else if (k === Qt.Key_Left || k === Qt.Key_Up || k === Qt.Key_H || k === Qt.Key_K || k === Qt.Key_Backtab) root.move(-1)
        else if (k === Qt.Key_PageDown) root.move(1)
        else if (k === Qt.Key_PageUp) root.move(-1)
        else if (k === Qt.Key_End || k === Qt.Key_G && s) root.jump(root.n - 1)
        else if (k === Qt.Key_Home || k === Qt.Key_G) root.jump(0)
        else return
        e.accepted = true
    }

    Item {
        width: parent.width
        height: Theme.wallTrackH
        clip: true

        Item {
            id: track
            x: root.trackX
            height: parent.height
            width: parent.width

            Repeater {
                model: root.n > 0 ? root.win : 0

                Item {
                    id: cell
                    required property int index
                    readonly property int abs: root.winStart + (((index - root.winStart) % root.win) + root.win) % root.win
                    readonly property int realIdx: root.n ? ((abs % root.n) + root.n) % root.n : 0
                    readonly property real dist: Math.abs(abs - root.centerIndex)
                    readonly property real glow: Math.max(0, 1 - dist)
                    readonly property real glowFast: Math.max(0, 1 - Math.abs(abs - root.focusPos))
                    readonly property var info: root.files[realIdx]

                    x: abs * root.step
                    width: Theme.thumbW
                    height: parent.height

                    Item {
                        id: thumb
                        readonly property int dir: cell.abs > root.centerIndex ? 1 : cell.abs < root.centerIndex ? -1 : 0
                        x: dir * Theme.wallFocusGap * Math.min(1, cell.dist)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.thumbW
                        height: Theme.thumbH
                        transformOrigin: Item.Center
                        scale: cell.glowFast > 0
                            ? 1 + (Theme.wallFocusScale - 1) * cell.glowFast
                            : (area.pressed ? Theme.feedbackPressScale : area.containsMouse ? Theme.feedbackHoverScale : 1)
                        z: cell.glowFast

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Theme.wallBleed
                            radius: Theme.wallRadius - Theme.wallBleed
                            color: Theme.chip
                            antialiasing: true
                        }

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: Theme.wallRadius
                            color: "transparent"

                            StableImage {
                                anchors.fill: parent
                                retries: Theme.wallRetries
                                source: cell.info ? Theme.url(cell.info.path) : ""
                                fillMode: Image.PreserveAspectCrop
                                retain: false
                                sourceSize: Qt.size(Theme.wallSourceW, Theme.wallSourceH)
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.wallRadius
                            color: "transparent"
                            border.width: Theme.surfaceBorderWidth
                            border.color: Theme.wallIdleBorder
                            opacity: 1 - cell.glowFast
                            antialiasing: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -Theme.wallRing
                            radius: Theme.wallRadius + Theme.wallRing
                            color: "transparent"
                            border.width: Theme.wallRing + Theme.wallBleed
                            border.color: Theme.accent
                            opacity: cell.glowFast
                            antialiasing: true
                        }
                    }

                    MouseArea {
                        id: area
                        x: thumb.x
                        width: Theme.thumbW
                        height: parent.height
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.go(cell.abs, false)
                            root.apply()
                        }
                    }
                }
            }
        }
    }
}

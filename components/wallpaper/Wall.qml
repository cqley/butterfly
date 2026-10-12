import "../core"
import Qt.labs.folderlistmodel
import QtQuick
import Quickshell
import Quickshell.Widgets

Fade {
    id: root
    property int cursor: 0
    property bool fast: false
    property bool snap: false
    property real trackX: 0
    property real px: -1
    property real py: -1
    property var files: []
    readonly property int n: files.length
    readonly property int sel: n ? ((cursor % n) + n) % n : 0
    readonly property int step: Theme.thumbW + Theme.thumbGap
    readonly property real viewW: Theme.wallW - 2 * Theme.wallPad
    readonly property int win: Theme.wallN + Theme.wallPreload * 2
    readonly property int winStart: {
        if (!n) return 0
        const mid = Math.floor(win / 2)
        return cursor - mid
    }

    width: viewW
    height: col.height
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

    NumberAnimation {
        id: slide
        target: root
        property: "trackX"
        easing.type: Theme.ease
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
        slide.stop()
        snap = instant
        cursor = i
        const x = centerFor(i)
        if (instant) {
            trackX = x
            snap = false
            return
        }
        slide.duration = fast ? Theme.fast : Theme.glide
        slide.to = x
        slide.start()
    }

    function move(d) {
        if (!n) return
        go(cursor + d, false)
    }

    function apply() {
        if (!n) return
        Quickshell.execDetached(Theme.wallCmd.concat([files[sel].path]))
        Wallpaper.open = false
    }

    function reset() {
        px = -1
        py = -1
        go(0, true)
    }

    onVisibleChanged: {
        if (visible) {
            rebuild()
            forceActiveFocus()
            reset()
        } else {
            fast = false
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
        const k = e.key
        root.fast = e.isAutoRepeat
        if (k === Qt.Key_Escape) Wallpaper.open = false
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) root.apply()
        else if (k === Qt.Key_Right || k === Qt.Key_L || k === Qt.Key_Tab) root.move(1)
        else if (k === Qt.Key_Left || k === Qt.Key_H || k === Qt.Key_Backtab) root.move(-1)
        else if (k === Qt.Key_PageDown) root.move(Theme.wallN)
        else if (k === Qt.Key_PageUp) root.move(-Theme.wallN)
        else return
        e.accepted = true
    }

    Keys.onReleased: e => {
        if (!e.isAutoRepeat) root.fast = false
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.wallGap

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "wallpaper"
            font.pixelSize: Theme.fsM
            font.weight: Font.DemiBold
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
                        readonly property bool on: abs === root.cursor
                        readonly property var info: root.files[realIdx]

                        x: abs * root.step
                        width: Theme.thumbW
                        height: parent.height

                        Item {
                            anchors.centerIn: parent
                            width: Theme.thumbW
                            height: Theme.thumbH
                            transformOrigin: Item.Center
                            scale: cell.on ? Theme.wallFocusScale : area.pressed ? Theme.feedbackPressScale : area.containsMouse ? Theme.feedbackHoverScale : 1
                            opacity: cell.on ? 1 : area.containsMouse ? Theme.wallHoverOpacity : Theme.wallIdleOpacity
                            z: cell.on ? 1 : 0

                            Behavior on opacity { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }

                            Behavior on scale {
                                enabled: !root.snap
                                NumberAnimation {
                                    duration: Theme.glide
                                    easing.type: Theme.ease
                                }
                            }

                            ClippingRectangle {
                                anchors.fill: parent
                                radius: Theme.wallRadius
                                color: Theme.chip

                                StableImage {
                                    anchors.fill: parent
                                    source: cell.info ? Theme.url(cell.info.path) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    retain: false
                                    sourceSize: Qt.size(Theme.wallSourceW, Theme.wallSourceH)
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -Theme.wallRing
                                radius: Theme.wallRadius + Theme.wallRing
                                color: "transparent"
                                border.width: cell.on ? Theme.wallRing : 0
                                border.color: Theme.accent
                                antialiasing: true
                            }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: m => {
                                const p = mapToItem(null, m.x, m.y)
                                if (p.x === root.px && p.y === root.py) return
                                root.px = p.x
                                root.py = p.y
                                if (cell.abs !== root.cursor) root.go(cell.abs, false)
                            }
                            onClicked: {
                                root.go(cell.abs, false)
                                root.apply()
                            }
                        }
                    }
                }
            }
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.n > 0 ? root.files[root.sel].name : ""
            elide: Text.ElideMiddle
            opacity: Theme.dimMuted
            font.pixelSize: Theme.fsS
        }
    }

    Wheel {
        anchors.fill: parent
        onStep: n => root.move(n)
    }
}

import "../core"
import Qt.labs.folderlistmodel
import QtQuick
import Quickshell
import Quickshell.Widgets

Panel {
    id: root
    property int cursor: 0
    property bool snap: false
    property real trackTo: 0
    readonly property real trackX: trackMotion.shaped
    property real vel: Theme.wallVelocity
    property int trackDur: Theme.glide
    property var files: []
    property bool applied: false
    readonly property string current: Theme.pal && Theme.pal.wallpaper ? String(Theme.pal.wallpaper) : ""
    readonly property int n: files.length
    readonly property int sel: n ? ((cursor % n) + n) % n : 0
    readonly property int step: Theme.thumbW + Theme.thumbGap
    readonly property real viewW: Theme.wallW - 2 * Theme.wallPad
    readonly property int originX: Math.round((viewW - Theme.thumbW) / 2)
    readonly property int win: Theme.wallN + Theme.wallPreload * 2
    readonly property real centerIndex: n ? (originX - trackX) / step : 0
    readonly property int winStart: n ? Math.round(centerIndex) - Math.floor(win / 2) : 0

    Spring {
        id: trackMotion
        response: Theme.springFor(root.trackDur)
        settle: Theme.springSettle
        snap: root.snap
        target: root.trackTo
    }

    pad: Theme.wallPad
    width: viewW
    height: Theme.wallTrackH
    focus: shown
    owner: Wallpaper
    onFresh: {
        if (Wallpaper.open)
            return
        if (!applied)
            reset()
        applied = false
    }
    onCurrentChanged: if (!visible) reset()

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
        return originX - i * step
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
        vel = Math.max(Theme.wallVelocity, (dist - Theme.wallCatchupSteps * step) * Theme.wallCatchup)
        trackDur = dist > 0 ? Math.round(dist / vel * 1000) : Theme.fast
        trackTo = x
        snap = false
    }

    function move(d) {
        if (!n) return
        go(cursor + d, false)
    }

    function jump(i) {
        if (!n) return
        go(cursor - sel + Math.max(0, Math.min(n - 1, i)), false)
    }

    function apply() {
        if (!n) return
        applied = true
        Wallpaper.set(files[sel].path)
    }

    function reset() {
        const i = Math.max(0, files.findIndex(f => f.path === current))
        if (!n || sel !== i)
            go(i, true)
    }

    onVisibleChanged: if (visible) rebuild()

    Keys.onPressed: e => Binds.run(e, Object.assign(Binds.step(d => root.move(d)), {
        cancel: () => Wallpaper.open = false,
        accept: () => root.apply(),
        pageDown: () => root.move(1),
        pageUp: () => root.move(-1),
        top: () => root.jump(0),
        home: () => root.jump(0),
        bottom: () => root.jump(root.n - 1),
        end: () => root.jump(root.n - 1)
    }))

    Txt {
        anchors.centerIn: parent
        text: "no wallpapers"
        visible: root.n === 0
        opacity: Theme.dimEmpty
    }

    Item {
        x: -Theme.wallEdgeFade
        width: parent.width + 2 * Theme.wallEdgeFade
        height: Theme.wallTrackH
        clip: true

        Item {
            id: track
            x: root.trackX + Theme.wallEdgeFade
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
                    readonly property real glow: Math.max(0, 1 - cell.dist)
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
                        scale: (1 + (Theme.wallFocusScale - 1) * cell.glow) * hoverMotion.shaped
                        z: cell.glow

                        ScaleSpring {
                            id: hoverMotion
                            size: Theme.thumbW
                            target: area.pressed ? Theme.feedbackPressScale : area.containsMouse ? Theme.feedbackHoverScale : 1
                            Component.onCompleted: land(1)
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Theme.wallBleed
                            radius: Theme.inner(Theme.wallRadius, Theme.wallBleed)
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
                            opacity: 1 - cell.glow
                            antialiasing: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -Theme.wallRing
                            radius: Theme.wallRadius + Theme.wallRing
                            color: "transparent"
                            border.width: Theme.wallRing + Theme.wallBleed
                            border.color: Theme.accent
                            opacity: cell.glow
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

        Rectangle {
            width: Theme.wallEdgeFade
            height: parent.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.bg }
                GradientStop { position: 1; color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0) }
            }
        }

        Rectangle {
            x: parent.width - width
            width: Theme.wallEdgeFade
            height: parent.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0) }
                GradientStop { position: 1; color: Theme.bg }
            }
        }
    }
}

import "../core"
import QtQuick
import QtQuick.Shapes
import Quickshell

Pick {
    id: root
    readonly property var items: Notifs.history
    readonly property bool settled: !root.churn
    property var view: []
    property string selKey: ""
    property bool churn: false
    property double now: Date.now()

    n: view.length
    rows: Theme.centerRows
    width: Theme.centerW - 2 * Theme.centerPad
    height: col.height
    focus: shown

    Component.onCompleted: view = items

    Timer {
        id: age
        interval: Theme.centerTick
        repeat: true
        running: root.shown
        onTriggered: root.now = Date.now()
    }

    Timer {
        id: swap
        interval: Theme.fade
        onTriggered: {
            root.hold()
            root.view = root.items
            if (!root.aimSel())
                root.syncSel()
            root.churn = false
        }
    }

    onItemsChanged: {
        if (!shown) {
            view = items
            syncSel()
            return
        }
        churn = true
        swap.restart()
    }

    function run() {
        if (n && view[sel])
            Notifs.forget(view[sel].key)
    }

    function aimSel() {
        if (!n || !pointer.hovered)
            return false
        const i = root.start + Math.floor(pointer.point.position.y / Theme.centerRowH)
        if (i < 0 || i >= n)
            return false
        sel = i
        remember()
        return true
    }

    function fresh() {
        swap.stop()
        churn = false
        now = Date.now()
        view = items
        reset()
        selKey = ""
        remember()
    }

    function remember() {
        if (view[sel])
            selKey = view[sel].key
    }

    function syncSel() {
        if (!n) {
            selKey = ""
            return
        }
        if (selKey !== "") {
            for (let i = 0; i < n; i++) {
                if (view[i] && view[i].key === selKey) {
                    sel = i
                    return
                }
            }
        }
        sel = Math.max(0, Math.min(n - 1, sel))
        remember()
    }

    onVisibleChanged: {
        if (visible)
            forceActiveFocus()
        else
            fresh()
    }

    Connections {
        target: Notifs
        function onOpenChanged() {
            if (!Notifs.open)
                return
            root.fresh()
            root.forceActiveFocus()
        }
    }

    Connections {
        target: root
        function onSelChanged() { root.remember() }
    }

    Keys.onPressed: e => {
        const k = e.key
        if (k === Qt.Key_Escape) Notifs.open = false
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space || k === Qt.Key_Delete || k === Qt.Key_Backspace) run()
        else if (!nav(e)) return
        e.accepted = true
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.listGap

        Row {
            height: Theme.centerHeadH
            anchors.right: parent.right
            anchors.rightMargin: Theme.centerHeadInset
            spacing: Theme.centerBtnGap

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.centerBtn
                height: Theme.centerBtn
                radius: width / 2
                color: Notifs.dnd ? (dndArea.containsMouse ? Theme.dndToneHover : Theme.dndTone)
                    : dndArea.containsMouse ? Theme.tile : Theme.chip
                border.width: Theme.surfaceBorderWidth
                border.color: dndArea.containsMouse ? Theme.surfaceBorderHover : Theme.surfaceBorder
                scale: dndArea.pressed ? Theme.feedbackPressScale : dndArea.containsMouse ? Theme.feedbackHoverScale : 1
                antialiasing: true

                Behavior on color {
                    ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                }

                Behavior on border.color {
                    ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                }

                Behavior on scale {
                    NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                }

                Shape {
                    anchors.centerIn: parent
                    width: Theme.iconGrid
                    height: Theme.iconGrid
                    scale: Theme.centerGlyph / Theme.iconGrid
                    opacity: Notifs.dnd ? 0 : 1
                    preferredRendererType: Shape.CurveRenderer

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                    }

                    ShapePath {
                        strokeWidth: Theme.iconStroke
                        strokeColor: Theme.fg
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathSvg { path: Theme.bellPath }
                        PathSvg { path: Theme.bellClapperPath }
                    }
                }

                Shape {
                    anchors.centerIn: parent
                    width: Theme.iconGrid
                    height: Theme.iconGrid
                    scale: Theme.centerGlyph / Theme.iconGrid
                    opacity: Notifs.dnd ? 1 : 0
                    preferredRendererType: Shape.CurveRenderer

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                    }

                    ShapePath {
                        strokeWidth: -1
                        fillColor: Theme.dndGlyph
                        fillRule: ShapePath.WindingFill
                        PathSvg { path: Theme.moonPath }
                    }
                }

                MouseArea {
                    id: dndArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.toggleDnd()
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.centerBtn
                height: Theme.centerBtn
                radius: width / 2
                color: clearArea.containsMouse ? Theme.tile : Theme.chip
                border.width: Theme.surfaceBorderWidth
                border.color: clearArea.containsMouse ? Theme.surfaceBorderHover : Theme.surfaceBorder
                opacity: root.n === 0 ? Theme.dimHint : 1
                scale: clearArea.pressed ? Theme.feedbackPressScale : clearArea.containsMouse ? Theme.feedbackHoverScale : 1
                antialiasing: true

                Behavior on color {
                    ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                }

                Behavior on border.color {
                    ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                }

                Behavior on opacity {
                    NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                }

                Behavior on scale {
                    NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                }

                Shape {
                    anchors.centerIn: parent
                    width: Theme.iconGrid
                    height: Theme.iconGrid
                    scale: Theme.centerGlyph / Theme.iconGrid
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: Theme.iconStroke
                        strokeColor: clearArea.containsMouse ? Theme.redSoft : Theme.fg
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathSvg { path: Theme.trashPath }

                        Behavior on strokeColor {
                            ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                        }
                    }
                }

                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.n > 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.clear()
                }
            }
        }

        Item {
            id: pane
            width: parent.width
            height: root.n > 0 ? Math.min(root.n, Theme.centerRows) * Theme.centerRowH : Theme.centerEmptyH

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: e => {
                    const max = Math.max(0, root.n - root.rows)
                    if (max <= 0)
                        return
                    root.start = Math.max(0, Math.min(max, root.start + (e.angleDelta.y > 0 ? -1 : 1)))
                }
            }

            Item {
                anchors.fill: parent
                visible: root.n > 0
                clip: true

                HoverHandler { id: pointer }

                ScriptModel {
                    id: noteModel
                    values: root.view
                    objectProp: "key"
                }

                Item {
                    id: list
                    width: parent.width
                    height: root.n * Theme.centerRowH
                    y: -root.start * Theme.centerRowH

                    Behavior on y {
                        NumberAnimation { duration: root.snap ? 0 : root.dur; easing.type: Theme.ease }
                    }

                    Rectangle {
                        x: Theme.selInset
                        y: root.sel * Theme.centerRowH + Theme.selGap / 2
                        width: list.width - Theme.selInset * 2
                        height: Theme.centerRowH - Theme.selGap
                        radius: height / 2
                        color: Theme.selFill
                        border.width: Theme.surfaceBorderWidth
                        border.color: Theme.surfaceBorder
                        antialiasing: true

                        Behavior on y {
                            NumberAnimation { duration: root.snap ? 0 : root.dur; easing.type: Theme.ease }
                        }
                    }

                    Repeater {
                        model: noteModel

                        delegate: Item {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool onscreen: row.index >= root.start && row.index < root.start + root.rows
                            readonly property bool fresh: root.now - row.modelData.time < Theme.centerFresh

                            y: row.index * Theme.centerRowH
                            width: list.width
                            height: Theme.centerRowH

                            MouseArea {
                                anchors.fill: parent
                                enabled: row.onscreen
                                hoverEnabled: row.onscreen
                                cursorShape: Qt.PointingHandCursor
                                onPositionChanged: m => root.aim(mapToItem(null, m.x, m.y), row.index)
                                onClicked: {
                                    root.sel = row.index
                                    Notifs.forget(row.modelData.key)
                                }
                            }

                            Chip {
                                id: icon
                                x: Theme.centerIconX
                                anchors.verticalCenter: parent.verticalCenter
                                picture: row.modelData.picture
                                mark: row.modelData.mark
                                letter: row.modelData.letter
                                kind: row.modelData.kind
                                critical: row.modelData.critical
                                on: row.modelData.on
                                level: row.modelData.level
                            }

                            Item {
                                id: dot
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.centerDotRight
                                anchors.verticalCenter: parent.verticalCenter
                                width: Theme.centerDot
                                height: Theme.centerDot
                                opacity: row.fresh ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                                }

                                Rectangle {
                                    property real pulse: 1

                                    anchors.fill: parent
                                    radius: width / 2
                                    color: Theme.greenSoft
                                    antialiasing: true
                                    opacity: Theme.dotLow + (1 - Theme.dotLow) * pulse

                                    SequentialAnimation on pulse {
                                        running: row.fresh
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

                            Column {
                                anchors.left: icon.right
                                anchors.leftMargin: Theme.centerTextGap
                                anchors.right: dot.left
                                anchors.rightMargin: Theme.centerDotGap
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.centerLineGap

                                Txt {
                                    width: parent.width
                                    text: row.modelData.summary
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    font.weight: Font.DemiBold
                                }

                                Txt {
                                    width: parent.width
                                    text: row.modelData.body !== "" ? row.modelData.body : row.modelData.app
                                    visible: text !== ""
                                    elide: Text.ElideRight
                                    wrapMode: Text.Wrap
                                    maximumLineCount: Theme.centerBodyLines
                                    opacity: Theme.dimSoft
                                    font.pixelSize: Theme.fsS
                                }
                            }
                        }
                    }
                }
            }

            Item {
                anchors.fill: parent
                visible: root.n === 0

                Shape {
                    anchors.centerIn: parent
                    width: Theme.iconGrid
                    height: Theme.iconGrid
                    scale: Theme.centerEmptyGlyph / Theme.iconGrid
                    opacity: Notifs.dnd ? 0 : 1
                    preferredRendererType: Shape.CurveRenderer

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                    }

                    ShapePath {
                        strokeWidth: Theme.glyphStroke(Theme.centerEmptyGlyph)
                        strokeColor: Theme.centerEmptyTone
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathSvg { path: Theme.bellPath }
                        PathSvg { path: Theme.bellClapperPath }
                    }
                }

                Shape {
                    anchors.centerIn: parent
                    width: Theme.iconGrid
                    height: Theme.iconGrid
                    scale: Theme.centerEmptyGlyph / Theme.iconGrid
                    opacity: Notifs.dnd ? 1 : 0
                    preferredRendererType: Shape.CurveRenderer

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                    }

                    ShapePath {
                        strokeWidth: -1
                        fillColor: Theme.centerEmptyTone
                        fillRule: ShapePath.WindingFill
                        PathSvg { path: Theme.moonPath }
                    }
                }
            }
        }
    }
}

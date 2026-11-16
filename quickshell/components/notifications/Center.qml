import "../core"
import QtQuick
import QtQuick.Shapes
import Quickshell

Pick {
    id: root
    readonly property var items: Notifs.history
    property string selKey: ""
    property double now: Date.now()
    property var gone: ({})
    property var faded: ({})
    property real selFade: root.n > 0 ? 1 : 0
    property int shifting: 0
    readonly property bool bellUp: root.n > 0 && bell.opacity > Theme.centerClearFade

    n: view.length
    rows: Theme.centerRows
    pad: Theme.centerPad
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
        id: exit
        interval: Theme.centerExit
        onTriggered: root.apply()
    }

    function apply() {
        exit.stop()
        gone = ({})
        faded = ({})
        const top = start === 0
        view = items
        if (!aimSel())
            syncSel()
        if (top && sel > rows - 1) {
            sel = rows - 1
            start = 0
        }
    }

    onItemsChanged: {
        if (!shown) {
            view = items
            syncSel()
            return
        }
        const live = {}
        for (const it of items)
            live[it.key] = true
        const out = {}
        let any = false
        for (const it of view) {
            if (!live[it.key]) {
                out[it.key] = true
                any = true
            }
        }
        if (!any) {
            apply()
            return
        }
        gone = out
        exit.restart()
        const stay = []
        for (let i = 0; i < view.length; i++)
            if (!out[view[i].key])
                stay.push(i)
        if (stay.length > 0 && out[view[sel] ? view[sel].key : ""])
            sel = stay.reduce((b, i) => Math.abs(i - sel) < Math.abs(b - sel) ? i : b, stay[0])
    }

    function settle(key) {
        if (!gone[key])
            return
        faded[key] = true
        for (const k in gone)
            if (!faded[k])
                return
        apply()
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
        exit.stop()
        gone = ({})
        faded = ({})
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
                scale: dndScale.shaped
                antialiasing: true

                Behavior on color {
                    ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                }

                Behavior on border.color {
                    ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                }

                ScaleSpring {
                    id: dndScale
                    size: Theme.centerBtn
                    target: dndArea.pressed ? Theme.feedbackPressScale : dndArea.containsMouse ? Theme.feedbackHoverScale : 1
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
                scale: clearScale.shaped
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

                ScaleSpring {
                    id: clearScale
                    size: Theme.centerBtn
                    target: clearArea.pressed ? Theme.feedbackPressScale : clearArea.containsMouse ? Theme.feedbackHoverScale : 1
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

            PickList {
                id: list
                pick: root
                rowH: Theme.centerRowH
                values: root.view
                key: "key"
                anchors.fill: parent
                visible: root.n > 0
                highlightOpacity: selShow.shaped

                Spring {
                    id: selShow
                    response: Theme.islandResponse
                    damping: 1
                    hold: Theme.springHold
                    epsilon: Theme.springUnitEps
                    rest: Theme.springUnitStop
                    snap: !root.visible
                    target: root.selFade
                }

                HoverHandler { id: pointer }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool onscreen: row.index >= root.start && row.index < root.start + root.rows
                    readonly property bool fresh: root.now - row.modelData.time < Theme.centerFresh
                    readonly property bool leaving: !!root.gone[row.modelData.key]
                    readonly property bool far: Math.abs(rowY.value - rowY.target) > Theme.centerClear
                    readonly property bool spent: row.leaving && body.opacity <= Theme.centerFaded
                    property bool counted: false
                    property bool popped: true
                    property bool waited: true

                    function tryPop() {
                        if (!row.popped && row.waited && root.shifting === 0 && !root.bellUp)
                            row.popped = true
                    }

                    onFarChanged: {
                        if (row.far === row.counted)
                            return
                        root.shifting += row.far ? 1 : -1
                        row.counted = row.far
                    }
                    onSpentChanged: {
                        if (!row.spent)
                            return
                        const key = row.modelData.key
                        Qt.callLater(() => root.settle(key))
                    }
                    Component.onDestruction: if (row.counted) root.shifting -= 1

                    Connections {
                        target: root
                        function onShiftingChanged() { row.tryPop() }
                        function onBellUpChanged() { row.tryPop() }
                    }

                    Binding {
                        target: root
                        property: "selFade"
                        value: body.opacity
                        when: row.index === root.sel
                    }

                    y: rowY.shaped
                    width: list.width
                    height: Theme.centerRowH

                    Spring {
                        id: rowY
                        response: Theme.glideResponse
                        settle: Theme.springSettle
                        target: row.index * Theme.centerRowH
                    }

                    ScaleSpring {
                        id: pop
                        size: row.width
                        response: Theme.islandResponse
                        damping: pop.target < 1 || !Theme.menuBounce ? Theme.islandDamping : Theme.menuBounceDamping
                        target: row.popped && !row.leaving ? 1 : Theme.centerPopFrom
                    }

                    Timer {
                        id: popWait
                        interval: Theme.centerEnterDelay
                        onTriggered: {
                            row.waited = true
                            row.tryPop()
                        }
                    }

                    Component.onCompleted: {
                        if (!root.visible)
                            return
                        row.popped = false
                        row.waited = false
                        pop.land(Theme.centerPopFrom)
                        popWait.start()
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: row.onscreen && !row.leaving
                        hoverEnabled: row.onscreen && !row.leaving
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPositionChanged: m => root.aim(mapToItem(null, m.x, m.y), row.index)
                        onClicked: e => {
                            root.sel = row.index
                            if (e.button === Qt.RightButton)
                                Notifs.focusEntry(row.modelData.key)
                            else
                                Notifs.forget(row.modelData.key)
                        }
                    }

                    Item {
                        id: body
                        width: row.width
                        height: row.height
                        transformOrigin: Item.Center
                        scale: pop.shaped
                        opacity: Math.max(0, Math.min(1, (pop.shaped - Theme.centerPopFrom) / (1 - Theme.centerPopFrom)))

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
                                    running: row.fresh && root.shown
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

            Item {
                id: bell
                width: parent.width
                height: Theme.centerEmptyH
                transformOrigin: Item.Center
                scale: bellPop.shaped
                opacity: Math.max(0, Math.min(1, (bellPop.shaped - Theme.centerPopFrom) / (1 - Theme.centerPopFrom)))
                visible: opacity > 0.004

                ScaleSpring {
                    id: bellPop
                    size: Theme.centerEmptyGlyph
                    snap: !root.visible
                    response: Theme.islandResponse
                    damping: bellPop.target < 1 || !Theme.menuBounce ? Theme.islandDamping : Theme.menuBounceDamping
                    target: root.n === 0 ? 1 : Theme.centerPopFrom
                }

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

            Wheel {
                anchors.fill: parent
                onStep: n => {
                    const max = Math.max(0, root.n - root.rows)
                    if (max <= 0)
                        return
                    root.start = Math.max(0, Math.min(max, root.start + n))
                }
            }
        }
    }
}

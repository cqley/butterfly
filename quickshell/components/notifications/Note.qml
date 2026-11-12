import "../core"
import QtQuick
import QtQuick.Shapes
import Quickshell.Services.Notifications

Panel {
    id: root
    property var n
    property var shownN: null
    property bool churn: false
    readonly property bool settled: !root.churn
    property bool expanded: false
    property string summary: ""
    property string body: ""
    property string appLabel: ""
    property string letter: "?"
    property string kind: ""
    property string picture: ""
    property string mark: ""
    property bool critical: false
    readonly property bool bluetooth: root.kind === "bluetooth"
    property bool charging: false
    property bool netOn: false
    property bool btConnected: false
    property bool dndOn: false
    property real level: -1
    readonly property bool hasLevel: bluetooth && level >= 0
    readonly property int sideReserve: hasLevel ? Theme.noteBtBadge + Theme.noteTextGap : 0
    readonly property int textX: Theme.noteIconX + Theme.noteIcon + Theme.noteTextGap
    readonly property int openTextW: Theme.noteOpenW - root.textX - Theme.noteTextRight - root.sideReserve
    readonly property int briefTextW: Theme.noteW - root.textX - Theme.noteTextRight - root.sideReserve
    property bool sized: true
    readonly property bool hasBody: root.body !== ""
    readonly property bool hasLabel: root.appLabel !== ""
    readonly property real briefH: titleBrief.implicitHeight + (root.hasBody ? Theme.noteLineGap + bodyLine.implicitHeight : 0)
    readonly property int briefY: Math.round(Theme.noteTop + (Theme.noteIcon - root.briefH) / 2)
    readonly property int openY: Theme.noteTop + (root.hasLabel ? Math.round(label.implicitHeight) + Theme.noteLineGap : 0)
    readonly property real openBottom: root.openY + titleBrief.implicitHeight + (root.hasBody ? Theme.noteLineGap + bodyFull.implicitHeight : 0)
    readonly property real wanted: Math.max(Theme.noteH, Math.ceil(root.openBottom + Theme.noteTop))
    readonly property bool grown: root.expanded && root.sized
    readonly property int textY: Math.round(slide.shaped)
    readonly property int bodyY: root.textY + Math.round(titleBrief.implicitHeight) + Theme.noteLineGap

    wantW: root.expanded ? Theme.noteOpenW : Theme.noteW
    wantH: root.expanded ? root.wanted : Theme.noteH
    width: root.wantW
    height: heightMotion.shaped

    Spring {
        id: heightMotion
        response: Theme.speedResponse
        settle: Theme.springSettle
        target: root.wantH
    }

    Spring {
        id: slide
        response: Theme.islandResponse
        damping: Theme.islandDamping
        hold: Theme.dashMorphHold
        target: root.expanded ? root.openY : root.briefY
    }

    function refresh() {
        const n = root.shownN
        if (!n)
            return

        summary = Notifs.plain(n.summary)
        body = Notifs.plain(n.body)
        const k = n.system ? String(n.kind || "") : ""
        const good = !!n.charging
        kind = k
        charging = k === "battery" && good
        netOn = k === "net" && good
        btConnected = k === "bluetooth" && good
        dndOn = k === "dnd" && good
        level = n.system && isFinite(Number(n.level)) ? Number(n.level) : -1
        critical = n.urgency === NotificationUrgency.Critical

        const name = String(n.appName || "").trim()
        const own = k !== ""
        appLabel = own ? "system" : name.toLowerCase()
        letter = ((name || "?")[0] || "?").toLowerCase()
        picture = own ? "" : Notifs.fileUrl(n.image)
        mark = own ? "" : (Notifs.fileUrl(n.appIcon) || Notifs.fileUrl(n.desktopEntry))
        chip.refresh()
    }

    function adopt() {
        root.churn = false
        root.shownN = root.n
        root.refresh()
    }

    onNChanged: {
        if (root.n && root.shownN && root.n !== root.shownN) {
            root.churn = true
            swap.restart()
            return
        }
        root.adopt()
    }

    Timer {
        id: swap
        interval: Theme.fade
        onTriggered: root.adopt()
    }

    Connections {
        target: root.shownN && !root.shownN.system ? root.shownN : null
        ignoreUnknownSignals: true
        function onSummaryChanged() { root.refresh() }
        function onBodyChanged() { root.refresh() }
        function onAppNameChanged() { root.refresh() }
        function onAppIconChanged() { root.refresh() }
        function onImageChanged() { root.refresh() }
        function onUrgencyChanged() { root.refresh() }
    }

    Chip {
        id: chip
        x: Theme.noteIconX
        y: Theme.noteTop
        picture: root.picture
        mark: root.mark
        letter: root.letter
        kind: root.kind
        critical: root.critical
        on: root.charging || root.netOn || root.btConnected || root.dndOn
        level: root.level
    }

    Shape {
        id: btBadge
        anchors.right: parent.right
        anchors.rightMargin: Theme.noteTextRight
        anchors.verticalCenter: chip.verticalCenter
        width: Theme.noteBtBadge
        height: Theme.noteBtBadge
        visible: root.hasLevel
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: Theme.noteBtRingWidth
            strokeColor: Theme.noteBtTrack
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: btBadge.width / 2
                centerY: btBadge.height / 2
                radiusX: (btBadge.width - Theme.noteBtRingWidth) / 2
                radiusY: (btBadge.height - Theme.noteBtRingWidth) / 2
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeWidth: Theme.noteBtRingWidth
            strokeColor: Theme.green
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap

            PathAngleArc {
                centerX: btBadge.width / 2
                centerY: btBadge.height / 2
                radiusX: (btBadge.width - Theme.noteBtRingWidth) / 2
                radiusY: (btBadge.height - Theme.noteBtRingWidth) / 2
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(1, root.level))
            }
        }
    }

    Item {
        id: words
        x: root.textX
        width: root.openTextW
        height: parent.height

        Fade {
            shown: root.grown
            rise: Theme.speed

            Txt {
                id: label
                y: Theme.noteTop
                width: words.width
                text: root.appLabel
                visible: root.hasLabel
                elide: Text.ElideRight
                maximumLineCount: 1
                opacity: Theme.dimEmpty
                font.pixelSize: Theme.fsXS
                font.weight: Font.Medium
            }
        }

        Item {
            id: lineFade
            opacity: root.expanded && fullFade.opacity >= 1 ? 0 : 1

            Behavior on opacity {
                id: lineEase

                NumberAnimation {
                    duration: lineEase.targetValue > 0 ? Theme.fall : Theme.speed
                    easing.type: Theme.ease
                }
            }

            Txt {
                id: titleBrief
                y: root.textY
                width: root.briefTextW
                text: root.summary
                elide: Text.ElideRight
                maximumLineCount: 1
                font.pixelSize: Theme.fsM
                font.weight: Font.DemiBold
            }

            Txt {
                id: bodyLine
                y: root.bodyY
                width: root.briefTextW
                text: root.body
                visible: root.hasBody
                elide: Text.ElideRight
                maximumLineCount: Theme.noteBodyLines
                color: Theme.mix(Theme.bg, Theme.fg, Theme.dimSoft)
                font.pixelSize: Theme.fsS
            }
        }

        Item {
            id: fullFade
            opacity: (root.expanded ? root.grown : lineFade.opacity < 1) ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                id: fullEase

                NumberAnimation {
                    duration: fullEase.targetValue > 0 ? Theme.speed : Theme.fall
                    easing.type: Theme.ease
                }
            }

            Txt {
                y: root.textY
                width: root.openTextW
                text: root.summary
                elide: Text.ElideRight
                maximumLineCount: 1
                font.pixelSize: Theme.fsM
                font.weight: Font.DemiBold
            }

            Txt {
                id: bodyFull
                y: root.bodyY
                width: root.openTextW
                text: root.body
                visible: root.hasBody
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: Theme.noteOpenBodyLines
                color: Theme.mix(Theme.bg, Theme.fg, Theme.dimSoft)
                font.pixelSize: Theme.fsS
            }
        }
    }
}

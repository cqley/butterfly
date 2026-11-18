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
    readonly property color levelTone: root.level <= Theme.batYellowAt ? Theme.batTone(root.level) : Theme.green
    readonly property int sideReserve: !hasLevel ? 0 : (Theme.noteBtPercent ? Math.ceil(btPct.implicitWidth) : Theme.noteBtBadge) + Theme.noteTextGap
    readonly property int textX: Theme.noteIconX + Theme.noteIcon + Theme.noteTextGap
    readonly property int openTextW: Theme.noteOpenW - root.textX - Theme.noteTextRight - root.sideReserve
    readonly property int briefTextW: Theme.noteW - root.textX - Theme.noteTextRight - root.sideReserve
    property bool sized: true
    readonly property bool hasBody: root.body !== ""
    readonly property bool hasLabel: root.appLabel !== ""
    readonly property real briefH: shared.title.implicitHeight + (root.hasBody ? Theme.noteLineGap + shared.body.implicitHeight : 0)
    readonly property int briefY: Math.round(Theme.noteTop + (Theme.noteIcon - root.briefH) / 2)
    readonly property int openY: Theme.noteTop + (root.hasLabel ? Math.round(label.implicitHeight) + Theme.noteLineGap : 0)
    readonly property real openBottom: root.openY + shared.title.implicitHeight + (root.hasBody ? Theme.noteLineGap + open.body.implicitHeight : 0)
    readonly property real wanted: Math.max(Theme.noteH, Math.ceil(root.openBottom + Theme.noteTop))
    readonly property bool grown: root.expanded && root.sized
    readonly property int textY: Math.round(slide.shaped)
    readonly property int bodyY: root.textY + Math.round(shared.title.implicitHeight) + Theme.noteLineGap
    readonly property int lineH: Math.round(shared.body.implicitHeight / Math.max(1, shared.body.lineCount))
    readonly property int titleCut: root.cut(root.summary, titleFm)
    readonly property int bodyCut: root.cut(root.body, bodyFm)

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
        linked: root.btConnected && root.hasBody
        level: root.level
    }

    Shape {
        id: btBadge
        anchors.right: parent.right
        anchors.rightMargin: Theme.noteTextRight
        anchors.verticalCenter: chip.verticalCenter
        width: Theme.noteBtBadge
        height: Theme.noteBtBadge
        visible: root.hasLevel && !Theme.noteBtPercent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: Theme.noteBtRingWidth
            strokeColor: Qt.rgba(root.levelTone.r, root.levelTone.g, root.levelTone.b, Theme.noteBtTrack)
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
            strokeColor: root.levelTone
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

    Txt {
        id: btPct
        anchors.right: parent.right
        anchors.rightMargin: Theme.noteTextRight - Theme.noteBtPctBearing
        anchors.verticalCenter: chip.verticalCenter
        visible: root.hasLevel && Theme.noteBtPercent
        text: Math.round(root.level * 100) + "%"
        color: root.level <= Theme.batYellowAt ? root.levelTone : Theme.mix(Theme.bg, Theme.fg, Theme.dimSoft)
        font.pixelSize: Theme.fsS
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

        Pane {
            width: root.titleCut
            height: root.bodyY

            Brief {
                id: shared
            }
        }

        Pane {
            y: root.bodyY
            width: root.bodyCut
            height: root.lineH
            visible: root.hasBody

            Brief {
                y: -root.bodyY
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

            Pane {
                x: root.titleCut
                width: words.width - root.titleCut
                height: root.bodyY

                Brief {
                    x: -root.titleCut
                }
            }

            Pane {
                x: root.bodyCut
                y: root.bodyY
                width: words.width - root.bodyCut
                height: root.lineH

                Brief {
                    x: -root.bodyCut
                    y: -root.bodyY
                }
            }

            Pane {
                y: root.bodyY + root.lineH
                width: words.width
                height: words.height

                Brief {
                    y: -root.bodyY - root.lineH
                }
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

            Pane {
                x: root.titleCut
                width: words.width - root.titleCut
                height: root.bodyY

                Full {
                    x: -root.titleCut
                }
            }

            Pane {
                x: root.bodyCut
                y: root.bodyY
                width: words.width - root.bodyCut
                height: root.lineH

                Full {
                    x: -root.bodyCut
                    y: -root.bodyY
                }
            }

            Pane {
                y: root.bodyY + root.lineH
                width: words.width
                height: words.height

                Full {
                    id: open
                    y: -root.bodyY - root.lineH
                }
            }
        }
    }

    function cut(text, fm) {
        const w = root.briefTextW
        if (fm.font && fm.advanceWidth(text) <= w)
            return root.openTextW
        const room = w - fm.advanceWidth("…")
        let i = text.lastIndexOf(" ")
        while (i > 0 && fm.advanceWidth(text.substring(0, i)) > room)
            i = text.lastIndexOf(" ", i - 1)
        if (i > 0)
            return Math.round(fm.advanceWidth(text.substring(0, i)) + fm.advanceWidth(" ") / 2)
        let k = 0
        while (k < text.length && fm.advanceWidth(text.substring(0, k + 1)) <= room)
            k++
        return Math.floor(fm.advanceWidth(text.substring(0, k)))
    }

    FontMetrics {
        id: titleFm
        font: shared.title.font
    }

    FontMetrics {
        id: bodyFm
        font: shared.body.font
    }

    component Pane: Item {
        clip: true
        visible: width > 0 && height > 0
    }

    component Brief: Item {
        property alias title: briefTitle
        property alias body: briefBody

        Txt {
            id: briefTitle
            y: root.textY
            width: root.briefTextW
            text: root.summary
            elide: Text.ElideRight
            maximumLineCount: 1
            font.pixelSize: Theme.fsM
            font.weight: Font.DemiBold
        }

        Txt {
            id: briefBody
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

    component Full: Item {
        property alias body: openBody

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
            id: openBody
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

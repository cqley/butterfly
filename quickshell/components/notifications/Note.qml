import "../core"
import QtQuick
import QtQuick.Shapes
import Quickshell.Services.Notifications

Fade {
    id: root
    property var n
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
    readonly property real wanted: Math.max(Theme.noteH, more.y + more.height + Theme.noteTop)
    readonly property int sideReserve: hasLevel ? Theme.noteBtBadge + Theme.noteTextGap : 0

    width: root.expanded ? Theme.noteOpenW : Theme.noteW
    height: root.expanded ? root.wanted : Theme.noteH

    Behavior on width {
        NumberAnimation { duration: Theme.speed; easing.type: Theme.ease }
    }

    Behavior on height {
        NumberAnimation { duration: Theme.speed; easing.type: Theme.ease }
    }

    function refresh() {
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

    onNChanged: refresh()

    Connections {
        target: root.n && !root.n.system ? root.n : null
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

    Fade {
        anchors.fill: parent
        shown: !root.expanded

        Column {
            x: chip.x + chip.width + Theme.noteTextGap
            y: Theme.noteTop + (Theme.noteIcon - height) / 2
            width: Theme.noteW - x - Theme.noteTextRight - root.sideReserve
            spacing: Theme.noteLineGap

            Txt {
                width: parent.width
                text: root.summary
                elide: Text.ElideRight
                maximumLineCount: 1
                font.pixelSize: Theme.fsM
                font.weight: Font.DemiBold
            }

            Txt {
                width: parent.width
                text: root.body
                visible: text !== ""
                elide: Text.ElideRight
                maximumLineCount: Theme.noteBodyLines
                opacity: Theme.dimSoft
                font.pixelSize: Theme.fsS
            }
        }
    }

    Fade {
        anchors.fill: parent
        shown: root.expanded

        Column {
            id: more
            x: chip.x + chip.width + Theme.noteTextGap
            y: Theme.noteTop
            width: Theme.noteOpenW - x - Theme.noteTextRight - root.sideReserve
            spacing: Theme.noteLineGap

            Txt {
                width: parent.width
                text: root.appLabel
                visible: text !== ""
                elide: Text.ElideRight
                maximumLineCount: 1
                opacity: Theme.dimEmpty
                font.pixelSize: Theme.fsXS
                font.weight: Font.Medium
            }

            Txt {
                width: parent.width
                text: root.summary
                elide: Text.ElideRight
                maximumLineCount: 1
                font.pixelSize: Theme.fsM
                font.weight: Font.DemiBold
            }

            Txt {
                width: parent.width
                text: root.body
                visible: text !== ""
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: Theme.noteOpenBodyLines
                opacity: Theme.dimSoft
                font.pixelSize: Theme.fsS
            }
        }
    }
}

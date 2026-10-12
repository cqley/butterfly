import "../core"
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

Fade {
    id: root
    property var n
    property bool expanded: false
    property string summary: ""
    property string body: ""
    property string appLabel: ""
    property string letter: "?"
    property string source: ""
    property string picture: ""
    property string mark: ""
    property bool critical: false
    property bool battery: false
    property bool charging: false
    readonly property real wanted: Math.max(Theme.noteH, more.y + more.height + Theme.noteTop)

    anchors.fill: parent

    function plain(text) {
        return String(text || "")
            .replace(/^\s*<a[^>]*>.*?<\/a>\s*/i, "")
            .replace(/<[^>]*>/g, "")
            .replace(/\s+/g, " ")
            .trim()
    }

    function fileUrl(value) {
        const v = String(value || "").trim()
        if (v === "")
            return ""
        if (/^[a-z][a-z0-9+.-]*:/i.test(v))
            return v
        if (v.startsWith("/"))
            return Theme.url(v)
        const hit = Quickshell.iconPath(v, true)
        if (!hit)
            return ""
        if (hit.startsWith("/") || /^[a-z][a-z0-9+.-]*:/i.test(hit))
            return Theme.url(hit)
        return hit
    }

    function refresh() {
        if (!n)
            return

        summary = plain(n.summary)
        body = plain(n.body)
        battery = !!n.system && n.kind === "battery"
        charging = battery && !!n.charging
        critical = n.urgency === NotificationUrgency.Critical

        const name = String(n.appName || "").trim()
        appLabel = battery ? "fairy" : name.toLowerCase()
        letter = ((name || "?")[0] || "?").toLowerCase()
        picture = battery ? "" : fileUrl(n.image)
        mark = battery ? "" : (fileUrl(n.appIcon) || fileUrl(n.desktopEntry))
        source = picture || mark
        if (img.failed)
            img.reload()
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

    ClippingRectangle {
        id: chip
        x: Theme.noteIconX
        y: Theme.noteTop
        width: Theme.noteIcon
        height: Theme.noteIcon
        radius: Theme.noteIconR
        color: root.critical ? Theme.red : Theme.chip

        StableImage {
            id: img
            anchors.fill: parent
            source: root.source
            retries: 2
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(Theme.noteIcon * 2, Theme.noteIcon * 2)
            onFailedChanged: {
                if (failed && root.source === root.picture && root.mark !== "" && root.mark !== root.picture)
                    root.source = root.mark
            }
        }

        Item {
            anchors.centerIn: parent
            width: Theme.noteBatW
            height: Theme.noteBatH
            visible: root.battery

            Rectangle {
                id: batteryBody
                width: Theme.noteBatW - Theme.noteBatNubW - Theme.noteBatGap
                height: Theme.noteBatH
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                radius: Theme.noteBatRadius
                color: Theme.batGreen
                border.color: Theme.fg
                border.width: Theme.noteBatBorder
                antialiasing: true
            }

            Rectangle {
                anchors.left: batteryBody.right
                anchors.leftMargin: Theme.noteBatGap
                anchors.verticalCenter: batteryBody.verticalCenter
                width: Theme.noteBatNubW
                height: Theme.noteBatNubH
                radius: width / 2
                color: Theme.noteBatNubColor
                antialiasing: true
            }

            Shape {
                anchors.centerIn: batteryBody
                width: Theme.noteBatBoltW
                height: Theme.noteBatBoltH
                visible: root.charging
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Theme.fg
                    strokeColor: "transparent"
                    strokeWidth: 0

                    PathSvg {
                        path: "M2.25 0L0.45 2.65H1.72L1.45 6L3.6 3.05H2.2L2.25 0Z"
                    }
                }
            }
        }

        Txt {
            anchors.centerIn: parent
            text: root.letter
            visible: !root.battery && img.showPlaceholder
            font.pixelSize: Theme.fsM
            font.weight: Font.Bold
        }
    }

    Fade {
        anchors.fill: parent
        shown: !root.expanded

        Column {
            x: chip.x + chip.width + Theme.noteTextGap
            width: parent.width - x - Theme.noteTextRight
            anchors.verticalCenter: parent.verticalCenter
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
            width: Theme.noteOpenW - x - Theme.noteTextRight
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

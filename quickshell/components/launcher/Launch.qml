import "../core"
import QtQuick
import Quickshell

Pick {
    id: root
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)
    readonly property var catalog: apps.map(a => ({
        id: String(a.id || a.name || ""),
        app: a,
        name: String(a.name || ""),
        genericName: String(a.genericName || ""),
        comment: String(a.comment || ""),
        keywords: Array.isArray(a.keywords) ? a.keywords.map(String) : [],
        iconName: String(a.icon || "")
    }))
    readonly property var raw: find(input.text)
    property var results: raw
    property var view: results
    property bool churn: false
    readonly property bool settled: !root.churn

    n: view.length
    rows: Theme.rows
    width: Theme.launchW - 2 * Theme.lpad
    height: col.height

    function fuzzy(n, s) {
        let j = 0
        for (let i = 0; i < n.length && j < s.length; i++)
            if (n[i] === s[j]) j++
        return j === s.length
    }

    function find(q) {
        const s = String(q || "").trim().toLowerCase()
        const c = a => Number(Launcher.counts[a.id]) || 0
        const byName = (a, b) => a.name.localeCompare(b.name)
        const apps = root.catalog
        if (!s) {
            const top = apps.filter(a => c(a) > 0).sort((a, b) => c(b) - c(a) || byName(a, b)).slice(0, Theme.rows)
            return top.concat(apps.filter(a => !top.includes(a)).sort(byName))
        }
        const hits = []
        for (const a of apps) {
            const n = a.name.toLowerCase()
            const i = n.indexOf(s)
            const generic = a.genericName.toLowerCase()
            const keywords = a.keywords.join(" ").toLowerCase()
            const haystack = generic + " " + keywords
            const k = i === 0 ? 0 : n.includes(" " + s) ? 1 : i > 0 ? 2 : haystack.includes(s) ? 3 : fuzzy(n, s) ? 4 : -1
            if (k >= 0) hits.push({ a, k })
        }
        return hits.sort((x, y) => x.k - y.k || c(y.a) - c(x.a) || x.a.name.length - y.a.name.length || byName(x.a, y.a)).slice(0, Theme.rows).map(h => h.a)
    }

    readonly property var icons: Object.create(null)

    function iconFor(name) {
        if (!(name in icons))
            icons[name] = src(name)
        return icons[name]
    }

    function src(icon) {
        const value = String(icon || "")
        if (value === "")
            return ""
        return value.startsWith("/") || value.indexOf("://") >= 0 ? Theme.url(value) : Quickshell.iconPath(value, true)
    }

    function clear() {
        reset()
        input.text = ""
    }

    Timer {
        id: swap
        interval: Theme.fade
        onTriggered: {
            root.hold()
            root.view = root.results
            root.churn = false
        }
    }

    function run() {
        const item = view[sel]
        const a = item ? item.app : null
        if (!a) return
        Launcher.bump(item.id)
        if (a.runInTerminal && a.command && a.command.length) Quickshell.execDetached({ command: Theme.terminal.concat(Array.from(a.command)), workingDirectory: a.workingDirectory || "" })
        else a.execute()
        Launcher.open = false
    }

    onRawChanged: {
        const r = results || []
        const key = a => [a && a.id, a && a.name, a && a.comment, a && a.genericName, a && a.iconName].map(String).join("\u0000")
        const changed = raw.length !== r.length || raw.some((a, i) => key(a) !== key(r[i]))
        if (!changed) return
        results = raw
        sel = 0
    }

    onResultsChanged: {
        if (!shown) {
            view = results
            return
        }
        const sameSize = Math.min(results.length, Theme.rows) === Math.min(view.length, Theme.rows)
        if (sameSize) {
            root.hold()
            view = results
            return
        }
        churn = true
        swap.restart()
    }

    onVisibleChanged: {
        if (visible) input.forceActiveFocus()
        else {
            clear()
        }
    }

    Connections {
        target: Launcher
        function onOpenChanged() {
            if (!Launcher.open) return
            clear()
            input.forceActiveFocus()
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.listGap

        Item {
            width: parent.width
            height: Theme.searchH

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Theme.chip
                opacity: input.activeFocus ? Theme.launchSearchFocusOpacity : Theme.launchSearchOpacity
                antialiasing: true

                Behavior on opacity { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
            }

            Item {
                x: Theme.launchSearchIconX
                width: Theme.launchSearchIconBox
                height: Theme.launchSearchIconBox
                anchors.verticalCenter: parent.verticalCenter
                opacity: Theme.launchSearchIconOpacity

                Rectangle {
                    x: Theme.launchSearchLensInset
                    y: Theme.launchSearchLensInset
                    width: Theme.launchSearchLensSize
                    height: Theme.launchSearchLensSize
                    radius: width / 2
                    color: "transparent"
                    border.width: Theme.launchSearchIconBorder
                    border.color: Theme.fg
                    antialiasing: true
                }

                Rectangle {
                    x: Theme.launchSearchHandleX
                    y: Theme.launchSearchHandleY
                    width: Theme.launchSearchHandleW
                    height: Theme.launchSearchHandleH
                    radius: height / 2
                    rotation: Theme.launchSearchHandleRot
                    transformOrigin: Item.Left
                    color: Theme.fg
                    antialiasing: true
                }
            }

            TextInput {
                id: input
                x: Theme.launchSearchTextX
                width: parent.width - Theme.launchSearchTextX - Theme.launchSearchTextRight
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fg
                selectionColor: Theme.accent
                selectedTextColor: Theme.bg
                selectByMouse: true
                font.family: Theme.font
                font.pixelSize: Theme.fsL
                font.weight: Font.Medium
                clip: true

                Keys.onPressed: e => {
                    if (e.isAutoRepeat) {
                        e.accepted = true
                        return
                    }
                    const k = e.key
                    const c = e.modifiers & Qt.ControlModifier
                    const w = true
                    if (k === Qt.Key_Escape) Launcher.open = false
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.run()
                    else if (k === Qt.Key_Down || k === Qt.Key_Tab || c && (k === Qt.Key_J || k === Qt.Key_N)) root.move(1, w)
                    else if (k === Qt.Key_Up || k === Qt.Key_Backtab || c && (k === Qt.Key_K || k === Qt.Key_P)) root.move(-1, w)
                    else if (k === Qt.Key_PageDown) root.move(1, false)
                    else if (k === Qt.Key_PageUp) root.move(-1, false)
                    else if (c && k === Qt.Key_End) root.move(root.n, false)
                    else if (c && k === Qt.Key_Home) root.move(-root.n, false)
                    else return
                    e.accepted = true
                }
            }

            Txt {
                x: input.x
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                visible: input.text === ""
                opacity: Theme.dimGhost
                font.pixelSize: Theme.fsL
            }
        }

        Item {
            id: pane
            width: parent.width
            height: Math.min(root.n, Theme.rows) * Theme.rowH
            clip: true
            visible: root.n > 0

            ScriptModel {
                id: appModel
                values: root.view
                objectProp: "id"
            }

            Item {
                id: list
                width: parent.width
                height: root.n * Theme.rowH
                y: -root.start * Theme.rowH

                Behavior on y {
                    NumberAnimation { duration: root.snap ? 0 : root.dur; easing.type: Theme.ease }
                }

                Repeater {
                    model: appModel

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index

                        y: row.index * Theme.rowH
                        width: list.width
                        height: Theme.rowH

                        readonly property bool selected: root.sel === row.index

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: Theme.selInset
                            anchors.rightMargin: Theme.selInset
                            anchors.verticalCenter: parent.verticalCenter
                            height: Theme.rowH - Theme.selGap
                            radius: height / 2
                            color: Theme.selFill
                            border.width: Theme.surfaceBorderWidth
                            border.color: Theme.surfaceBorder
                            opacity: row.selected ? 1 : 0
                            antialiasing: true

                            Behavior on opacity { NumberAnimation { duration: Theme.selDuration; easing.type: Theme.ease } }
                        }

                        LaunchIcon {
                            id: icon
                            x: Theme.launchIconX
                            anchors.verticalCenter: parent.verticalCenter
                            source: root.iconFor(row.modelData.iconName)
                            fallbackText: row.modelData.name.charAt(0).toLowerCase() || "?"
                            selected: row.selected
                            hovered: area.containsMouse
                            pressed: area.pressed
                        }

                        Column {
                            anchors.left: icon.right
                            anchors.leftMargin: Theme.launchTextGap
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.rowR
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.launchTextRowGap

                            Txt {
                                width: parent.width
                                text: row.modelData.name
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                font.weight: Font.DemiBold
                            }

                            Txt {
                                width: parent.width
                                text: row.modelData.comment || row.modelData.genericName
                                visible: text !== ""
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                opacity: Theme.dimSoft
                                font.pixelSize: Theme.fsXS
                            }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: m => root.aim(mapToItem(null, m.x, m.y), row.index)
                            onClicked: {
                                root.sel = row.index
                                root.run()
                            }
                        }
                    }
                }
            }
        }
    }
}

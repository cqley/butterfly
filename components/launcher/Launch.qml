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

    n: results.length
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

    function run() {
        const item = results[sel]
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

    onVisibleChanged: {
        if (visible) input.forceActiveFocus()
        else {
            root.fast = false
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
                    const k = e.key
                    const c = e.modifiers & Qt.ControlModifier
                    const w = !e.isAutoRepeat
                    root.fast = e.isAutoRepeat
                    if (k === Qt.Key_Escape) Launcher.open = false
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.run()
                    else if (k === Qt.Key_Down || k === Qt.Key_Tab || c && (k === Qt.Key_J || k === Qt.Key_N)) root.move(1, w)
                    else if (k === Qt.Key_Up || k === Qt.Key_Backtab || c && (k === Qt.Key_K || k === Qt.Key_P)) root.move(-1, w)
                    else if (k === Qt.Key_PageDown) root.move(Theme.rows, false)
                    else if (k === Qt.Key_PageUp) root.move(-Theme.rows, false)
                    else return
                    e.accepted = true
                }

                Keys.onReleased: e => {
                    if (!e.isAutoRepeat) root.fast = false
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

        Rule { visible: root.n > 0 }

        Item {
            id: pane
            width: parent.width
            height: list.height
            visible: root.n > 0

            ListView {
                id: list
                width: parent.width
                height: Math.min(root.n, Theme.rows) * Theme.rowH
                clip: true
                interactive: false
                ScriptModel {
                    id: appModel
                    values: root.results
                    objectProp: "id"
                }

                model: appModel
                cacheBuffer: Theme.rowH * Theme.rows * 2
                reuseItems: true
                contentY: root.start * Theme.rowH
                highlightFollowsCurrentItem: false

                Behavior on contentY {
                    enabled: !root.snap
                    NumberAnimation { duration: root.dur; easing.type: Theme.ease }
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index

                    width: list.width
                    height: Theme.rowH

                    readonly property bool selected: root.sel === row.index

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Theme.launchSelectionX
                        anchors.rightMargin: Theme.launchSelectionRight
                        anchors.verticalCenter: parent.verticalCenter
                        height: Theme.launchSelectionH
                        radius: Theme.launchSelectionRadius
                        color: Theme.launchSelectionFill
                        opacity: row.selected ? 1 : 0
                        antialiasing: true

                        Behavior on opacity { NumberAnimation { duration: Theme.launchSelectionDuration; easing.type: Theme.ease } }
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

    Wheel {
        anchors.fill: parent
        onStep: n => root.move(n, false)
    }
}

import "../core"
import QtQuick
import Quickshell.Widgets

Item {
    id: popup
    property bool shown: Settings.open
    readonly property bool alive: pop.value > 0.001 || popup.shown
    readonly property int sidebarContentH: Settings.categories.length * Theme.settingsSidebarItemH
        + Math.max(0, Settings.categories.length - 1) * Theme.settingsSidebarGap
    readonly property real contentProgress: Math.max(0, Math.min(1,
        (pop.value - Theme.settingsContentDelay) / (1 - Theme.settingsContentDelay)))

    width: Theme.settingsW
    height: popup.sidebarContentH + Theme.settingsPad + Theme.settingsPadBottom
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0
    visible: popup.alive
    transformOrigin: Item.Center
    scale: Theme.settingsScaleFrom + (1 - Theme.settingsScaleFrom) * pop.value
    opacity: Math.max(0, Math.min(1, pop.value / Theme.settingsBoxFadeIn))

    transform: Translate {
        y: (1 - pop.value) * Theme.settingsRiseOffset
    }

    Spring {
        id: pop
        target: popup.shown ? 1 : 0
        response: Theme.settingsPopResponse
        damping: Theme.settingsPopDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    onShownChanged: if (shown) keys.forceActiveFocus()

    Shadow {
        anchors.fill: shell
        radius: shell.radius
    }

    ClippingRectangle {
        id: shell
        anchors.fill: parent
        radius: Theme.settingsRadius
        color: Qt.rgba(Theme.settingsBg.r, Theme.settingsBg.g, Theme.settingsBg.b, Theme.settingsBgOpacity)
        border.width: Theme.settingsBorderWidth
        border.color: Qt.rgba(1, 1, 1, Theme.settingsBorderOpacity)

        FocusScope {
            id: keys
            anchors.fill: parent
            focus: popup.shown
            opacity: popup.contentProgress
            scale: Theme.settingsContentScaleFrom + (1 - Theme.settingsContentScaleFrom) * popup.contentProgress

            transform: Translate {
                y: (1 - popup.contentProgress) * Theme.settingsContentRise
            }

            Keys.onPressed: e => {
                Settings.keyNav = true
                if (e.key === Qt.Key_Escape) {
                    Settings.open = false
                    e.accepted = true
                } else if (e.key === Qt.Key_PageDown || e.key === Qt.Key_PageUp) {
                    e.accepted = true
                    if (e.isAutoRepeat)
                        return
                    const dir = e.key === Qt.Key_PageDown ? 1 : -1
                    const maxY = Math.max(0, view.contentHeight - view.height)
                    view.contentY = Math.max(0, Math.min(maxY, view.contentY + dir * view.height))
                }
            }

            FocusScope {
                id: sidebar
                x: Theme.settingsPad
                y: Theme.settingsPad
                width: Theme.settingsSidebarW
                height: parent.height - Theme.settingsPad - Theme.settingsPadBottom
                focus: true

                Rectangle {
                    width: parent.width
                    height: Theme.settingsSidebarItemH
                    y: Math.round(mark.value)
                    radius: Theme.settingsSidebarItemRadius
                    color: Theme.settingsHover
                    border.width: Theme.surfaceBorderWidth
                    border.color: Theme.surfaceBorderHover
                    antialiasing: true

                    Spring {
                        id: mark
                        target: Settings.selected * (Theme.settingsSidebarItemH + Theme.settingsSidebarGap)
                        response: Theme.settingsMoveResponse
                        damping: Theme.settingsMoveDamping
                        epsilon: Theme.settleEps
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.settingsSidebarGap

                    Repeater {
                        model: Settings.categories

                        delegate: SettingsSidebarItem {
                            required property var modelData
                            required property int index
                            icon: modelData.icon
                            label: modelData.label
                            selected: Settings.selected === index
                            focus: index === 0
                            onActivated: Settings.selected = index
                            onSelectedChanged: if (selected && sidebar.activeFocus) forceActiveFocus()
                            onStepped: d => Settings.move(d)
                        }
                    }
                }
            }

            Rectangle {
                x: Math.round(sidebar.x + sidebar.width + (Theme.settingsGap - width) / 2)
                y: Theme.settingsPad
                width: 1
                height: parent.height - Theme.settingsPad - Theme.settingsPadBottom
                color: Theme.settingsDivider
            }

            Item {
                id: contentArea
                x: sidebar.x + sidebar.width + Theme.settingsGap
                y: Theme.settingsPad
                width: parent.width - x - Theme.settingsPad
                height: parent.height - Theme.settingsPad - Theme.settingsPadBottom
                clip: true

                Item {
                    id: stage
                    anchors.fill: parent

                    property int shownIndex: Settings.selected
                    property bool churn: false

                    function retarget(to, ms) {
                        pageFade.stop()
                        pageFade.duration = ms
                        pageFade.to = to
                        pageFade.start()
                    }

                    function reveal() {
                        if (!stage.churn && view.ready && view.opacity < 1)
                            stage.retarget(1, Theme.rise)
                    }

                    Component.onCompleted: stage.reveal()

                    Connections {
                        target: Settings
                        function onSelectedChanged() {
                            stage.churn = true
                            stage.retarget(0, Theme.fall)
                        }
                    }

                    NumberAnimation {
                        id: pageFade
                        target: view
                        property: "opacity"
                        easing.type: Theme.ease

                        onFinished: {
                            if (!stage.churn)
                                return
                            stage.shownIndex = Settings.selected
                            stage.churn = false
                            stage.reveal()
                        }
                    }

                    SettingsPageView {
                        id: view
                        anchors.fill: parent
                        category: Settings.categories[stage.shownIndex]
                        opacity: 0

                        onReadyChanged: stage.reveal()
                    }
                }
            }
        }
    }
}

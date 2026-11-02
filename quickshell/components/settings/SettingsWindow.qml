import "../core"
import QtQuick
import Quickshell.Widgets

Item {
    id: popup
    property bool shown: Settings.open
    readonly property bool alive: pop.value > 0.001 || popup.shown
    readonly property int sidebarContentH: Settings.categories.length * Theme.settingsSidebarItemH
        + Math.max(0, Settings.categories.length - 1) * Theme.settingsSidebarGap

    width: Theme.settingsW
    height: popup.sidebarContentH + Theme.settingsPad + Theme.settingsPadBottom
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0
    visible: popup.alive
    transformOrigin: Item.Center
    scale: Theme.settingsScaleFrom + (1 - Theme.settingsScaleFrom) * pop.value
    opacity: Math.max(0, Math.min(1, pop.value))

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

            Keys.onPressed: e => {
                Settings.keyNav = true
                if (e.key === Qt.Key_Escape) {
                    Settings.open = false
                    e.accepted = true
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
                    color: Theme.settingsSelected
                    border.width: Theme.surfaceBorderWidth
                    border.color: Theme.surfaceBorder
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
                    anchors.rightMargin: Theme.settingsScrollPad

                    property int shownIndex: Settings.selected
                    property bool churn: false
                    readonly property alias scrollRatio: view.scrollRatio
                    readonly property alias scrollH: view.height

                    Connections {
                        target: Settings
                        function onSelectedChanged() {
                            stage.churn = true
                            swapTimer.restart()
                        }
                    }

                    Timer {
                        id: swapTimer
                        interval: Theme.fall
                        onTriggered: {
                            stage.shownIndex = Settings.selected
                            stage.churn = false
                        }
                    }

                    SettingsPageView {
                        id: view
                        anchors.fill: parent
                        category: Settings.categories[stage.shownIndex]
                        opacity: stage.churn ? 0 : 1

                        Behavior on opacity {
                            NumberAnimation {
                                duration: stage.churn ? Theme.fall : Theme.rise
                                easing.type: Theme.ease
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    y: Math.round(stage.scrollRatio.yPosition * stage.scrollH)
                    width: Theme.settingsScrollW
                    height: Math.round(stage.scrollRatio.heightRatio * stage.scrollH)
                    radius: width / 2
                    color: Theme.settingsScroll
                    visible: stage.scrollRatio.heightRatio < 1
                    antialiasing: true
                }
            }
        }
    }
}

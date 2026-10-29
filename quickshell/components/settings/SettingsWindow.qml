import "../core"
import QtQuick
import Quickshell.Widgets

Item {
    id: popup
    property bool shown: Settings.open
    readonly property bool alive: pop.value > 0.001 || popup.shown

    width: Theme.settingsW
    height: Theme.settingsH
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
        duration: Theme.settingsPopDuration
        easing: Theme.ease
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    onShownChanged: if (shown) keys.forceActiveFocus()

    Shadow {
        anchors.fill: shell
        radius: Theme.settingsRadius
    }

    ClippingRectangle {
        id: shell
        anchors.fill: parent
        radius: Theme.settingsRadius
        color: Qt.rgba(Theme.settingsBg.r, Theme.settingsBg.g, Theme.settingsBg.b, Theme.settingsBgOpacity)
        border.width: Theme.settingsBorderWidth
        border.color: Qt.rgba(1, 1, 1, Theme.settingsBorderOpacity)

        Item {
            id: keys
            focus: popup.shown

            Keys.onPressed: e => {
                const k = e.key
                if (k === Qt.Key_Escape) {
                    Settings.open = false
                    e.accepted = true
                } else if (k === Qt.Key_Down || k === Qt.Key_J) {
                    Settings.move(1)
                    e.accepted = true
                } else if (k === Qt.Key_Up || k === Qt.Key_K) {
                    Settings.move(-1)
                    e.accepted = true
                }
            }
        }

        Item {
            id: sidebar
            x: Theme.settingsPad
            y: Theme.settingsPad
            width: Theme.settingsSidebarW
            height: parent.height - 2 * Theme.settingsPad

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
                        onActivated: Settings.selected = index
                    }
                }
            }
        }

        Item {
            id: contentArea
            x: sidebar.x + sidebar.width + Theme.settingsGap
            y: Theme.settingsPad
            width: parent.width - x - Theme.settingsPad
            height: parent.height - 2 * Theme.settingsPad
            clip: true

            Item {
                id: stage
                anchors.fill: parent
                anchors.rightMargin: Theme.settingsScrollPad

                property bool aFront: true
                property var aCategory: Settings.categories[Settings.selected]
                property var bCategory: Settings.categories[Settings.selected]
                readonly property var activeFlick: aFront ? viewA : viewB

                Connections {
                    target: Settings
                    function onSelectedChanged() {
                        const cat = Settings.categories[Settings.selected]
                        if (stage.aFront)
                            stage.bCategory = cat
                        else
                            stage.aCategory = cat
                        stage.aFront = !stage.aFront
                    }
                }

                SettingsPageView {
                    id: viewA
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width
                    category: stage.aCategory
                    opacity: stage.aFront ? 1 : 0
                    x: stage.aFront ? 0 : Theme.settingsSwapSlide

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.settingsSwapDuration; easing.type: Theme.ease }
                    }
                    Behavior on x {
                        NumberAnimation { duration: Theme.settingsSwapDuration; easing.type: Theme.ease }
                    }
                }

                SettingsPageView {
                    id: viewB
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width
                    category: stage.bCategory
                    opacity: stage.aFront ? 0 : 1
                    x: stage.aFront ? -Theme.settingsSwapSlide : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.settingsSwapDuration; easing.type: Theme.ease }
                    }
                    Behavior on x {
                        NumberAnimation { duration: Theme.settingsSwapDuration; easing.type: Theme.ease }
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                y: Math.round(stage.activeFlick.visibleArea.yPosition * stage.activeFlick.height)
                width: Theme.settingsScrollW
                height: Math.round(stage.activeFlick.visibleArea.heightRatio * stage.activeFlick.height)
                radius: width / 2
                color: Theme.settingsScroll
                visible: stage.activeFlick.visibleArea.heightRatio < 1
                antialiasing: true
            }
        }
    }
}

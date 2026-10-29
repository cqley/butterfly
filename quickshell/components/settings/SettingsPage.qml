import "../core"
import QtQuick

Column {
    id: root
    property var category: null
    readonly property string catId: root.category ? root.category.id : ""

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsHeaderCard {
        width: parent.width
        icon: root.category ? root.category.icon : ""
        title: root.category ? root.category.title : ""
        subtitle: root.category ? root.category.subtitle : ""
    }

    SettingsGroup {
        width: parent.width
        visible: root.catId === "general"

        SettingsRow { label: "profile"; value: "shell"; showArrow: true }
        SettingsRow { label: "version"; value: "0.1"; showArrow: true }
    }

    SettingsGroup {
        width: parent.width
        visible: root.catId === "style"

        SettingsRow { label: "theme"; value: "rxyhn"; showArrow: true }
        SettingsRow { label: "wallpaper"; value: "choose…"; showArrow: true }
    }

    Txt {
        visible: root.catId === "style"
        text: "accent"
        font.pixelSize: Theme.settingsSectionPx
        color: Theme.settingsSectionInk
        font.weight: Font.Normal
        leftPadding: Theme.settingsRowPadX
        height: Theme.settingsSectionH
        verticalAlignment: Text.AlignVCenter
    }

    SettingsGroup {
        id: accentGroup
        width: parent.width
        visible: root.catId === "style"
        property int accentIdx: 0

        SettingsRow {
            label: "accent colour"

            SettingsColorDots {
                colors: [Theme.mix(Theme.fg, Theme.bg, 0.3), Theme.red, Theme.green, "#f2c94c", "#5b8def", "#bb6bd9", "#56ccd0"]
                current: accentGroup.accentIdx
                onPicked: i => accentGroup.accentIdx = i
            }
        }

        SettingsRow {
            label: "custom (#rrggbb)"

            Rectangle {
                width: Theme.settingsFieldW
                height: Theme.settingsFieldH
                radius: height / 2
                color: Theme.settingsFieldBg
                border.width: hex.activeFocus ? Theme.feedbackFocusBorder : 0
                border.color: Theme.accent
                antialiasing: true

                Behavior on border.width {
                    NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
                }

                TextInput {
                    id: hex
                    anchors.fill: parent
                    anchors.leftMargin: Theme.settingsRowPadX
                    anchors.rightMargin: Theme.settingsRowPadX
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.bg
                    selectByMouse: true
                    font.family: Theme.font
                    font.pixelSize: Theme.settingsValuePx
                    clip: true
                }
            }
        }

        SettingsRow {
            label: "color burst (a different palette colour per surface)"
            SettingsToggle {}
        }
    }

    Txt {
        visible: root.catId === "style"
        text: "type"
        font.pixelSize: Theme.settingsSectionPx
        color: Theme.settingsSectionInk
        font.weight: Font.Normal
        leftPadding: Theme.settingsRowPadX
        height: Theme.settingsSectionH
        verticalAlignment: Text.AlignVCenter
    }

    SettingsGroup {
        id: typeGroup
        width: parent.width
        visible: root.catId === "style"
        property real fontSize: 15

        SettingsRow {
            label: "font size"
            value: Math.round(typeGroup.fontSize) + " px"

            SettingsSlider {
                from: 10
                to: 20
                value: typeGroup.fontSize
                onMoved: v => typeGroup.fontSize = v
            }
        }
    }

    SettingsGroup {
        id: motionGroup
        width: parent.width
        visible: root.catId === "motion"
        property int styleIdx: 0
        property real speed: 0.5

        SettingsRow {
            label: "animation style"

            SettingsSegmented {
                width: 140
                options: ["spring", "classic"]
                current: motionGroup.styleIdx
                onPicked: i => motionGroup.styleIdx = i
            }
        }

        SettingsRow {
            label: "speed"

            SettingsSlider {
                value: motionGroup.speed
                onMoved: v => motionGroup.speed = v
            }
        }
    }
}

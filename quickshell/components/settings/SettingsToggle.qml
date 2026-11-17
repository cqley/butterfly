import "../core"
import QtQuick

Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool checked)

    readonly property real gap: (height - Theme.settingsToggleKnob) / 2

    function rowActivate() {
        root.toggled(!root.checked)
    }

    width: Theme.settingsToggleW
    height: Theme.settingsToggleH
    radius: Theme.corner(height / 2)
    color: root.checked ? Theme.accent : Theme.settingsTrack
    antialiasing: true
    activeFocusOnTab: true

    Keys.onPressed: e => {
        Settings.keyNav = true
        Binds.run(e, {
            accept: () => root.toggled(!root.checked),
            left: root.checked ? () => root.toggled(false) : null,
            right: root.checked ? null : () => root.toggled(true)
        })
    }

    Behavior on color {
        ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
    }

    SettingsFocus {
        radius: root.radius + Theme.corner(Theme.settingsFocusPad)
        focused: root.activeFocus
    }

    Spring {
        id: knob
        target: root.checked ? 1 : 0
        response: Theme.settingsMoveResponse
        damping: Theme.settingsMoveDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    Rectangle {
        x: root.gap + knob.value * (root.width - width - 2 * root.gap)
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.settingsToggleKnob
        height: Theme.settingsToggleKnob
        radius: Theme.corner(width / 2)
        color: root.checked && !Theme.whiteKnobs ? Theme.settingsBg : Theme.knobInk
        antialiasing: true

        Behavior on color {
            ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Settings.keyNav = false
            root.forceActiveFocus()
            root.toggled(!root.checked)
        }
    }
}

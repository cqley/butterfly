import "../core"
import QtQuick

Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool checked)

    readonly property real gap: (height - Theme.settingsToggleKnob) / 2

    width: Theme.settingsToggleW
    height: Theme.settingsToggleH
    radius: height / 2
    color: root.checked ? Theme.accent : Theme.settingsTrack
    antialiasing: true
    activeFocusOnTab: true

    Keys.onPressed: e => {
        Settings.keyNav = true
        if (e.key === Qt.Key_Space || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            root.toggled(!root.checked)
            e.accepted = true
        } else if (e.key === Qt.Key_Left && root.checked) {
            root.toggled(false)
            e.accepted = true
        } else if (e.key === Qt.Key_Right && !root.checked) {
            root.toggled(true)
            e.accepted = true
        }
    }

    Behavior on color {
        ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
    }

    SettingsFocus {
        radius: root.radius + Theme.settingsFocusPad
        focused: root.activeFocus
    }

    Rectangle {
        x: root.checked ? root.width - width - root.gap : root.gap
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.settingsToggleKnob
        height: Theme.settingsToggleKnob
        radius: width / 2
        color: Theme.fg
        antialiasing: true

        Behavior on x {
            NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
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

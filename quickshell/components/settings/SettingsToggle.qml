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
    color: root.checked ? Theme.accent : Theme.settingsCardAlt
    antialiasing: true

    Behavior on color {
        ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
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
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}

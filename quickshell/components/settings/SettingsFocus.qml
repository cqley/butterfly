import "../core"
import QtQuick

Rectangle {
    property bool focused: false
    property bool always: false
    readonly property bool shown: focused && (always || Settings.keyNav)

    anchors.fill: parent
    anchors.margins: -Theme.settingsFocusPad
    radius: Theme.settingsFocusRadius + Theme.corner(Theme.settingsFocusPad)
    color: "transparent"
    border.width: Theme.settingsFocusWidth
    border.pixelAligned: false
    border.color: Theme.settingsFocusInk
    opacity: shown ? 1 : 0
    visible: opacity > 0
    antialiasing: true

    Behavior on opacity {
        NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
    }
}

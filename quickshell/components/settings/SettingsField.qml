import "../core"
import QtQuick

Rectangle {
    id: root
    property string text: ""
    property string placeholder: ""
    property int limit: 0
    signal committed(string text)

    width: Theme.settingsFieldW
    height: Theme.settingsFieldH
    radius: height / 2
    color: Theme.settingsFieldBg
    antialiasing: true

    onTextChanged: if (!input.activeFocus) input.text = root.text

    SettingsFocus {
        radius: root.radius + Theme.settingsFocusPad
        focused: input.activeFocus
        always: true
    }

    Txt {
        anchors.fill: input
        visible: input.text === ""
        verticalAlignment: Text.AlignVCenter
        text: root.placeholder
        font.pixelSize: Theme.settingsValuePx
        font.weight: Font.Normal
        color: Theme.settingsValueInk
    }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: Theme.settingsRowPadX
        anchors.rightMargin: Theme.settingsRowPadX
        verticalAlignment: TextInput.AlignVCenter
        text: root.text
        maximumLength: root.limit > 0 ? root.limit : 32767
        color: Theme.settingsInk
        selectionColor: Theme.accent
        selectedTextColor: Theme.settingsBg
        selectByMouse: true
        activeFocusOnTab: true
        font.family: Theme.font
        font.pixelSize: Theme.settingsValuePx
        clip: true

        onAccepted: root.committed(input.text)
        onActiveFocusChanged: if (!activeFocus) root.committed(input.text)

        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) {
                input.text = root.text
                input.focus = false
                e.accepted = true
            }
        }
    }
}

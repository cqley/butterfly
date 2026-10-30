import "../core"
import QtQuick

Rectangle {
    id: root
    property var options: []
    property int current: 0
    signal picked(int index)

    readonly property int n: options.length
    readonly property real segW: n ? width / n : 0

    function step(d) {
        if (root.n <= 0)
            return
        root.picked(((root.current + d) % root.n + root.n) % root.n)
    }

    width: Theme.settingsSegW
    height: Theme.settingsSegH
    radius: Theme.settingsSegRadius
    color: Theme.settingsSegBg
    antialiasing: true
    activeFocusOnTab: true

    Keys.onPressed: e => {
        Settings.keyNav = true
        if (e.key === Qt.Key_Left) {
            root.step(-1)
            e.accepted = true
        } else if (e.key === Qt.Key_Right) {
            root.step(1)
            e.accepted = true
        }
    }

    SettingsFocus {
        radius: root.radius + Theme.settingsFocusPad
        focused: root.activeFocus
    }

    Rectangle {
        x: root.segW * root.current
        width: root.segW
        height: parent.height
        radius: parent.radius
        color: Theme.settingsTrack
        antialiasing: true

        Behavior on x {
            NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
        }
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: root.options

            Item {
                id: seg
                required property string modelData
                required property int index

                width: root.segW
                height: root.height

                Txt {
                    anchors.centerIn: parent
                    width: parent.width - Theme.settingsSegPadX
                    text: seg.modelData
                    font.pixelSize: Theme.settingsLabelPx
                    font.weight: root.current === seg.index ? Font.DemiBold : Font.Normal
                    color: Theme.fg
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Settings.keyNav = false
            root.forceActiveFocus()
                        root.picked(seg.index)
                    }
                }
            }
        }
    }
}

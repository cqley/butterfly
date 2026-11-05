import "../core"
import QtQuick

FocusScope {
    id: root
    property var colors: []
    property int current: 0
    property int autoIndex: -1
    signal picked(int index)

    readonly property int n: colors.length
    readonly property int cell: Theme.settingsDotD + Theme.settingsDotRingPad * 2

    function step(d) {
        if (root.n <= 0)
            return
        root.picked(((root.current + d) % root.n + root.n) % root.n)
    }

    width: root.n ? root.n * cell + (root.n - 1) * Theme.settingsDotGap : 0
    height: cell
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
        focused: root.activeFocus
    }

    Row {
        anchors.fill: parent
        spacing: Theme.settingsDotGap

        Repeater {
            model: root.colors

            Item {
                id: dot
                required property var modelData
                required property int index

                width: root.cell
                height: root.cell

                Rectangle {
                    anchors.centerIn: parent
                    width: Theme.settingsDotD
                    height: Theme.settingsDotD
                    radius: width / 2
                    color: dot.modelData
                    border.width: Theme.surfaceBorderWidth
                    border.color: Theme.surfaceBorder
                    antialiasing: true

                    Rectangle {
                        anchors.centerIn: parent
                        visible: dot.index === root.autoIndex
                        width: parent.width / 2
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: Theme.surfaceBorderWidth
                        border.color: Theme.onTone(dot.modelData)
                        antialiasing: true
                        opacity: Theme.dimMid
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: Theme.surfaceBorderWidth
                    border.color: Theme.fg
                    antialiasing: true
                    visible: root.current === dot.index
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Settings.keyNav = false
                        root.forceActiveFocus()
                        root.picked(dot.index)
                    }
                }
            }
        }
    }
}

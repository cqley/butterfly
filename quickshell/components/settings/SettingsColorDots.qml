import "../core"
import QtQuick

Row {
    id: root
    property var colors: []
    property int current: 0
    signal picked(int index)

    spacing: Theme.settingsDotGap

    Repeater {
        model: root.colors

        Item {
            id: dot
            required property var modelData
            required property int index

            width: Theme.settingsDotD + Theme.settingsDotRingPad * 2
            height: width

            Rectangle {
                anchors.centerIn: parent
                width: Theme.settingsDotD
                height: Theme.settingsDotD
                radius: width / 2
                color: dot.modelData
                antialiasing: true
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
                    root.current = dot.index
                    root.picked(dot.index)
                }
            }
        }
    }
}

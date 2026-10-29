import "../core"
import QtQuick

Rectangle {
    id: root
    property var options: []
    property int current: 0
    signal picked(int index)

    readonly property real segW: options.length ? width / options.length : 0

    height: Theme.settingsRowH - 10
    radius: Theme.settingsCardRadius - 4
    color: Theme.bg
    antialiasing: true

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
                required property string modelData
                required property int index
                width: root.segW
                height: root.height

                Txt {
                    anchors.centerIn: parent
                    text: parent.modelData
                    font.pixelSize: Theme.settingsLabelPx
                    font.weight: root.current === index ? Font.DemiBold : Font.Normal
                    color: Theme.fg
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.current = index
                        root.picked(index)
                    }
                }
            }
        }
    }
}

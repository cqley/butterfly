import "../core"
import QtQuick

Row {
    id: root
    property int level: 0
    spacing: Theme.sigGap

    Repeater {
        model: Theme.sigBars

        Rectangle {
            required property int index
            anchors.bottom: parent.bottom
            width: Theme.sigW
            height: Theme.sigH + index * Theme.sigStep
            radius: Theme.sigR
            color: Theme.fg
            opacity: root.level > index ? Theme.sigOn : Theme.sigOff
            antialiasing: true
        }
    }
}

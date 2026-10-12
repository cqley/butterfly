import "../core"
import QtQuick

Fade {
    id: root
    property date now
    property int target: 0
    property real pos: target
    readonly property int base: Math.floor(pos)
    readonly property real frac: pos - base

    width: Theme.gridW
    height: Theme.stripH
    clip: true

    onVisibleChanged: if (!visible) target = 0

    Behavior on pos { NumberAnimation { duration: Theme.glide; easing.type: Theme.ease } }

    Repeater {
        model: Theme.weekCells

        Item {
            required property int index
            readonly property int rel: root.base + index - Theme.weekCenter
            readonly property date d: new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate() + rel)
            readonly property bool today: rel === 0
            readonly property bool weekend: d.getDay() === 0 || d.getDay() === 6
            readonly property color tint: today ? Theme.accent : weekend ? Theme.red : Theme.fg

            x: (index - Theme.weekLead - root.frac) * Theme.cellW
            width: Theme.cellW
            height: Theme.stripH
            opacity: Math.max(Theme.weekFadeMin, 1 - Math.abs(x + Theme.cellW / 2 - Theme.gridW / 2) / (Theme.cellW * Theme.weekFadeSpan))

            Rectangle {
                anchors.fill: parent
                radius: Theme.weekTodayR
                visible: today
                color: Theme.accent
                opacity: Theme.todayFill
            }

            Column {
                anchors.centerIn: parent
                spacing: Theme.weekGap

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "smtwtfs"[d.getDay()]
                    color: tint
                    font.pixelSize: Theme.fsXXS
                }

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: d.getDate()
                    color: tint
                    font.pixelSize: Theme.fsXL
                    font.weight: today ? Font.Bold : Font.Medium
                }
            }
        }
    }

    Wheel {
        anchors.fill: parent
        onStep: n => root.target += n
    }
}


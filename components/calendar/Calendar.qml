import "../core"
import QtQuick

Fade {
    id: root
    property date now
    property int months: 0
    property int last: 0
    readonly property date view: new Date(now.getFullYear(), now.getMonth() + months, 1)
    readonly property int first: view.getDay()
    readonly property int rows: Math.ceil((first + new Date(view.getFullYear(), view.getMonth() + 1, 0).getDate()) / Theme.weekDays)

    width: col.width
    height: col.height

    onVisibleChanged: if (!visible) months = 0
    onMonthsChanged: {
        grid.y = months > last ? Theme.calSlide : -Theme.calSlide
        grid.opacity = 0
        last = months
        settle.restart()
    }

    ParallelAnimation {
        id: settle
        NumberAnimation { target: grid; property: "y"; to: 0; duration: Theme.glide; easing.type: Theme.ease }
        NumberAnimation { target: grid; property: "opacity"; to: 1; duration: Theme.glide; easing.type: Theme.ease }
    }

    Column {
        id: col
        spacing: Theme.calGap

        Txt {
            x: Theme.calTitleX
            text: Qt.formatDate(root.view, "MMMM yyyy").toLowerCase()
            font.pixelSize: Theme.fsL
            font.weight: Font.DemiBold
        }

        Item {
            width: Theme.gridW
            height: grid.height

            Grid {
                id: grid
                columns: Theme.weekDays

                Repeater {
                    model: Theme.weekDays

                    Txt {
                        required property int index
                        width: Theme.cellW
                        height: Theme.calHeadH
                        horizontalAlignment: Text.AlignHCenter
                        text: "smtwtfs"[index]
                        color: index === 0 || index === Theme.weekDays - 1 ? Theme.red : Theme.fg
                        opacity: Theme.dimMid
                        font.pixelSize: Theme.fsXS
                    }
                }

                Repeater {
                    model: root.rows * Theme.weekDays

                    Item {
                        required property int index
                        readonly property date d: new Date(root.view.getFullYear(), root.view.getMonth(), index - root.first + 1)
                        readonly property bool inMonth: d.getMonth() === root.view.getMonth()
                        readonly property bool today: d.getFullYear() === root.now.getFullYear() && d.getMonth() === root.now.getMonth() && d.getDate() === root.now.getDate()
                        readonly property bool weekend: index % Theme.weekDays === 0 || index % Theme.weekDays === Theme.weekDays - 1

                        width: Theme.cellW
                        height: Theme.cellH
                        opacity: inMonth ? 1 : Theme.outMonth

                        Rectangle {
                            anchors.centerIn: parent
                            width: Theme.cellH
                            height: Theme.cellH
                            radius: Theme.cellH / 2
                            visible: today
                            color: Theme.accent
                            opacity: Theme.todayFill
                        }

                        Txt {
                            anchors.centerIn: parent
                            text: d.getDate()
                            color: today ? Theme.accent : weekend ? Theme.red : Theme.fg
                            font.weight: today ? Font.Bold : Font.Medium
                        }
                    }
                }
            }
        }
    }

    Wheel {
        anchors.fill: parent
        onStep: n => root.months += n
    }
}

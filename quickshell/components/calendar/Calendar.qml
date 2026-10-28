import "../core"
import QtQuick

Fade {
    id: root
    property date now
    property int months: 0
    property int last: 0
    property int cw: Theme.cellW
    property int ch: Theme.cellH
    property int px: Theme.fsM
    readonly property int gw: cw * Theme.weekDays
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

    component Nav: Item {
        id: nav
        required property string glyph
        required property int step

        width: Theme.calNavDia
        height: Theme.calNavDia
        scale: tap.pressed ? Theme.feedbackPressScale : area.hovered ? Theme.feedbackHoverScale : 1

        Behavior on scale {
            NumberAnimation {
                duration: Theme.feedbackDuration
                easing.type: Theme.ease
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.fg
            opacity: area.hovered ? Theme.calNavHoverFill : Theme.calNavFill

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.feedbackDuration
                    easing.type: Theme.ease
                }
            }
        }

        Txt {
            anchors.centerIn: parent
            text: nav.glyph
            opacity: Theme.dimMid
            font.pixelSize: Theme.calNavGlyph
        }

        HoverHandler { id: area }

        TapHandler {
            id: tap
            onTapped: root.months += nav.step
        }
    }

    Column {
        id: col
        spacing: Theme.calGap

        Item {
            width: root.gw
            height: Theme.calNavDia

            Nav {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                glyph: "←"
                step: -1
            }

            Txt {
                anchors.centerIn: parent
                text: Qt.formatDate(root.view, "MMMM yyyy").toLowerCase()
                font.pixelSize: Theme.fsL
                font.weight: Font.DemiBold
            }

            Nav {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                glyph: "→"
                step: 1
            }
        }

        Item {
            width: root.gw
            height: grid.height

            Grid {
                id: grid
                columns: Theme.weekDays

                Repeater {
                    model: Theme.weekDays

                    Txt {
                        required property int index
                        width: root.cw
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

                        width: root.cw
                        height: root.ch
                        opacity: inMonth ? 1 : Theme.outMonth

                        Rectangle {
                            anchors.centerIn: parent
                            width: root.ch * Theme.calTodayScale
                            height: width
                            radius: width / 2
                            visible: today
                            color: Theme.accent
                        }

                        Txt {
                            anchors.centerIn: parent
                            text: d.getDate()
                            color: today ? Theme.bg : weekend ? Theme.red : Theme.fg
                            font.pixelSize: root.px
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

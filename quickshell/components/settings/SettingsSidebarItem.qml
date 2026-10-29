import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property bool selected: false
    property string icon: ""
    property string label: ""
    signal activated()

    width: parent ? parent.width : 0
    height: Theme.settingsSidebarItemH

    Rectangle {
        anchors.fill: parent
        radius: Theme.settingsCardRadius
        color: root.selected ? Theme.settingsCardAlt : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
        }
    }

    Rectangle {
        id: iconBg
        x: Theme.settingsSidebarPadX
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.settingsSidebarIconD
        height: Theme.settingsSidebarIconD
        radius: width / 2
        color: root.selected ? Theme.accent : Theme.chip
        antialiasing: true

        Behavior on color {
            ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
        }

        Shape {
            anchors.centerIn: parent
            width: Theme.settingsSidebarIconD * 0.5
            height: width
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: Theme.iconStroke
                strokeColor: root.selected ? Theme.bg : Theme.fg
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg { path: root.icon }
            }
        }
    }

    Txt {
        anchors.left: iconBg.right
        anchors.leftMargin: Theme.settingsSidebarPadX
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        font.pixelSize: Theme.settingsSidebarPx
        font.weight: root.selected ? Font.DemiBold : Font.Normal
        color: root.selected ? Theme.fg : Theme.mix(Theme.fg, Theme.bg, Theme.dimSoft)
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}

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
        radius: Theme.settingsSidebarItemRadius
        color: root.selected ? Theme.settingsSelected : "transparent"
        antialiasing: true

        Behavior on color {
            ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
        }
    }

    Rectangle {
        id: iconBg
        x: Theme.settingsSidebarPadX
        y: Math.round((root.height - height) / 2)
        width: Theme.settingsSidebarIconD
        height: Theme.settingsSidebarIconD
        radius: width / 2
        color: root.selected ? Theme.settingsIconOnBg : Theme.settingsIconOffBg
        antialiasing: true

        Behavior on color {
            ColorAnimation { duration: Theme.glide; easing.type: Theme.ease }
        }

        Shape {
            anchors.centerIn: parent
            width: Theme.iconGrid
            height: Theme.iconGrid
            scale: Theme.settingsSidebarIcon / Theme.iconGrid
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: Theme.glyphStroke(Theme.settingsSidebarIcon, Theme.settingsIconStroke)
                strokeColor: root.selected ? Theme.settingsIconOnInk : Theme.settingsIconOffInk
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
        color: Theme.fg
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}

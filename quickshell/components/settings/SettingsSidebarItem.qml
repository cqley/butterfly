import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property bool selected: false
    property string icon: ""
    property string label: ""
    signal activated
    signal stepped(int delta)

    width: parent ? parent.width : 0
    height: Theme.settingsSidebarItemH
    activeFocusOnTab: true

    Keys.onPressed: e => {
        if (e.isAutoRepeat) {
            e.accepted = true
            return
        }
        Settings.keyNav = true
        const k = e.key
        if (k === Qt.Key_Down || k === Qt.Key_J || k === Qt.Key_L || k === Qt.Key_Tab) {
            root.stepped(1)
            e.accepted = true
        } else if (k === Qt.Key_Up || k === Qt.Key_K || k === Qt.Key_H || k === Qt.Key_Backtab) {
            root.stepped(-1)
            e.accepted = true
        } else if (k === Qt.Key_Space || k === Qt.Key_Return || k === Qt.Key_Enter) {
            root.activated()
            e.accepted = true
        }
    }

    MouseArea {
        id: touch
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Settings.keyNav = false
            root.forceActiveFocus()
            root.activated()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.settingsSidebarItemRadius
        color: Theme.settingsRowHover
        border.width: Theme.surfaceBorderWidth
        border.color: Theme.surfaceBorder
        opacity: touch.containsMouse && !root.selected ? 1 : 0
        antialiasing: true

        Behavior on opacity {
            NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
        }
    }

    Rectangle {
        id: iconBg
        x: Theme.settingsSidebarPadX
        y: Theme.mid(root.height, height)
        width: Theme.settingsSidebarIconD
        height: Theme.settingsSidebarIconD
        radius: width / 2
        color: root.selected ? Theme.settingsIconOnBg : Theme.settingsIconOffBg
        scale: iconScale.shaped
        antialiasing: true

        Behavior on color {
            ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
        }

        ScaleSpring {
            id: iconScale
            size: Theme.settingsSidebarIconD
            target: touch.pressed ? Theme.feedbackPressScale : (touch.containsMouse ? Theme.feedbackHoverScale : 1)
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
}

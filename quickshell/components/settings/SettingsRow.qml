import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    default property alias content: slot.data
    property string label: ""
    property string value: ""
    property bool showArrow: false
    property bool last: true
    property bool interactive: showArrow
    signal activated()

    width: parent ? parent.width : 0
    height: Theme.settingsRowH

    Txt {
        anchors.left: parent.left
        anchors.leftMargin: Theme.settingsRowPadX
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        font.pixelSize: Theme.settingsLabelPx
        color: Theme.fg
    }

    Row {
        id: slot
        anchors.right: arrow.visible ? arrow.left : parent.right
        anchors.rightMargin: arrow.visible ? Theme.settingsSidebarGap : Theme.settingsRowPadX
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.settingsSidebarGap

        Txt {
            visible: root.value !== ""
            text: root.value
            font.pixelSize: Theme.settingsValuePx
            color: Theme.mix(Theme.fg, Theme.bg, Theme.dimSoft)
        }
    }

    Shape {
        id: arrow
        visible: root.showArrow
        anchors.right: parent.right
        anchors.rightMargin: Theme.settingsRowPadX
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.settingsArrowSize
        height: Theme.settingsArrowSize
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: Theme.iconStroke
            strokeColor: Theme.mix(Theme.fg, Theme.bg, Theme.dimSoft)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: "M1 1L7 4L1 7" }
        }
    }

    Rectangle {
        visible: !root.last
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.settingsRowPadX
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.settingsDivider
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.activated()
    }
}

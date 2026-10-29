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
        font.weight: Font.Medium
        color: Theme.fg
    }

    Row {
        id: slot
        anchors.right: arrow.visible ? arrow.left : parent.right
        anchors.rightMargin: arrow.visible ? Theme.settingsValueGap : Theme.settingsRowPadX
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.settingsValueGap

        Txt {
            visible: root.value !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.value
            font.pixelSize: Theme.settingsValuePx
            font.weight: Font.Normal
            color: Theme.settingsValueInk
        }
    }

    Item {
        id: arrow
        visible: root.showArrow
        width: Theme.settingsArrowSize
        height: Theme.settingsArrowSize
        x: Math.round(root.width - Theme.settingsRowPadX - width)
        y: Math.round((root.height - height) / 2)

        Shape {
            anchors.centerIn: parent
            width: Theme.iconGrid
            height: Theme.iconGrid
            scale: Theme.settingsArrowSize / Theme.iconGrid
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: Theme.glyphStroke(Theme.settingsArrowSize, Theme.settingsIconStroke)
                strokeColor: Theme.settingsArrowInk
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg { path: Theme.settingsArrowPath }
            }
        }
    }

    Rectangle {
        visible: !root.last
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.settingsRowPadX
        anchors.rightMargin: Theme.settingsRowPadX
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

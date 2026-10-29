import "../core"
import QtQuick
import QtQuick.Shapes

Rectangle {
    id: root
    property string icon: ""
    property string title: ""
    property string subtitle: ""

    width: parent ? parent.width : 0
    height: col.height + 2 * Theme.settingsHeaderPad
    radius: Theme.settingsCardRadius
    color: Theme.settingsCard
    antialiasing: true

    Column {
        id: col
        y: Theme.settingsHeaderPad
        width: parent.width
        spacing: 0

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.settingsHeaderIconD
            height: Theme.settingsHeaderIconD
            radius: width / 2
            color: Theme.settingsIconOffBg
            antialiasing: true

            Shape {
                anchors.centerIn: parent
                width: Theme.iconGrid
                height: Theme.iconGrid
                scale: Theme.settingsHeaderIcon / Theme.iconGrid
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: Theme.glyphStroke(Theme.settingsHeaderIcon, Theme.settingsIconStroke)
                    strokeColor: Theme.settingsIconOffInk
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathSvg { path: root.icon }
                }
            }
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: Theme.settingsHeaderGap
            text: root.title
            font.pixelSize: Theme.settingsTitlePx
            font.weight: Font.DemiBold
            color: Theme.fg
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: Theme.settingsHeaderSubGap
            text: root.subtitle
            font.pixelSize: Theme.settingsSubtitlePx
            font.weight: Font.Normal
            color: Theme.settingsValueInk
            horizontalAlignment: Text.AlignHCenter
            width: Math.min(implicitWidth, root.width - 2 * Theme.settingsRowPadX)
            wrapMode: Text.WordWrap
        }
    }
}

import "../core"
import QtQuick
import QtQuick.Shapes

Column {
    id: root
    property string icon: ""
    property string title: ""
    property string subtitle: ""

    width: parent ? parent.width : 0
    spacing: Theme.settingsHeaderGap

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Theme.settingsHeaderIconD
        height: Theme.settingsHeaderIconD
        radius: width / 2
        color: Theme.accent
        antialiasing: true

        Shape {
            anchors.centerIn: parent
            width: Theme.settingsHeaderIconD * 0.46
            height: width
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: Theme.iconStroke * 1.1
                strokeColor: Theme.bg
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg { path: root.icon }
            }
        }
    }

    Txt {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.title
        font.pixelSize: Theme.settingsTitlePx
        font.weight: Font.DemiBold
        color: Theme.fg
    }

    Txt {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.subtitle
        font.pixelSize: Theme.settingsSubtitlePx
        color: Theme.mix(Theme.fg, Theme.bg, Theme.dimSoft)
        horizontalAlignment: Text.AlignHCenter
        width: Math.min(implicitWidth, root.width)
        wrapMode: Text.WordWrap
    }
}

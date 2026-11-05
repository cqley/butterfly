import "../core"
import QtQuick

Txt {
    width: parent ? parent.width : 0
    height: Theme.settingsSectionH
    font.pixelSize: Theme.settingsSectionPx
    font.weight: Font.Normal
    color: Theme.settingsSectionInk
    leftPadding: Theme.settingsRowPadX
    verticalAlignment: Text.AlignVCenter
}

import "../core"
import QtQuick

Column {
    id: root
    property string title: ""
    default property alias content: col.data

    width: parent ? parent.width : 0
    spacing: Theme.settingsSidebarGap

    function markLast() {
        const kids = col.children
        for (let i = 0; i < kids.length; i++)
            if (kids[i].hasOwnProperty("last"))
                kids[i].last = i === kids.length - 1
    }

    Txt {
        visible: root.title !== ""
        width: parent.width
        height: Theme.settingsSidebarItemH
        verticalAlignment: Text.AlignBottom
        leftPadding: Theme.settingsTitleInset
        bottomPadding: Theme.settingsTitleLift
        text: root.title
        font.pixelSize: Theme.settingsSectionPx
        font.weight: Font.Normal
        color: Theme.settingsSectionInk
    }

    Rectangle {
        width: parent.width
        height: col.height
        radius: Theme.settingsCardRadius
        color: Theme.settingsCard
        border.width: Theme.settingsBorderWidth
        border.color: Theme.surfaceBorder
        antialiasing: true

        Column {
            id: col
            width: parent.width

            onChildrenChanged: root.markLast()
            Component.onCompleted: root.markLast()
        }
    }
}

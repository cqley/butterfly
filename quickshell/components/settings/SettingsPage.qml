import "../core"
import QtQuick

Column {
    id: root
    property var category: null

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsHeaderCard {
        width: parent.width
        icon: root.category ? root.category.icon : ""
        title: root.category ? root.category.title : ""
        subtitle: root.category ? root.category.subtitle : ""
    }

    Loader {
        width: parent.width
        height: item ? item.implicitHeight : 0
        source: root.category ? root.category.page : ""
    }
}

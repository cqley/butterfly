import "../core"
import QtQuick

Flickable {
    id: root
    property var category: null
    readonly property alias scrollRatio: root.visibleArea
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    contentWidth: width
    contentHeight: page.height

    onCategoryChanged: contentY = 0

    SettingsPage {
        id: page
        width: root.width
        category: root.category
    }
}

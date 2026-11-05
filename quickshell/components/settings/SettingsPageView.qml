import "../core"
import QtQuick

Flickable {
    id: root
    property var category: null
    readonly property bool ready: loader.status === Loader.Ready
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    contentWidth: width
    contentHeight: loader.height

    onCategoryChanged: contentY = 0

    Loader {
        id: loader
        asynchronous: true
        width: root.width
        height: item ? item.implicitHeight : 0
        source: root.category ? root.category.page : ""
    }
}

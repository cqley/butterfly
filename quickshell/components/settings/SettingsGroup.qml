import "../core"
import QtQuick

Rectangle {
    id: root
    default property alias content: col.data

    width: parent ? parent.width : 0
    height: col.height
    radius: Theme.settingsCardRadius
    color: Theme.settingsCard
    antialiasing: true

    Column {
        id: col
        width: parent.width

        onChildrenChanged: root.markLast()
        Component.onCompleted: root.markLast()
    }

    function markLast() {
        const kids = col.children
        for (let i = 0; i < kids.length; i++)
            if (kids[i].hasOwnProperty("last"))
                kids[i].last = i === kids.length - 1
    }
}

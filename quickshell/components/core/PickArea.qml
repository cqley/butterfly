import QtQuick

MouseArea {
    id: root
    required property Item pick
    required property int at
    property bool live: true
    property bool aims: true

    anchors.fill: parent
    enabled: root.live
    hoverEnabled: root.live
    cursorShape: Qt.PointingHandCursor
    onPositionChanged: m => {
        if (root.aims)
            root.pick.aim(mapToItem(null, m.x, m.y), root.at)
    }
}

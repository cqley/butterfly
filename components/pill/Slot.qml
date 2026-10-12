import "../core"
import QtQuick

Item {
    id: root
    property bool shown: false
    property int size: Theme.micS
    property int leadingGap: Theme.rowGap
    readonly property int targetWidth: shown ? leadingGap + size : 0
    property real enter: shown ? 1 : 0
    default property alias content: holder.data
    signal clicked

    width: (leadingGap + size) * enter
    height: Theme.h
    visible: enter > 0
    clip: true

    Behavior on enter {
        NumberAnimation {
            duration: Theme.idlePopDuration
            easing.type: Theme.ease
        }
    }

    Item {
        id: holder
        x: root.leadingGap
        width: root.size
        height: root.size
        anchors.verticalCenter: parent.verticalCenter
        transformOrigin: Item.Center
        scale: (Theme.slotScale + (1 - Theme.slotScale) * root.enter) * (area.pressed ? Theme.feedbackPressScale : area.containsMouse ? Theme.feedbackHoverScale : 1)
        opacity: root.enter
    }

    MouseArea {
        id: area
        x: root.leadingGap - Theme.slotHit
        y: Math.round((root.height - root.size) / 2) - Theme.slotHit
        width: root.size + Theme.slotHit * 2
        height: root.size + Theme.slotHit * 2
        enabled: root.shown
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

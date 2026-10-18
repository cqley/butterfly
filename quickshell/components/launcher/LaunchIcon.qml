import "../core"
import QtQuick

Item {
    id: root

    property url source
    property string fallbackText: "?"
    property bool selected: false
    property bool hovered: false
    property bool pressed: false

    width: Theme.launchIconBox
    height: Theme.launchIconBox

    Rectangle {
        anchors.fill: parent
        radius: Theme.launchIconRadius
        color: root.selected ? Theme.launchIconSelectedFill : Theme.launchIconFill
        border.color: root.selected ? Theme.accent : root.hovered ? Theme.launchIconHoverBorder : Theme.launchIconBorder
        border.width: Theme.launchIconBorderWidth
        antialiasing: true
        transformOrigin: Item.Center
        scale: root.pressed ? Theme.feedbackPressScale : root.selected ? Theme.launchIconSelectedScale : root.hovered ? Theme.feedbackHoverScale : 1

        Behavior on scale { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
        Behavior on color { ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
        Behavior on border.color { ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
    }

    StableImage {
        id: icon
        anchors.centerIn: parent
        width: Theme.launchIconSize
        height: Theme.launchIconSize
        source: root.source
        sourceSize: Qt.size(Theme.launchIconSourceSize, Theme.launchIconSourceSize)
        mipmap: true
        smooth: true
    }

    Txt {
        anchors.centerIn: parent
        text: root.fallbackText
        visible: icon.showPlaceholder
        font.pixelSize: Theme.launchFallbackPx
        font.weight: Font.Bold
    }
}

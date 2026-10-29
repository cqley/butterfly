import QtQuick

Item {
    id: root
    property int radius: 0
    property color color: Theme.shadowColor
    property real strength: Theme.shadowOpacity
    property int blur: Theme.shadowBlur
    property int layers: Theme.shadowLayers
    property int offsetY: Theme.shadowOffsetY
    z: -1

    Repeater {
        model: root.layers

        Rectangle {
            required property int index
            readonly property real t: (index + 1) / root.layers

            anchors.fill: parent
            anchors.margins: -t * root.blur
            anchors.topMargin: -t * root.blur + root.offsetY
            anchors.bottomMargin: -t * root.blur - root.offsetY
            radius: root.radius + t * root.blur
            color: root.color
            opacity: root.strength * (1 - t) * (1 - t) / root.layers * 2.4
            antialiasing: true
        }
    }
}

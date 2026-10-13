import QtQuick

Rectangle {
    id: root
    required property string label
    property color tint: Theme.accent
    readonly property bool cap: /[A-Z0-9]/.test(root.label)

    x: Theme.markX
    y: Math.round(parent.height / 2 + (cap ? Theme.markCapY - Theme.markCapH / 2 : Theme.markY - Theme.markH / 2))
    width: Theme.markW
    height: cap ? Theme.markCapH : Theme.markH
    radius: width / 2
    color: root.tint
    antialiasing: true
}

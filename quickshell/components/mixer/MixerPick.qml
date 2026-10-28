import "../core"
import "../audio"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    required property int slot
    required property string title
    property bool open: false
    readonly property var items: Audio.list(root.slot)
    readonly property bool many: root.items.length > 1
    readonly property bool ready: Audio.ready(root.slot)
    signal toggled

    width: parent.width
    height: head.height + list.height
    clip: true

    Spring {
        id: reveal
        target: root.open && root.many ? rows.height + Theme.mixerPickGap : 0
        response: Theme.mixerSizeResponse
        damping: Theme.mixerSizeDamping
    }

    Rectangle {
        id: head
        width: parent.width
        height: Theme.mixerPickH
        radius: Theme.mixerPickR
        color: tap.containsMouse || root.open ? Theme.chip : "transparent"
        antialiasing: true

        Behavior on color {
            ColorAnimation { duration: Theme.feedbackDuration }
        }

        Txt {
            x: Theme.mixerPickPad
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.mixerPickTitleW
            text: root.title
            color: Theme.fg
            opacity: Theme.dimMuted
            font.pixelSize: Theme.fsXXS
        }

        Txt {
            x: Theme.mixerPickPad + Theme.mixerPickTitleW
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - Theme.mixerPickPad - Theme.mixerPickCaret
            elide: Text.ElideRight
            text: Audio.label(root.slot)
            color: Theme.fg
            opacity: root.ready ? 1 : Theme.dimEmpty
            font.pixelSize: Theme.fsXS
        }

        Shape {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width - Theme.mixerPickPad - Theme.mixerPickCaret
            width: Theme.iconGrid
            height: Theme.iconGrid
            scale: Theme.mixerPickCaret / Theme.iconGrid
            transformOrigin: Item.Left
            visible: root.many
            rotation: root.open ? 180 : 0
            opacity: Theme.dimMuted

            Behavior on rotation {
                NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
            }

            ShapePath {
                strokeWidth: Theme.glyphStroke(Theme.mixerPickCaret)
                strokeColor: Theme.fg
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg { path: Theme.mixerCaretPath }
            }
        }

        MouseArea {
            id: tap
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.many
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }

    Item {
        id: list
        width: parent.width
        y: head.height
        height: reveal.value
        clip: true

        Column {
            id: rows
            width: parent.width
            y: Theme.mixerPickGap
            spacing: 0

            Repeater {
                model: root.items

                Rectangle {
                    id: row
                    required property var modelData
                    readonly property bool on: Audio.isDefault(root.slot, modelData)

                    width: rows.width
                    height: Theme.mixerPickH
                    radius: Theme.mixerPickR
                    color: hit.containsMouse ? Theme.chip : "transparent"
                    antialiasing: true

                    Behavior on color {
                        ColorAnimation { duration: Theme.feedbackDuration }
                    }

                    Shape {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Theme.mixerPickPad
                        width: Theme.iconGrid
                        height: Theme.iconGrid
                        scale: Theme.mixerPickCaret / Theme.iconGrid
                        transformOrigin: Item.Left
                        opacity: row.on ? 1 : Theme.dimEmpty

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
                        }

                        ShapePath {
                            strokeWidth: row.on ? -1 : Theme.glyphStroke(Theme.mixerPickCaret)
                            strokeColor: Theme.fg
                            fillColor: row.on ? Theme.accent : "transparent"
                            fillRule: ShapePath.WindingFill

                            PathSvg { path: Theme.mixerDotPath }
                        }
                    }

                    Txt {
                        x: Theme.mixerPickPad + Theme.mixerPickTitleW
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x - Theme.mixerPickPad
                        elide: Text.ElideRight
                        text: Audio.deviceName(row.modelData)
                        color: Theme.fg
                        opacity: row.on ? 1 : Theme.dimSoft
                        font.pixelSize: Theme.fsXS
                    }

                    MouseArea {
                        id: hit
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Audio.choose(root.slot, row.modelData)
                    }
                }
            }
        }
    }
}

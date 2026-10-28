import "../core"
import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        property bool fadeShown: Screenshot.picking

        readonly property real offX: modelData.x
        readonly property real offY: modelData.y
        readonly property real localX: Screenshot.curG.x - offX
        readonly property real localY: Screenshot.curG.y - offY
        readonly property bool hasPointer: localX >= 0 && localX <= win.width && localY >= 0 && localY <= win.height

        readonly property real brLocalX: Math.max(Screenshot.pressG.x, Screenshot.curG.x) - offX
        readonly property real brLocalY: Math.max(Screenshot.pressG.y, Screenshot.curG.y) - offY
        readonly property bool hasLabel: Screenshot.dragging
            && brLocalX >= 0 && brLocalX <= win.width
            && brLocalY >= 0 && brLocalY <= win.height

        readonly property real selX: Math.min(Screenshot.pressG.x, Screenshot.curG.x) - offX
        readonly property real selY: Math.min(Screenshot.pressG.y, Screenshot.curG.y) - offY
        readonly property real selW: Math.abs(Screenshot.curG.x - Screenshot.pressG.x)
        readonly property real selH: Math.abs(Screenshot.curG.y - Screenshot.pressG.y)

        screen: modelData
        visible: fadeShown || surface.opacity > 0
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: win.fadeShown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        mask: Region { width: win.width; height: win.height }

        Item {
            id: surface
            anchors.fill: parent
            opacity: 0
            focus: win.fadeShown

            states: State {
                name: "on"
                when: win.fadeShown
                PropertyChanges { surface.opacity: 1 }
            }

            transitions: [
                Transition {
                    to: "on"
                    NumberAnimation { property: "opacity"; duration: Theme.rise; easing.type: Theme.ease }
                },
                Transition {
                    from: "on"
                    NumberAnimation { property: "opacity"; duration: Theme.fall; easing.type: Theme.ease }
                }
            ]

            Keys.onEscapePressed: Screenshot.cancelRegion()

            Rectangle {
                anchors.fill: parent
                color: Theme.bg
                opacity: Theme.regionDim
                visible: !Screenshot.dragging && Screenshot.picking
            }

            DimHole {
                visible: Screenshot.dragging
                holeX: win.selX
                holeY: win.selY
                holeW: win.selW
                holeH: win.selH
            }

            Rectangle {
                visible: !Screenshot.dragging && Screenshot.picking && win.hasPointer
                x: 0
                y: win.localY - Theme.regionGuideWidth / 2
                width: win.width
                height: Theme.regionGuideWidth
                color: Theme.accent
                opacity: Theme.regionGuideOpacity
            }

            Rectangle {
                visible: !Screenshot.dragging && Screenshot.picking && win.hasPointer
                x: win.localX - Theme.regionGuideWidth / 2
                y: 0
                width: Theme.regionGuideWidth
                height: win.height
                color: Theme.accent
                opacity: Theme.regionGuideOpacity
            }

            Rectangle {
                id: label
                visible: win.hasLabel && win.selW > 0 && win.selH > 0
                x: Math.max(0, Math.min(win.width - width, win.brLocalX + Theme.regionLabelGap))
                y: Math.max(0, Math.min(win.height - height, win.brLocalY + Theme.regionLabelGap))
                width: dimText.implicitWidth + Theme.regionLabelPadX * 2
                height: dimText.implicitHeight + Theme.regionLabelPadY * 2
                radius: Theme.regionLabelR
                color: Theme.bg
                border.width: Theme.surfaceBorderWidth
                border.color: Theme.surfaceBorder

                Txt {
                    id: dimText
                    anchors.centerIn: parent
                    text: Math.round(win.selW) + " × " + Math.round(win.selH)
                    font.pixelSize: Theme.fsS
                }
            }

            HoverHandler {
                cursorShape: Qt.CrossCursor
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true

                onPositionChanged: m => Screenshot.updatePointer(win.offX + m.x, win.offY + m.y)
                onPressed: m => {
                    Screenshot.updatePointer(win.offX + m.x, win.offY + m.y)
                    Screenshot.beginDrag()
                }
                onReleased: m => {
                    Screenshot.updatePointer(win.offX + m.x, win.offY + m.y)
                    Screenshot.endDrag()
                }
            }
        }
    }
}

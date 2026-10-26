import "../core"
import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        property bool fadeShown: Screenshot.targeting

        readonly property real offX: modelData.x
        readonly property real offY: modelData.y

        readonly property var activeTarget: (Screenshot.targetIndex >= 0 && Screenshot.targetIndex < Screenshot.targets.length)
            ? Screenshot.targets[Screenshot.targetIndex] : null
        readonly property bool hasTarget: activeTarget !== null

        readonly property real selX: hasTarget ? activeTarget.x - offX : 0
        readonly property real selY: hasTarget ? activeTarget.y - offY : 0
        readonly property real selW: hasTarget ? activeTarget.w : 0
        readonly property real selH: hasTarget ? activeTarget.h : 0

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

            Keys.onEscapePressed: Screenshot.cancelTargetPick()
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
                    Screenshot.confirmTargetPick()
                    e.accepted = true
                } else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) {
                    Screenshot.cycleTarget(-1)
                    e.accepted = true
                } else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) {
                    Screenshot.cycleTarget(1)
                    e.accepted = true
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.bg
                opacity: Theme.regionDim
                visible: Screenshot.targeting && !win.hasTarget
            }

            DimHole {
                visible: win.hasTarget
                holeX: win.selX
                holeY: win.selY
                holeW: win.selW
                holeH: win.selH
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onPositionChanged: m => Screenshot.hoverTarget(win.offX + m.x, win.offY + m.y)
                onClicked: Screenshot.confirmTargetPick()
            }
        }
    }
}

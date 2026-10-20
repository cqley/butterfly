import "../core"
import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        property point pressPt: Qt.point(-1, -1)
        property point curPt: Qt.point(-1, -1)
        property bool dragging: false

        readonly property real rx: Math.min(pressPt.x, curPt.x)
        readonly property real ry: Math.min(pressPt.y, curPt.y)
        readonly property real rw: Math.abs(curPt.x - pressPt.x)
        readonly property real rh: Math.abs(curPt.y - pressPt.y)

        screen: modelData
        visible: Screenshot.picking
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: win.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        mask: Region { width: win.width; height: win.height }

        onVisibleChanged: if (visible) {
            dragging = false
            pressPt = Qt.point(-1, -1)
            curPt = Qt.point(-1, -1)
        }

        Item {
            id: surface
            anchors.fill: parent
            focus: win.visible

            Keys.onEscapePressed: Screenshot.cancelRegion()

            Rectangle {
                anchors.fill: parent
                color: Theme.bg
                opacity: Theme.regionDim
                visible: !win.dragging
            }

            Rectangle {
                visible: win.dragging
                x: 0
                y: 0
                width: win.width
                height: win.ry
                color: Theme.bg
                opacity: Theme.regionDim
            }

            Rectangle {
                visible: win.dragging
                x: 0
                y: win.ry + win.rh
                width: win.width
                height: win.height - (win.ry + win.rh)
                color: Theme.bg
                opacity: Theme.regionDim
            }

            Rectangle {
                visible: win.dragging
                x: 0
                y: win.ry
                width: win.rx
                height: win.rh
                color: Theme.bg
                opacity: Theme.regionDim
            }

            Rectangle {
                visible: win.dragging
                x: win.rx + win.rw
                y: win.ry
                width: win.width - (win.rx + win.rw)
                height: win.rh
                color: Theme.bg
                opacity: Theme.regionDim
            }

            Rectangle {
                visible: win.dragging
                x: win.rx
                y: win.ry
                width: win.rw
                height: win.rh
                radius: Theme.regionRadius
                color: "transparent"
                border.width: Theme.regionBorderWidth
                border.color: Theme.accent
                antialiasing: true
            }

            Rectangle {
                visible: !win.dragging && win.curPt.y >= 0
                x: 0
                y: win.curPt.y
                width: win.width
                height: 1
                color: Theme.accent
                opacity: Theme.regionGuideOpacity
            }

            Rectangle {
                visible: !win.dragging && win.curPt.x >= 0
                x: win.curPt.x
                y: 0
                width: 1
                height: win.height
                color: Theme.accent
                opacity: Theme.regionGuideOpacity
            }

            Rectangle {
                id: label
                readonly property bool below: win.ry < (dimText.implicitHeight + Theme.regionLabelPadY * 2) + Theme.regionLabelGap
                visible: win.dragging && win.rw > 0 && win.rh > 0
                x: Math.max(0, Math.min(win.width - width, win.rx))
                y: below ? win.ry + win.rh + Theme.regionLabelGap : win.ry - height - Theme.regionLabelGap
                width: dimText.implicitWidth + Theme.regionLabelPadX * 2
                height: dimText.implicitHeight + Theme.regionLabelPadY * 2
                radius: Theme.regionLabelR
                color: Theme.bg
                border.width: Theme.surfaceBorderWidth
                border.color: Theme.surfaceBorder

                Txt {
                    id: dimText
                    anchors.centerIn: parent
                    text: Math.round(win.rw) + " × " + Math.round(win.rh)
                    font.pixelSize: Theme.fsS
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.CrossCursor
                preventStealing: true

                onPositionChanged: m => win.curPt = Qt.point(m.x, m.y)

                onPressed: m => {
                    win.pressPt = Qt.point(m.x, m.y)
                    win.curPt = Qt.point(m.x, m.y)
                    win.dragging = true
                }

                onReleased: m => {
                    win.curPt = Qt.point(m.x, m.y)
                    win.dragging = false
                    if (win.rw >= Theme.regionMinSize && win.rh >= Theme.regionMinSize)
                        Screenshot.finishRegion(win.modelData, Qt.rect(win.rx, win.ry, win.rw, win.rh))
                    else
                        Screenshot.cancelRegion()
                }
            }
        }
    }
}

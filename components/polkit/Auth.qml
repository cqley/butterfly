import "../core"
import QtQuick
import QtQuick.Shapes
import Quickshell

Fade {
    id: root
    readonly property var flow: Polkit.flow
    readonly property string lockPath: "M5 11H19A2 2 0 0 1 21 13V20A2 2 0 0 1 19 22H5A2 2 0 0 1 3 20V13A2 2 0 0 1 5 11ZM7 11V7A5 5 0 0 1 17 7V11"

    width: Theme.authW - 2 * Theme.authPad
    height: col.height
    focus: shown

    function submit() {
        if (!flow || !flow.isResponseRequired) return
        flow.submit(input.text)
        input.text = ""
        input.forceActiveFocus()
    }

    function cancel() {
        Polkit.cancel()
        input.text = ""
    }

    onVisibleChanged: {
        input.text = ""
        if (visible) {
            forceActiveFocus()
            input.forceActiveFocus()
        }
    }

    Connections {
        target: Polkit
        function onOpenChanged() {
            input.text = ""
            if (Polkit.open) {
                root.forceActiveFocus()
                input.forceActiveFocus()
            }
        }
    }

    Connections {
        target: Polkit.flow
        function onIsResponseRequiredChanged() {
            input.text = ""
            if (Polkit.flow && Polkit.flow.isResponseRequired) input.forceActiveFocus()
        }
        function onFailedChanged() {
            if (Polkit.flow && Polkit.flow.failed) input.forceActiveFocus()
        }
    }

    Keys.onPressed: e => {
        if (e.key === Qt.Key_Escape) {
            root.cancel()
            e.accepted = true
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.authSpacing

        Row {
            spacing: Theme.authHeadGap

            Rectangle {
                width: Theme.authIcon
                height: Theme.authIcon
                radius: Theme.authIconR
                color: Theme.chip

                Shape {
                    anchors.centerIn: parent
                    width: Theme.iconGrid
                    height: Theme.iconGrid
                    scale: Theme.authGlyph / Theme.iconGrid
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: Theme.iconStroke
                        strokeColor: Theme.fg
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathSvg { path: root.lockPath }
                    }
                }
            }

            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: "authentication required"
                font.pixelSize: Theme.fsXXL
                font.weight: Font.DemiBold
            }
        }

        Txt {
            width: parent.width
            text: root.flow ? (root.flow.message || "").toLowerCase() : ""
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fsL
        }

        Txt {
            width: parent.width
            visible: text !== ""
            text: root.flow ? (root.flow.actionId || "") : ""
            elide: Text.ElideMiddle
            opacity: Theme.dimGhost
            font.pixelSize: Theme.fsS
        }

        Txt {
            width: parent.width
            visible: !!root.flow && (root.flow.failed || (root.flow.supplementaryIsError && root.flow.supplementaryMessage !== ""))
            text: root.flow && root.flow.supplementaryIsError && root.flow.supplementaryMessage !== "" ? root.flow.supplementaryMessage.toLowerCase() : "authentication failed, try again"
            color: Theme.red
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fsM
        }

        Rectangle {
            width: parent.width
            height: Theme.authFieldH
            radius: Theme.authFieldR
            color: Theme.chip

            Shape {
                x: Theme.authFieldIconX
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.iconGrid
                height: Theme.iconGrid
                scale: Theme.authGlyph / Theme.iconGrid
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: Theme.iconStroke
                    strokeColor: Theme.fg
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: root.lockPath }
                }
            }

            TextInput {
                id: input
                x: Theme.authFieldTextX
                width: parent.width - Theme.authFieldTextPad
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fg
                selectionColor: Theme.accent
                selectedTextColor: Theme.bg
                echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                selectByMouse: true
                clip: true
                font.family: Theme.font
                font.pixelSize: Theme.fsL
                font.weight: Font.Medium
                enabled: !!root.flow && root.flow.isResponseRequired
                onAccepted: root.submit()
            }

            Txt {
                x: input.x
                anchors.verticalCenter: parent.verticalCenter
                text: "password"
                visible: input.text === ""
                opacity: Theme.dimHint
                font.pixelSize: Theme.fsL
            }
        }

        Item {
            width: parent.width
            height: Theme.authBtnH

            Row {
                anchors.right: parent.right
                spacing: Theme.authBtnGap

                Rectangle {
                    width: Math.round(cancelTxt.width + Theme.authBtnPadX)
                    height: Theme.authBtnH
                    radius: Theme.authBtnH / 2
                    color: mouse.pressed ? Theme.tile : mouse.containsMouse ? Theme.tile : Theme.chip
                    scale: mouse.pressed ? Theme.feedbackPressScale : mouse.containsMouse ? Theme.feedbackHoverScale : 1
                    antialiasing: true
                    transformOrigin: Item.Center

                    Behavior on scale { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
                    Behavior on color { ColorAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }

                    Txt {
                        id: cancelTxt
                        anchors.centerIn: parent
                        text: "cancel"
                        font.pixelSize: Theme.fsL
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancel()
                    }
                }

                Rectangle {
                    width: Math.round(okTxt.width + Theme.authBtnPadX)
                    height: Theme.authBtnH
                    radius: Theme.authBtnH / 2
                    color: Theme.accent
                    opacity: input.text.length > 0 ? (mouse2.pressed ? Theme.authPressed : 1) : Theme.authDisabled
                    scale: input.text.length > 0 ? (mouse2.pressed ? Theme.feedbackPressScale : mouse2.containsMouse ? Theme.feedbackHoverScale : 1) : 1
                    antialiasing: true
                    transformOrigin: Item.Center

                    Behavior on scale { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
                    Behavior on opacity { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }

                    Txt {
                        id: okTxt
                        anchors.centerIn: parent
                        text: "authenticate"
                        color: Theme.bg
                        font.pixelSize: Theme.fsL
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: mouse2
                        anchors.fill: parent
                        enabled: input.text.length > 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submit()
                    }
                }
            }
        }
    }
}

import "../core"
import QtQuick
import QtQuick.Shapes

Fade {
    id: root
    property var flow: Polkit.flow
    property bool slip: false
    property string heading: ""
    property string detail: ""
    property string fault: ""
    property string hint: ""
    readonly property bool asking: !!flow && flow.isResponseRequired
    readonly property bool busy: shown && !!flow && !flow.isResponseRequired && !flow.isCompleted
    readonly property string lockPath: "M5 11H19A2 2 0 0 1 21 13V20A2 2 0 0 1 19 22H5A2 2 0 0 1 3 20V13A2 2 0 0 1 5 11ZM7 11V7A5 5 0 0 1 17 7V11"

    width: Theme.authW - 2 * Theme.authPad
    height: col.height
    focus: shown

    onFlowChanged: take()

    function take() {
        if (!flow)
            return
        const p = (flow.inputPrompt || "").trim().replace(/:$/, "").trim().toLowerCase()
        heading = (flow.message || "").toLowerCase()
        detail = flow.actionId || ""
        hint = p === "" ? "password" : p
        fault = flow.supplementaryIsError && flow.supplementaryMessage !== ""
            ? flow.supplementaryMessage.toLowerCase()
            : "authentication failed, try again"
    }

    function submit() {
        if (!root.asking || input.text === "") return
        root.flow.submit(input.text)
        input.text = ""
        input.forceActiveFocus()
    }

    function cancel() {
        Polkit.cancel()
    }

    function reset() {
        input.text = ""
        slip = false
    }

    onVisibleChanged: {
        reset()
        if (visible) {
            forceActiveFocus()
            input.forceActiveFocus()
        }
    }

    Connections {
        target: Polkit
        function onOpenChanged() {
            if (!Polkit.open)
                return
            root.reset()
            root.forceActiveFocus()
            input.forceActiveFocus()
        }
    }

    Connections {
        target: Polkit.flow
        function onInputPromptChanged() { root.take() }
        function onIsResponseRequiredChanged() {
            if (!root.asking)
                return
            input.text = ""
            input.forceActiveFocus()
        }
        function onFailedChanged() {
            if (!Polkit.flow || !Polkit.flow.failed) return
            root.take()
            root.slip = true
            shake.restart()
            input.forceActiveFocus()
        }
        function onSupplementaryMessageChanged() {
            root.take()
            if (Polkit.flow && Polkit.flow.supplementaryIsError && Polkit.flow.supplementaryMessage !== "")
                root.slip = true
        }
    }

    Keys.onPressed: e => {
        if (e.key === Qt.Key_Escape) {
            root.cancel()
            e.accepted = true
        }
    }

    SequentialAnimation {
        id: shake

        NumberAnimation {
            target: field
            property: "x"
            to: Theme.authShake
            duration: Theme.authShakeStep
            easing.type: Easing.OutSine
        }

        SequentialAnimation {
            loops: 2

            NumberAnimation {
                target: field
                property: "x"
                to: -Theme.authShake
                duration: Theme.authShakeStep * 2
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                target: field
                property: "x"
                to: Theme.authShake
                duration: Theme.authShakeStep * 2
                easing.type: Easing.InOutSine
            }
        }

        NumberAnimation {
            target: field
            property: "x"
            to: 0
            duration: Theme.authShakeStep
            easing.type: Easing.InSine
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.authSpacing

        Item {
            width: parent.width
            height: Math.max(Theme.authIcon, head.height)

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.authIcon
                height: Theme.authIcon
                radius: Theme.authIconR
                color: Theme.chip
                border.width: Theme.surfaceBorderWidth
                border.color: Theme.surfaceBorder
                antialiasing: true

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

            Column {
                id: head
                x: Theme.authIcon + Theme.authHeadGap
                width: parent.width - x
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.authHeadTextGap

                Txt {
                    width: parent.width
                    height: Theme.authTitleH
                    verticalAlignment: Text.AlignVCenter
                    text: "authentication required"
                    font.pixelSize: Theme.fsL
                    font.weight: Font.DemiBold
                }

                Txt {
                    width: parent.width
                    visible: text !== ""
                    text: root.heading
                    wrapMode: Text.Wrap
                    maximumLineCount: Theme.authMsgLines
                    elide: Text.ElideRight
                    opacity: Theme.dimMuted
                    font.pixelSize: Theme.fsS
                }
            }
        }

        Item {
            width: parent.width
            height: Theme.authFieldH + Theme.authStatusGap + Theme.authStatusH

            Rectangle {
                id: field
                width: parent.width
                height: Theme.authFieldH
                radius: Theme.authFieldR
                color: Theme.chip
                border.width: Theme.surfaceBorderWidth
                border.color: root.slip ? Theme.red : input.activeFocus ? Theme.accent : Theme.surfaceBorder
                antialiasing: true

                Behavior on border.color { ColorAnimation { duration: Theme.feedbackDuration } }

                TextInput {
                    id: input
                    x: Theme.authFieldTextX
                    width: parent.width - 2 * Theme.authFieldTextX - dots.width
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fg
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.bg
                    echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                    passwordCharacter: Theme.passChar
                    selectByMouse: true
                    clip: true
                    font.family: Theme.font
                    font.pixelSize: Theme.fsL
                    font.weight: Font.Medium
                    enabled: root.asking
                    onTextEdited: root.slip = false
                    onAccepted: root.submit()
                }

                Txt {
                    x: input.x
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.hint
                    visible: input.text === "" && !root.busy
                    opacity: Theme.dimHint
                    font.pixelSize: Theme.fsL
                }

                Row {
                    id: dots
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.authFieldTextX
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.authDotGap
                    opacity: root.busy ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: Theme.fade; easing.type: Theme.ease } }

                    Repeater {
                        model: Theme.authDots

                        Rectangle {
                            required property int index
                            width: Theme.authDotS
                            height: Theme.authDotS
                            radius: width / 2
                            color: Theme.fg
                            opacity: Theme.dimHint
                            antialiasing: true

                            SequentialAnimation on opacity {
                                running: root.busy
                                loops: Animation.Infinite

                                PauseAnimation { duration: index * Theme.authDotStagger }

                                NumberAnimation {
                                    to: 1
                                    duration: Theme.authDotStep
                                    easing.type: Easing.InOutSine
                                }

                                NumberAnimation {
                                    to: Theme.dimHint
                                    duration: Theme.authDotStep
                                    easing.type: Easing.InOutSine
                                }

                                PauseAnimation { duration: (Theme.authDots - 1 - index) * Theme.authDotStagger }
                            }
                        }
                    }
                }
            }

            Txt {
                x: Theme.authFieldTextX
                y: Theme.authFieldH + Theme.authStatusGap
                width: parent.width - 2 * Theme.authFieldTextX
                height: Theme.authStatusH
                verticalAlignment: Text.AlignVCenter
                text: root.slip ? root.fault : root.detail
                color: root.slip ? Theme.red : Theme.fg
                opacity: root.slip ? 1 : Theme.dimGhost
                elide: root.slip ? Text.ElideRight : Text.ElideMiddle
                font.pixelSize: Theme.fsXS

                Behavior on color { ColorAnimation { duration: Theme.feedbackDuration } }
                Behavior on opacity { NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease } }
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
                    radius: height / 2
                    color: cancelArea.containsMouse ? Theme.tile : Theme.chip
                    scale: cancelArea.pressed ? Theme.feedbackPressScale : cancelArea.containsMouse ? Theme.feedbackHoverScale : 1
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
                        id: cancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancel()
                    }
                }

                Rectangle {
                    readonly property bool live: root.asking && input.text !== ""
                    width: Math.round(okTxt.width + Theme.authBtnPadX)
                    height: Theme.authBtnH
                    radius: height / 2
                    color: Theme.accent
                    opacity: live ? (okArea.pressed ? Theme.authPressed : 1) : Theme.authDisabled
                    scale: live && okArea.pressed ? Theme.feedbackPressScale : live && okArea.containsMouse ? Theme.feedbackHoverScale : 1
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
                        id: okArea
                        anchors.fill: parent
                        enabled: parent.live
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submit()
                    }
                }
            }
        }
    }
}

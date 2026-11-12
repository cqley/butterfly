import "../core"
import QtQuick

Item {
    id: root
    property real from: 0
    property real to: 1
    property real step: 0
    property real value: 0
    signal moved(real value)
    signal committed

    readonly property real span: root.to - root.from
    readonly property real ratio: root.span > 0 ? Math.max(0, Math.min(1, (root.value - root.from) / root.span)) : 0
    readonly property int trackY: Math.round((root.height - Theme.settingsSliderH) / 2)
    readonly property real axis: root.trackY + Theme.settingsSliderH / 2

    width: Theme.settingsSliderW
    height: Theme.settingsSliderKnobD
    activeFocusOnTab: true

    onRatioChanged: if (drag.pressed) pos.land(root.ratio)

    Spring {
        id: pos
        target: root.ratio
        response: Theme.settingsMoveResponse
        damping: Theme.settingsMoveDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    function quantize(v) {
        const clamped = Math.max(root.from, Math.min(root.to, v))
        if (root.step <= 0)
            return clamped
        return root.from + Math.round((clamped - root.from) / root.step) * root.step
    }

    function emitAt(r) {
        root.moved(root.quantize(root.from + Math.max(0, Math.min(1, r)) * root.span))
    }

    function nudge(d) {
        root.moved(root.quantize(root.value + (root.step > 0 ? root.step : root.span * Theme.settingsStepKey) * d))
        root.committed()
    }

    Keys.onPressed: e => {
        Settings.keyNav = true
        if (e.key === Qt.Key_Left) {
            root.nudge(-1)
            e.accepted = true
        } else if (e.key === Qt.Key_Right) {
            root.nudge(1)
            e.accepted = true
        } else if (e.key === Qt.Key_Home) {
            root.moved(root.from)
            root.committed()
            e.accepted = true
        } else if (e.key === Qt.Key_End) {
            root.moved(root.to)
            root.committed()
            e.accepted = true
        }
    }

    SettingsFocus {
        radius: root.height / 2 + Theme.settingsFocusPad
        focused: root.activeFocus
    }

    Rectangle {
        y: root.trackY
        width: parent.width
        height: Theme.settingsSliderH
        radius: height / 2
        color: Theme.settingsTrack
        antialiasing: true

        Rectangle {
            width: parent.width * pos.value
            height: parent.height
            radius: height / 2
            color: Theme.accent
            antialiasing: true
        }
    }

    Rectangle {
        x: pos.value * (root.width - width)
        y: root.axis - height / 2
        width: Theme.settingsSliderKnobD
        height: Theme.settingsSliderKnobD
        radius: width / 2
        color: Theme.knobInk
        antialiasing: true
        scale: knobScale.shaped

        ScaleSpring {
            id: knobScale
            size: Theme.settingsSliderKnobD
            target: drag.pressed ? Theme.feedbackPressScale : 1
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        anchors.topMargin: -Theme.settingsSliderHitPad
        anchors.bottomMargin: -Theme.settingsSliderHitPad

        onPressed: mouse => {
            Settings.keyNav = false
            root.forceActiveFocus()
            root.emitAt(mouse.x / root.width)
        }
        onPositionChanged: mouse => {
            if (pressed)
                root.emitAt(mouse.x / root.width)
        }
        onReleased: root.committed()
    }
}

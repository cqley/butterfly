import QtQuick

Fade {
    id: root
    property real pad: 0
    property real padX: pad
    property real padBottom: pad
    property real wantW: width + 2 * padX
    property real wantH: y + height + padBottom
    property QtObject owner: null
    property Item focusTarget: root
    property bool takesFocus: owner !== null
    property bool freshOnShow: false
    property bool freshOnHide: true
    property bool keepWhileOpen: false

    signal fresh

    y: pad

    onVisibleChanged: {
        if (!root.takesFocus)
            return
        if (root.visible) {
            if (root.freshOnShow)
                root.fresh()
            root.focusTarget.forceActiveFocus()
        } else if (root.freshOnHide && !(root.keepWhileOpen && root.owner && root.owner.open)) {
            root.fresh()
        }
    }

    Connections {
        target: root.owner
        function onOpenChanged() {
            if (!root.owner.open)
                return
            root.fresh()
            root.focusTarget.forceActiveFocus()
        }
    }
}

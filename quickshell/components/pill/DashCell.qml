import "../core"
import QtQuick

Item {
    id: cell

    property bool shown: true
    property int gap: 0
    property real contentW: 0
    property var origin: null
    property bool fades: false
    property bool hoverable: false
    property bool togglable: false
    property bool stages: false
    signal activated
    signal toggled

    default property alias content: holder.data

    readonly property real t: parent && parent.t !== undefined ? parent.t : 1
    readonly property real reveal: parent && parent.reveal !== undefined ? parent.reveal : 1
    readonly property real late: parent && parent.late !== undefined ? parent.late : 1
    readonly property real originY: parent && parent.originY !== undefined ? parent.originY : 0
    readonly property bool live: parent && parent.live !== undefined ? parent.live : true
    readonly property real calm: parent && parent.calm !== undefined ? parent.calm : 1
    readonly property real rowCy: parent && parent.rowCy !== undefined ? parent.rowCy : 0
    readonly property bool morphs: cell.origin !== null && cell.origin !== undefined
    readonly property real hold: cell.stages && !cell.morphs ? Math.min(cell.calm, cell.late) : 1
    readonly property real homeCx: (parent ? parent.x : 0) + cell.x + cell.gap + cell.contentW / 2
    readonly property real travelX: cell.morphs ? (1 - cell.t) * (cell.origin - cell.homeCx) : 0
    readonly property real travelY: cell.morphs ? (1 - cell.t) * (cell.originY - cell.rowCy) : 0
    readonly property bool hovered: hit.containsMouse
    readonly property bool pressed: hit.pressed
    property real touchScale: cell.pressed ? Theme.feedbackPressScale : cell.hovered ? Theme.feedbackHoverScale : 1

    Behavior on touchScale {
        NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
    }

    width: cell.shown ? Math.round(cell.gap + cell.contentW) : 0
    height: parent ? parent.height : 0
    visible: cell.width > 0.5
    opacity: cell.shown && cell.morphs && !cell.fades ? 1 : cell.shown ? cell.reveal * cell.hold : 0

    Behavior on width {
        NumberAnimation { duration: Theme.glide; easing.type: Theme.ease }
    }

    transform: Translate {
        x: cell.travelX
        y: cell.travelY
    }

    Item {
        id: frame
        y: -cell.height
        width: cell.width
        height: cell.height * 3
        clip: cell.travelX === 0 && cell.travelY === 0

        Item {
            id: holder
            x: cell.gap
            y: cell.height
            width: cell.contentW
            height: cell.height
            transformOrigin: Item.Center
            scale: cell.touchScale
        }
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        visible: cell.hoverable && cell.shown && cell.live
        hoverEnabled: hit.visible
        acceptedButtons: cell.togglable ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => e.button === Qt.RightButton ? cell.toggled() : cell.activated()
    }
}

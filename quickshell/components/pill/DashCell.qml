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
    property bool stages: true
    property bool bounces: true
    property var lead: null
    signal activated
    signal toggled

    default property alias content: holder.data

    readonly property real t: parent && parent.t !== undefined ? parent.t : 1
    readonly property real tFlat: parent && parent.tFlat !== undefined ? parent.tFlat : 1
    readonly property real travelT: cell.bounces ? cell.t : cell.tFlat
    readonly property real reveal: parent && parent.reveal !== undefined ? parent.reveal : 1
    readonly property real late: parent && parent.late !== undefined ? parent.late : 1
    readonly property real originY: parent && parent.originY !== undefined ? parent.originY : 0
    readonly property bool live: parent && parent.live !== undefined ? parent.live : true
    readonly property real calm: parent && parent.calm !== undefined ? parent.calm : 1
    readonly property real rowCy: parent && parent.rowCy !== undefined ? parent.rowCy : 0
    readonly property bool morphs: cell.origin !== null && cell.origin !== undefined
    readonly property real hold: cell.stages && !cell.morphs ? Math.min(cell.calm, cell.late) : 1
    readonly property real homeCx: (parent ? parent.x : 0) + cell.x + cell.gap + cell.contentW / 2
    readonly property real reach: cell.morphs ? cell.origin - cell.homeCx : 0
    readonly property bool locked: cell.morphs && !!cell.lead && cell.lead.morphs && cell.lead.shown
    readonly property real travelX: !cell.morphs ? 0
        : cell.locked ? cell.lead.travelX + Math.pow(Math.max(0, 1 - cell.travelT), Theme.dashColumnLock) * (cell.reach - cell.lead.reach)
        : (1 - cell.travelT) * cell.reach
    readonly property real travelY: cell.morphs ? (1 - cell.travelT) * (cell.originY - cell.rowCy) : 0
    readonly property bool hovered: hit.containsMouse
    readonly property bool pressed: hit.pressed
    readonly property real touchScale: touch.shaped

    width: widthMotion.shaped
    height: parent ? parent.height : 0
    visible: cell.width > 0.5
    opacity: cell.shown && cell.morphs && !cell.fades ? 1 : cell.shown ? cell.reveal * cell.hold : 0

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

        ScaleSpring {
            id: touch
            size: cell.contentW
            target: cell.pressed ? Theme.feedbackPressScale : cell.hovered ? Theme.feedbackHoverScale : 1
        }

        ScaleSpring {
            id: pop
            size: cell.contentW
            response: Theme.dashMorphResponse
            damping: pop.target < 1 ? 1 : Theme.dashMorphDamping
            target: cell.stages && !cell.morphs && cell.hold <= 0.001 ? Theme.dashPopFrom : 1
        }

        Spring {
            id: widthMotion
            response: Theme.glideResponse
            settle: Theme.springSettle
            target: cell.shown ? Math.round(cell.gap + cell.contentW) : 0
        }

        Item {
            id: holder
            x: cell.gap
            y: cell.height
            width: cell.contentW
            height: cell.height
            transformOrigin: Item.Center
            scale: cell.touchScale * pop.shaped
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

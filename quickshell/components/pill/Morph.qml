import "../core"
import QtQuick

Item {
    id: root
    property bool face: false
    property bool bare: false
    property bool islandOpen: false
    property bool dashVisible: false
    property bool visualizer: false
    property bool wsAvailable: false

    property bool wasClosed: true
    property bool openedFromIdle: true
    property bool heldVis: false
    property real orphanVeil: 1

    readonly property bool runs: root.openedFromIdle && (root.face || root.bare)
    readonly property bool staged: root.face && !root.runs
    readonly property real t: root.runs ? drive.shaped : 1
    readonly property real tFlat: root.runs ? flat.shaped : 1
    readonly property bool morphing: root.runs && (root.face || drive.moving || flat.moving)
    readonly property bool live: root.face || root.morphing || exit.running
    readonly property bool leaving: root.live && !root.face && !root.morphing
    readonly property bool veiled: root.morphing || root.dashVisible
    readonly property real veil: root.runs ? (root.veiled ? 0 : 1) : root.orphanVeil
    readonly property bool wsMorphs: Theme.dashWs && root.wsAvailable
    readonly property real wsVeil: root.wsMorphs ? root.veil : root.orphanVeil

    function arm() {
        root.wasClosed = !root.islandOpen
        root.heldVis = root.visualizer
        if (!root.face) {
            drive.land(0)
            flat.land(0)
        }
    }

    onFaceChanged: {
        if (!root.face) {
            exit.restart()
            return
        }
        root.openedFromIdle = root.wasClosed
        exit.stop()
    }

    onVeiledChanged: {
        veilRun.stop()
        veilRun.duration = root.veiled ? Theme.fall : Theme.rise
        veilRun.to = root.veiled ? 0 : 1
        veilRun.start()
    }

    Timer {
        id: exit
        interval: Theme.fall
    }

    NumberAnimation {
        id: veilRun
        target: root
        property: "orphanVeil"
        easing.type: Theme.ease
    }

    Spring {
        id: drive
        target: root.face ? 1 : 0
        hold: root.face ? Theme.dashBounceHold : Theme.dashMorphHold
        response: root.face ? Theme.dashMorphResponse : Theme.islandResponse
        damping: root.face ? Theme.dashMorphDamping : Theme.islandDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }

    Spring {
        id: flat
        target: root.face ? 1 : 0
        hold: Theme.dashMorphHold
        response: Theme.islandResponse
        damping: Theme.islandDamping
        epsilon: Theme.springUnitEps
        rest: Theme.springUnitStop
    }
}

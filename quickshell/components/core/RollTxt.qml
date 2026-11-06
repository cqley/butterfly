import QtQuick
import QtQuick.Effects

Item {
    id: root
    property string text: ""
    property alias font: base.font
    property color color: Theme.fg
    property int horizontalAlignment: Text.AlignHCenter
    property real dx: 0
    property string last: ""
    property string prior: ""
    readonly property real originX: root.horizontalAlignment === Text.AlignHCenter
        ? (root.width - base.contentWidth) / 2
        : root.horizontalAlignment === Text.AlignRight ? root.width - base.contentWidth : 0
    readonly property real lift: base.font.pixelSize * Theme.clockRollLift
    readonly property real bleed: base.font.pixelSize * 0.25
    readonly property real band: base.font.pixelSize * Theme.clockRollBand
    readonly property real bandY: (root.height - root.band) / 2 - optical.shift

    implicitWidth: base.implicitWidth
    implicitHeight: base.implicitHeight

    onTextChanged: {
        root.prior = root.last
        root.last = root.text
        for (let i = 0; i < cells.count; i++) {
            const c = cells.itemAt(i)
            if (c)
                c.sync()
        }
    }

    Component.onCompleted: {
        root.last = root.text
        root.prior = root.text
    }

    Txt {
        id: base
        anchors.fill: parent
        visible: false
        text: root.text
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: Text.AlignVCenter
    }

    OpticalCenter {
        id: optical
        targetFont: base.font
        text: root.text
    }

    transform: Translate {
        x: root.dx
        y: optical.shift
    }

    Repeater {
        id: cells
        model: Theme.clockRollCells

        Item {
            id: cell
            required property int index
            readonly property int at: root.text.length - 1 - cell.index
            readonly property int wasAt: root.prior.length - 1 - cell.index
            readonly property real padL: cell.at === 0 ? root.bleed : 0
            readonly property real padR: cell.index === 0 ? root.bleed : 0
            property real p: 1
            readonly property real blur: Math.sin(Math.PI * cell.p) * Theme.clockRollBlur

            function sync() {
                const a = root.text.length - 1 - cell.index
                const b = root.prior.length - 1 - cell.index
                if ((a >= 0 ? root.text.charAt(a) : "") !== (b >= 0 ? root.prior.charAt(b) : ""))
                    run.restart()
            }

            visible: cell.at >= 0
            x: root.originX + head.advanceWidth - cell.padL
            y: root.bandY
            width: upto.advanceWidth - head.advanceWidth + cell.padL + cell.padR
            height: root.band
            clip: true

            TextMetrics {
                id: head
                font: base.font
                text: cell.at > 0 ? root.text.substring(0, cell.at) : ""
            }

            TextMetrics {
                id: upto
                font: base.font
                text: cell.at >= 0 ? root.text.substring(0, cell.at + 1) : ""
            }

            TextMetrics {
                id: wasHead
                font: base.font
                text: cell.wasAt > 0 ? root.prior.substring(0, cell.wasAt) : ""
            }

            NumberAnimation {
                id: run
                target: cell
                property: "p"
                from: 0
                to: 1
                duration: Theme.clockRoll
                easing.type: Theme.ease
            }

            Txt {
                x: cell.padL - wasHead.advanceWidth
                y: -root.bandY - root.lift * cell.p
                height: root.height
                verticalAlignment: Text.AlignVCenter
                font: base.font
                color: root.color
                text: root.prior
                opacity: 1 - cell.p
                visible: cell.p < 1
                layer.enabled: cell.p < 1
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: Theme.clockRollBlurMax
                    blur: cell.blur
                }
            }

            Txt {
                x: cell.padL - head.advanceWidth
                y: -root.bandY + root.lift * (1 - cell.p)
                height: root.height
                verticalAlignment: Text.AlignVCenter
                font: base.font
                color: root.color
                text: root.text
                opacity: cell.p
                layer.enabled: cell.p < 1
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: Theme.clockRollBlurMax
                    blur: cell.blur
                }
            }
        }
    }
}

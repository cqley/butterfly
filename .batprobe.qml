import Quickshell
import Quickshell.Wayland
import QtQuick
import "components/core"
import "components/status"

PanelWindow {
    anchors { top: true; left: true }
    implicitWidth: 300
    implicitHeight: 150
    exclusionMode: ExclusionMode.Ignore
    color: Theme.bg
    WlrLayershell.layer: WlrLayer.Overlay

    component BatRow: Row {
        property bool plugged: false
        property bool full: false
        spacing: 14
        Repeater {
            model: [0.08, 0.3, 0.6, 1.0]
            BatteryIcon {
                required property real modelData
                shown: true
                available: true
                pct: modelData
                pluggedIn: plugged
                charged: full
                tone: plugged ? Theme.batGreen
                    : modelData <= Theme.batRedAt ? Theme.batRed
                    : modelData <= Theme.batYellowAt ? Theme.batYellow : Theme.batGreen
                leadingGap: 0
            }
        }
    }

    Column {
        x: 10
        y: 10
        spacing: 14
        BatRow { plugged: false; full: false }
        BatRow { plugged: true;  full: false }
        BatRow { plugged: true;  full: true }
    }
}

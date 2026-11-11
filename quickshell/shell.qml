import Quickshell
import Quickshell.Wayland
import QtQuick
import "components/core"
import "components/pill"
import "components/screenshot"
import "components/settings"

Scope {
    readonly property bool probing: Probe.on

    Variants {
        model: Theme.shellScreens

        Scope {
            required property var modelData

            PanelWindow {
                screen: modelData
                anchors {
                    top: true
                    left: true
                    right: true
                }
                readonly property int reserve: pill.hidden && Theme.barFreesZone ? 0 : Theme.zone
                implicitHeight: Math.max(1, reserve)
                exclusiveZone: reserve
                aboveWindows: false
                color: "transparent"
                mask: Region {}
            }

            PanelWindow {
                id: win
                readonly property bool modal: Modal.any && Modal.which !== "settings" && Modal.which !== "osd"
                property var pillMask: Region { item: pill.hitTarget }
                property var openMask: Region { width: win.width; height: win.height }
                property var tuckMask: Region {}

                screen: modelData
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                mask: modal ? openMask : pill.tucking ? tuckMask : pillMask
                WlrLayershell.keyboardFocus: modal ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                Pill { id: pill }
            }
        }
    }

    Variants {
        model: Theme.shellScreens

        Scope {
            required property var modelData

            PanelWindow {
                id: setWin

                screen: modelData
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                mask: Settings.open ? openMask : closedMask
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-settings"
                WlrLayershell.keyboardFocus: Settings.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                property var openMask: Region { width: setWin.width; height: setWin.height }
                property var closedMask: Region {}

                Item {
                    anchors.fill: parent

                    TapHandler {
                        enabled: Settings.open
                        onTapped: p => {
                            const point = settingsPopup.mapFromItem(parent, p.position)
                            if (!settingsPopup.contains(point))
                                Modal.dismiss()
                        }
                    }

                    SettingsWindow { id: settingsPopup }
                }
            }
        }
    }

    RegionPicker {}
    TargetPicker {}
}

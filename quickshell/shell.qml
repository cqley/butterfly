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
        model: {
            const m = Quickshell.screens.filter(s => s.name === Theme.screen)
            return m.length ? m : Quickshell.screens.slice(0, 1)
        }

        Scope {
            required property var modelData

            PanelWindow {
                screen: modelData
                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: Theme.zone
                exclusiveZone: Theme.zone
                aboveWindows: false
                color: "transparent"
                mask: Region {}
            }

            PanelWindow {
                id: win
                readonly property bool modal: Modal.any
                property var pillMask: Region { item: pill.hitTarget }
                property var openMask: Region { width: win.width; height: win.height }

                screen: modelData
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                mask: modal ? openMask : pillMask
                WlrLayershell.keyboardFocus: modal ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                Pill { id: pill }
            }
        }
    }

    Variants {
        model: Quickshell.screens.filter(s => s.name === Settings.screenName)

        Scope {
            required property var modelData

            PanelWindow {
                id: setWin

                screen: modelData
                visible: settingsPopup.alive
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                mask: Settings.open ? openMask : closedMask
                WlrLayershell.layer: WlrLayer.Overlay
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

import Quickshell
import Quickshell.Wayland
import QtQuick
import "components/core"
import "components/lock"
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
                implicitHeight: 1
                exclusionMode: ExclusionMode.Normal
                exclusiveZone: reserve
                aboveWindows: false
                color: "transparent"
                mask: Region {}
            }

            PanelWindow {
                id: win
                readonly property bool modal: Modal.any && Modal.which !== "settings" || Locker.covering
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

                LockWall {
                    id: lockWall
                    visible: Locker.covering
                    t: Locker.fade
                }

                Clock {
                    id: lockClock
                    visible: Locker.covering
                    t: Locker.t
                    move: Locker.move
                    from: pill.lockClockSeen
                    fromInk: pill.idleClock
                    to: Qt.point(win.width / 2, win.height / 2 + Theme.lockerClockOffsetY)
                    wall: lockWall.glass
                    text: Theme.clockText(pill.clockNow)
                }

                Pill {
                    id: pill
                    lockShift: Locker.covering ? Qt.point(lockClock.cx - pill.lockClockSeen.x, lockClock.cy - pill.lockClockSeen.y) : Qt.point(0, 0)
                    lockScale: Locker.covering ? lockClock.size / Theme.clockPx : 1
                }

                Item {
                    id: lockKeys
                    Keys.onPressed: e => {
                        Locker.key(e)
                        e.accepted = true
                    }

                    Connections {
                        target: Locker
                        function onCoveringChanged() {
                            if (Locker.covering)
                                lockKeys.forceActiveFocus()
                        }
                    }
                }

                Loader {
                    anchors.fill: parent
                    active: Locker.preview && Locker.phase === "locked"
                    sourceComponent: LockStage {}
                }
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

    LockSession {}

    RegionPicker {}
    TargetPicker {}
}

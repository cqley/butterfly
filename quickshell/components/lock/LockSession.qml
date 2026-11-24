import "../core"
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    WlSessionLock {
        id: session
        locked: Locker.held
        onLockedChanged: if (!locked) Locker.lost()

        WlSessionLockSurface {
            id: surface
            color: "black"

            Item {
                id: sink
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => {
                    Locker.key(e)
                    e.accepted = true
                }
                Component.onCompleted: sink.forceActiveFocus()

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onPressed: sink.forceActiveFocus()
                }
            }

            Loader {
                anchors.fill: parent
                active: !!surface.screen && surface.screen.name === Theme.shellScreen
                sourceComponent: LockStage {
                    sealed: true
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens.filter(s => s.name !== Theme.shellScreen)

        PanelWindow {
            id: shadeWin
            required property var modelData
            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"
            mask: Region {}

            Rectangle {
                id: shade
                anchors.fill: parent
                color: "black"
                opacity: 0
            }

            OpacityAnimator {
                id: shadeIn
                target: shade
                to: 1
                duration: Theme.lockerShadeIn
                easing.type: Theme.ease
            }

            OpacityAnimator {
                id: shadeOut
                target: shade
                to: 0
                duration: Theme.lockerShadeOut
                easing.type: Theme.ease
            }

            function clear() {
                if (shadeOut.running)
                    return
                shadeIn.stop()
                shadeOut.start()
            }

            Connections {
                target: Locker
                function onPhaseChanged() {
                    if (Locker.down && !Locker.leaving) {
                        shadeOut.stop()
                        shadeIn.start()
                    } else if (Locker.phase === "opening") {
                        shadeWin.clear()
                    }
                }
                function onLeavingChanged() {
                    if (Locker.leaving)
                        shadeWin.clear()
                    else if (Locker.down) {
                        shadeOut.stop()
                        shadeIn.start()
                    }
                }
            }
        }
    }

    Binding {
        target: Locker
        property: "secure"
        value: session.secure
    }
}

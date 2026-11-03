import "../core"
import QtQuick
import Quickshell

Column {
    id: root
    readonly property var screens: Quickshell.screens.map(s => s.name)

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "monitor"
            token: "screen"

            SettingsSegmented {
                options: root.screens
                current: Math.max(0, root.screens.indexOf(Theme.screen))
                onPicked: i => {
                    Cfg.set("screen", root.screens[i])
                    Cfg.flush()
                }
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "charge ring"
            token: "batRingEnabled"

            SettingsToggle {
                checked: Theme.batRingEnabled
                onToggled: on => {
                    Cfg.set("batRingEnabled", on)
                    Cfg.flush()
                }
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "reset everything to defaults"
            value: Cfg.count === 0 ? "nothing changed" : Cfg.count + " changed"
            showArrow: Cfg.count > 0
            onActivated: {
                Cfg.clearAll()
                Cfg.flush()
            }
        }
    }
}

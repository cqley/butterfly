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
            note: "moves every shell surface"
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

    SettingsSection { text: "battery" }

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

        SettingsRow {
            label: "ring width"
            token: "batRingWidth"
            value: Theme.batRingWidth.toFixed(1) + " px"

            SettingsSlider {
                from: 1
                to: 5
                step: 0.5
                value: Theme.batRingWidth
                onMoved: v => Cfg.set("batRingWidth", Math.round(v * 10) / 10)
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "low below"
            token: "batYellowAt"
            value: Math.round(Theme.batYellowAt * 100) + "%"

            SettingsSlider {
                from: 0.05
                to: 0.6
                step: 0.01
                value: Theme.batYellowAt
                onMoved: v => Cfg.set("batYellowAt", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "critical below"
            token: "batRedAt"
            value: Math.round(Theme.batRedAt * 100) + "%"

            SettingsSlider {
                from: 0.02
                to: 0.4
                step: 0.01
                value: Theme.batRedAt
                onMoved: v => Cfg.set("batRedAt", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }
    }

    SettingsSection { text: "reset" }

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

import "../core"
import QtQuick

Column {
    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "show percentages"
            token: "mixerPct"

            SettingsToggle {
                checked: Theme.mixerPct
                onToggled: on => {
                    Cfg.set("mixerPct", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "show per-app streams"
            token: "mixerApps"

            SettingsToggle {
                checked: Theme.mixerApps
                onToggled: on => {
                    Cfg.set("mixerApps", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "show device labels"
            token: "mixerLabels"

            SettingsToggle {
                checked: Theme.mixerLabels
                onToggled: on => {
                    Cfg.set("mixerLabels", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "scroll step"
            token: "mixerStep"
            value: Theme.mixerStep + "%"

            SettingsSlider {
                from: 1
                to: 20
                step: 1
                value: Theme.mixerStep
                onMoved: v => Cfg.set("mixerStep", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "track height"
            token: "mixerTrackH"
            value: Theme.mixerTrackH + " px"

            SettingsSlider {
                from: 48
                to: 160
                step: 2
                value: Theme.mixerTrackH
                onMoved: v => Cfg.set("mixerTrackH", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }
}

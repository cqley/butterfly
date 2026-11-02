import "../core"
import QtQuick

Column {
    id: root
    readonly property var modes: ["popout", "classic"]

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "island interaction"
            note: "click to open a panel, or open on hover"
            token: "islandMode"

            SettingsSegmented {
                options: ["pop-out", "classic"]
                current: Math.max(0, root.modes.indexOf(Theme.islandMode))
                onPicked: i => {
                    Cfg.set("islandMode", root.modes[i])
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "menu crossfade"
            note: "not implemented in this shell yet"
            value: "—"
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "response"
            token: "springResponse"
            value: Theme.springResponse.toFixed(2) + " s"

            SettingsSlider {
                from: 0.08
                to: 0.6
                step: 0.01
                value: Theme.springResponse
                onMoved: v => Cfg.set("springResponse", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "damping"
            token: "springDamping"
            value: Theme.springDamping.toFixed(2)

            SettingsSlider {
                from: 0.4
                to: 1.6
                step: 0.05
                value: Theme.springDamping
                onMoved: v => Cfg.set("springDamping", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "transition"
            note: "panel and window transitions"
            token: "speed"
            value: Theme.speed + " ms"

            SettingsSlider {
                from: 80
                to: 600
                step: 10
                value: Theme.speed
                onMoved: v => Cfg.set("speed", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "micro-transition"
            note: "toggles, selections and colour changes"
            token: "glide"
            value: Theme.glide + " ms"

            SettingsSlider {
                from: 40
                to: 500
                step: 10
                value: Theme.glide
                onMoved: v => Cfg.set("glide", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }
}

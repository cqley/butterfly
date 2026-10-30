import "../core"
import QtQuick

Column {
    id: root
    readonly property var styles: ["spring", "classic"]
    readonly property var modes: ["popout", "classic"]
    readonly property string springNote: Theme.motionStyle === "spring" ? "" : "spring style only"

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "animation style"
            token: "motionStyle"

            SettingsSegmented {
                options: ["new (spring)", "classic"]
                current: Math.max(0, root.styles.indexOf(Theme.motionStyle))
                onPicked: i => {
                    Cfg.set("motionStyle", root.styles[i])
                    Cfg.flush()
                }
            }
        }

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
            label: "reduce motion"
            note: "collapses every transition to a short fade"
            token: "motionReduce"

            SettingsToggle {
                checked: Theme.motionReduce
                onToggled: on => {
                    Cfg.set("motionReduce", on)
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

    SettingsSection { text: "spring" }

    SettingsGroup {
        SettingsRow {
            label: "response"
            note: root.springNote
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
            note: root.springNote
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

    SettingsSection { text: "timing" }

    SettingsGroup {
        SettingsRow {
            label: "transition"
            note: "classic easing duration, and the fallback when springs are off"
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

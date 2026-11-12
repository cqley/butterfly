import "../core"
import QtQuick

Column {
    id: root

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

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

    SettingsGroup {
        SettingsRow {
            label: "menu bounce"
            token: "menuBounce"

            SettingsToggle {
                checked: Theme.menuBounce
                onToggled: on => {
                    Cfg.set("menuBounce", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "bounce speed"
            token: "menuBounceResponse"
            value: Theme.menuBounceResponse.toFixed(2) + " s"

            SettingsSlider {
                from: 0.2
                to: 0.7
                step: 0.01
                value: Theme.menuBounceResponse
                onMoved: v => Cfg.set("menuBounceResponse", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "bounce damping"
            token: "menuBounceDamping"
            value: Theme.menuBounceDamping.toFixed(2)

            SettingsSlider {
                from: 0.3
                to: 0.95
                step: 0.05
                value: Theme.menuBounceDamping
                onMoved: v => Cfg.set("menuBounceDamping", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "overshoot limit"
            token: "menuBounceReach"
            value: Theme.menuBounceReach + " px"

            SettingsSlider {
                from: 4
                to: 64
                step: 1
                value: Theme.menuBounceReach
                onMoved: v => Cfg.set("menuBounceReach", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "close dip"
            token: "menuBounceDip"
            value: Math.round(Theme.menuBounceDip * 100) + "%"

            SettingsSlider {
                from: 0
                to: 0.2
                step: 0.01
                value: Theme.menuBounceDip
                onMoved: v => Cfg.set("menuBounceDip", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "dip when switching menus"
            token: "menuSwitchDip"

            SettingsToggle {
                checked: Theme.menuSwitchDip
                onToggled: on => {
                    Cfg.set("menuSwitchDip", on)
                    Cfg.flush()
                }
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "dashboard bounce speed"
            token: "dashMorphResponse"
            value: Theme.dashMorphResponse.toFixed(2) + " s"

            SettingsSlider {
                from: 0.2
                to: 0.7
                step: 0.01
                value: Theme.dashMorphResponse
                onMoved: v => Cfg.set("dashMorphResponse", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "dashboard bounce damping"
            token: "dashMorphDamping"
            value: Theme.dashMorphDamping.toFixed(2)

            SettingsSlider {
                from: 0.3
                to: 1
                step: 0.05
                value: Theme.dashMorphDamping
                onMoved: v => Cfg.set("dashMorphDamping", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }
    }
}

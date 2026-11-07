import "../core"
import QtQuick

Column {
    id: root

    readonly property var places: ["left", "right", "only"]

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "show workspaces"
            token: "wsOn"

            SettingsToggle {
                checked: Theme.wsOn
                onToggled: on => {
                    Cfg.set("wsOn", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "placement"
            token: "wsPlace"

            SettingsSegmented {
                options: ["left", "right", "only"]
                current: Math.max(0, root.places.indexOf(Theme.wsPlace))
                onPicked: i => {
                    Cfg.set("wsPlace", root.places[i])
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "style"
            token: "wsVertical"

            SettingsSegmented {
                options: ["dots", "bars"]
                current: Theme.wsVertical ? 1 : 0
                onPicked: i => {
                    Cfg.set("wsVertical", i === 1)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "click to switch"
            token: "wsClick"

            SettingsToggle {
                checked: Theme.wsClick
                onToggled: on => {
                    Cfg.set("wsClick", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "accent the active workspace"
            token: "wsAccent"

            SettingsToggle {
                checked: Theme.wsAccent
                onToggled: on => {
                    Cfg.set("wsAccent", on)
                    Cfg.flush()
                }
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "visible workspaces"
            token: "wsCount"
            value: Theme.wsCount + ""

            SettingsSlider {
                from: 3
                to: 10
                step: 1
                value: Theme.wsCount
                onMoved: v => Cfg.set("wsCount", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "gap to the clock"
            token: "wsClockGap"
            value: Theme.wsClockGap + " px"

            SettingsSlider {
                from: 0
                to: 28
                step: 1
                value: Theme.wsClockGap
                onMoved: v => Cfg.set("wsClockGap", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "breathing room in the pill"
            token: "wsPad"
            value: Theme.wsPad + " px"

            SettingsSlider {
                from: 0
                to: 24
                step: 1
                value: Theme.wsPad
                onMoved: v => Cfg.set("wsPad", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }

    SettingsGroup {
        visible: !Theme.wsVertical

        SettingsRow {
            label: "dot size"
            token: "wsDot"
            value: Theme.wsDot + " px"

            SettingsSlider {
                from: 2
                to: 10
                step: 1
                value: Theme.wsDot
                onMoved: v => Cfg.set("wsDot", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "active width"
            token: "wsActiveW"
            value: Theme.wsActiveW + " px"

            SettingsSlider {
                from: 4
                to: 40
                step: 1
                value: Theme.wsActiveW
                onMoved: v => Cfg.set("wsActiveW", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "active thickness"
            token: "wsActiveH"
            value: Theme.wsActiveH + " px"

            SettingsSlider {
                from: 2
                to: 14
                step: 1
                value: Theme.wsActiveH
                onMoved: v => Cfg.set("wsActiveH", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "spacing"
            token: "wsGap"
            value: Theme.wsGap + " px"

            SettingsSlider {
                from: 2
                to: 20
                step: 1
                value: Theme.wsGap
                onMoved: v => Cfg.set("wsGap", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }

    SettingsGroup {
        visible: Theme.wsVertical

        SettingsRow {
            label: "bar width"
            token: "wsBarW"
            value: Theme.wsBarW + " px"

            SettingsSlider {
                from: 2
                to: 12
                step: 1
                value: Theme.wsBarW
                onMoved: v => Cfg.set("wsBarW", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "bar height"
            token: "wsBarH"
            value: Theme.wsBarH + " px"

            SettingsSlider {
                from: 3
                to: 22
                step: 1
                value: Theme.wsBarH
                onMoved: v => Cfg.set("wsBarH", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "active bar width"
            token: "wsBarActiveW"
            value: Theme.wsBarActiveW + " px"

            SettingsSlider {
                from: 2
                to: 16
                step: 1
                value: Theme.wsBarActiveW
                onMoved: v => Cfg.set("wsBarActiveW", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "active bar height"
            token: "wsBarActiveH"
            value: Theme.wsBarActiveH + " px"

            SettingsSlider {
                from: 4
                to: 26
                step: 1
                value: Theme.wsBarActiveH
                onMoved: v => Cfg.set("wsBarActiveH", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "spacing"
            token: "wsBarGap"
            value: Theme.wsBarGap + " px"

            SettingsSlider {
                from: 1
                to: 20
                step: 1
                value: Theme.wsBarGap
                onMoved: v => Cfg.set("wsBarGap", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "long jump easing"
            token: "wsSpread"
            value: Math.round(Theme.wsSpread * 100) + "%"

            SettingsSlider {
                from: 0
                to: 1
                step: 0.05
                value: Theme.wsSpread
                onMoved: v => Cfg.set("wsSpread", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "layout change"
            token: "wsSwap"
            value: Theme.wsSwap + " ms"

            SettingsSlider {
                from: 40
                to: 300
                step: 10
                value: Theme.wsSwap
                onMoved: v => Cfg.set("wsSwap", Math.round(v / 10) * 10)
                onCommitted: Cfg.flush()
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "empty workspace"
            token: "wsDotDim"
            value: Math.round(Theme.wsDotDim * 100) + "%"

            SettingsSlider {
                from: 0.05
                to: 1
                step: 0.02
                value: Theme.wsDotDim
                onMoved: v => Cfg.set("wsDotDim", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "workspace with windows"
            token: "wsDotLive"
            value: Math.round(Theme.wsDotLive * 100) + "%"

            SettingsSlider {
                from: 0.05
                to: 1
                step: 0.02
                value: Theme.wsDotLive
                onMoved: v => Cfg.set("wsDotLive", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }
    }
}

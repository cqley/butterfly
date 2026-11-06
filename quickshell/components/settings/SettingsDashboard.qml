import "../core"
import QtQuick

Column {
    id: root

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "show workspaces"
            token: "dashWs"

            SettingsToggle {
                checked: Theme.dashWs
                onToggled: on => {
                    Cfg.set("dashWs", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "show the date"
            token: "dashDate"

            SettingsToggle {
                checked: Theme.dashDate
                onToggled: on => {
                    Cfg.set("dashDate", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "show the weekday"
            token: "dashWeekday"

            SettingsToggle {
                checked: Theme.dashWeekday
                onToggled: on => {
                    Cfg.set("dashWeekday", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "show notifications"
            token: "dashNotes"

            SettingsToggle {
                checked: Theme.dashNotes
                onToggled: on => {
                    Cfg.set("dashNotes", on)
                    Cfg.flush()
                }
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "show wifi"
            token: "dashNet"

            SettingsToggle {
                checked: Theme.dashNet
                onToggled: on => {
                    Cfg.set("dashNet", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "show bluetooth"
            token: "dashBt"

            SettingsToggle {
                checked: Theme.dashBt
                onToggled: on => {
                    Cfg.set("dashBt", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "show battery and volume"
            token: "dashPower"

            SettingsToggle {
                checked: Theme.dashPower
                onToggled: on => {
                    Cfg.set("dashPower", on)
                    Cfg.flush()
                }
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "width"
            token: "dashW"
            value: Theme.dashW + " px"

            SettingsSlider {
                from: Theme.dashMinW
                to: Theme.dashMaxW
                step: 4
                value: Theme.dashW
                onMoved: v => Cfg.set("dashW", Math.round(v / 4) * 4)
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "breathing room at the edges"
            token: "dashPadX"
            value: Theme.dashPadX + " px"

            SettingsSlider {
                from: 12
                to: 48
                step: 1
                value: Theme.dashPadX
                onMoved: v => Cfg.set("dashPadX", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "gap between status icons"
            token: "dashStatusGap"
            value: Theme.dashStatusGap + " px"

            SettingsSlider {
                from: 4
                to: 24
                step: 1
                value: Theme.dashStatusGap
                onMoved: v => Cfg.set("dashStatusGap", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "clock size"
            token: "dashClockPx"
            value: Theme.dashClockPx + " px"

            SettingsSlider {
                from: 14
                to: 34
                step: 1
                value: Theme.dashClockPx
                onMoved: v => Cfg.set("dashClockPx", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }
}

import "../core"
import QtQuick

Column {
    id: root
    readonly property var formats: ["HH:mm", "hh:mm AP"]

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "time format"
            token: "clockFormat"

            SettingsSegmented {
                options: ["24-hour", "12-hour"]
                current: Math.max(0, root.formats.indexOf(Theme.clockFormat))
                onPicked: i => {
                    Cfg.set("clockFormat", root.formats[i])
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "clock size"
            token: "clockPx"
            value: Theme.clockPx + " px"

            SettingsSlider {
                from: 10
                to: 22
                step: 1
                value: Cfg.get("clockPx", 14)
                onMoved: v => Cfg.set("clockPx", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "gap to the side modules"
            token: "clockGap"
            value: Theme.clockGap + " px"

            SettingsSlider {
                from: 0
                to: 16
                step: 1
                value: Theme.clockGap
                onMoved: v => Cfg.set("clockGap", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }

    SettingsSection { text: "week strip" }

    SettingsGroup {
        SettingsRow {
            label: "days shown"
            token: "weekCells"
            value: Theme.weekCells + ""

            SettingsSlider {
                from: 5
                to: 13
                step: 1
                value: Theme.weekCells
                onMoved: v => Cfg.set("weekCells", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "days before today"
            note: "pop-out strip only"
            token: "islandWeekLead"
            value: Theme.islandWeekLead + ""

            SettingsSlider {
                from: 0
                to: 5
                step: 1
                value: Theme.islandWeekLead
                onMoved: v => Cfg.set("islandWeekLead", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }

    SettingsSection { text: "calendar" }

    SettingsGroup {
        SettingsRow {
            label: "today highlight"
            token: "todayFill"
            value: Math.round(Theme.todayFill * 100) + "%"

            SettingsSlider {
                from: 0
                to: 0.5
                step: 0.01
                value: Theme.todayFill
                onMoved: v => Cfg.set("todayFill", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "other-month days"
            token: "outMonth"
            value: Math.round(Theme.outMonth * 100) + "%"

            SettingsSlider {
                from: 0.05
                to: 0.8
                step: 0.01
                value: Theme.outMonth
                onMoved: v => Cfg.set("outMonth", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }
    }
}

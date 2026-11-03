import "../core"
import QtQuick

Column {
    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "popup width"
            token: "noteW"
            value: Theme.noteW + " px"

            SettingsSlider {
                from: 200
                to: 400
                step: 2
                value: Theme.noteW
                onMoved: v => Cfg.set("noteW", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "body lines"
            token: "noteBodyLines"
            value: Theme.noteBodyLines + ""

            SettingsSlider {
                from: 0
                to: 4
                step: 1
                value: Theme.noteBodyLines
                onMoved: v => Cfg.set("noteBodyLines", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "time on screen"
            token: "dwell"
            value: (Theme.dwell / 1000).toFixed(1) + " s"

            SettingsSlider {
                from: 1000
                to: 15000
                step: 500
                value: Theme.dwell
                onMoved: v => Cfg.set("dwell", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "time on screen (critical)"
            token: "dwellCritical"
            value: (Theme.dwellCritical / 1000).toFixed(1) + " s"

            SettingsSlider {
                from: 2000
                to: 30000
                step: 1000
                value: Theme.dwellCritical
                onMoved: v => Cfg.set("dwellCritical", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "rows shown"
            token: "centerRows"
            value: Theme.centerRows + ""

            SettingsSlider {
                from: 1
                to: 8
                step: 1
                value: Theme.centerRows
                onMoved: v => Cfg.set("centerRows", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "history kept"
            token: "notificationHistoryMax"
            value: Theme.notificationHistoryMax + ""

            SettingsSlider {
                from: 5
                to: 200
                step: 5
                value: Theme.notificationHistoryMax
                onMoved: v => Cfg.set("notificationHistoryMax", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }
}

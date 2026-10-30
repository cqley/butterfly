import "../core"
import QtQuick

Column {
    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "width"
            token: "launchW"
            value: Theme.launchW + " px"

            SettingsSlider {
                from: 240
                to: 520
                step: 2
                value: Theme.launchW
                onMoved: v => Cfg.set("launchW", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "rows shown"
            token: "rows"
            value: Theme.rows + ""

            SettingsSlider {
                from: 3
                to: 10
                step: 1
                value: Theme.rows
                onMoved: v => Cfg.set("rows", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "row height"
            token: "rowH"
            value: Theme.rowH + " px"

            SettingsSlider {
                from: 28
                to: 56
                step: 1
                value: Theme.rowH
                onMoved: v => Cfg.set("rowH", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "icon size"
            token: "launchIconSize"
            value: Theme.launchIconSize + " px"

            SettingsSlider {
                from: 12
                to: 32
                step: 1
                value: Theme.launchIconSize
                onMoved: v => Cfg.set("launchIconSize", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }
}

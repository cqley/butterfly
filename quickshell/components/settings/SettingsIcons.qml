import "../core"
import QtQuick

Column {
    id: root

    readonly property var sides: ["left", "right"]

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "battery"
            token: "batPlace"

            SettingsSegmented {
                options: ["left", "right"]
                current: Math.max(0, root.sides.indexOf(Theme.batPlace))
                onPicked: i => {
                    Cfg.set("batPlace", root.sides[i])
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "microphone"
            token: "micPlace"

            SettingsSegmented {
                options: ["left", "right"]
                current: Math.max(0, root.sides.indexOf(Theme.micPlace))
                onPicked: i => {
                    Cfg.set("micPlace", root.sides[i])
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "recording dot"
            token: "recPlace"

            SettingsSegmented {
                options: ["left", "right"]
                current: Math.max(0, root.sides.indexOf(Theme.recPlace))
                onPicked: i => {
                    Cfg.set("recPlace", root.sides[i])
                    Cfg.flush()
                }
            }
        }
    }
}

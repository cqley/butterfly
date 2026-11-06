import "../core"
import QtQuick

Column {
    id: root

    readonly property var sides: ["left", "right"]

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "wifi"
            token: "wifiOn"

            SettingsToggle {
                checked: Theme.wifiOn
                onToggled: on => {
                    Cfg.set("wifiOn", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "wifi side"
            token: "wifiPlace"

            SettingsSegmented {
                options: root.sides
                current: Math.max(0, root.sides.indexOf(Theme.wifiPlace))
                onPicked: i => {
                    Cfg.set("wifiPlace", root.sides[i])
                    Cfg.flush()
                }
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "battery side"
            token: "batPlace"

            SettingsSegmented {
                options: root.sides
                current: Math.max(0, root.sides.indexOf(Theme.batPlace))
                onPicked: i => {
                    Cfg.set("batPlace", root.sides[i])
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "charge ring"
            token: "batRingEnabled"

            SettingsToggle {
                checked: Theme.batRingEnabled
                onToggled: on => {
                    Cfg.set("batRingEnabled", on)
                    Cfg.flush()
                }
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "microphone"
            token: "micPlace"

            SettingsSegmented {
                options: root.sides
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
                options: root.sides
                current: Math.max(0, root.sides.indexOf(Theme.recPlace))
                onPicked: i => {
                    Cfg.set("recPlace", root.sides[i])
                    Cfg.flush()
                }
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "visualizer on hover"
            token: "visPeek"

            SettingsToggle {
                checked: Theme.visPeek
                onToggled: on => {
                    Cfg.set("visPeek", on)
                    Cfg.flush()
                }
            }
        }
    }
}

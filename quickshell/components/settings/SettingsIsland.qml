import "../core"
import QtQuick

Column {
    id: root
    readonly property bool popout: Theme.islandMode === "popout"
    readonly property string popNote: root.popout ? "" : "pop-out mode only — the island is in classic mode"

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "pill width"
            token: "w"
            value: Theme.w + " px"

            SettingsSlider {
                from: 40
                to: 160
                step: 1
                value: Theme.w
                onMoved: v => Cfg.set("w", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "pill height"
            token: "h"
            value: Theme.h + " px"

            SettingsSlider {
                from: 20
                to: 48
                step: 1
                value: Theme.h
                onMoved: v => Cfg.set("h", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "gap from the screen edge"
            token: "gap"
            value: Theme.gap + " px"

            SettingsSlider {
                from: 0
                to: 24
                step: 1
                value: Theme.gap
                onMoved: v => Cfg.set("gap", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "panel side padding"
            token: "pad"
            value: Theme.pad + " px"

            SettingsSlider {
                from: 4
                to: 40
                step: 1
                value: Theme.pad
                onMoved: v => Cfg.set("pad", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "pop-out width"
            note: root.popNote
            token: "islandPopW"
            value: Theme.islandPopW + " px"

            SettingsSlider {
                from: 0
                to: 40
                step: 1
                value: Theme.islandPopW
                onMoved: v => Cfg.set("islandPopW", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "pop-out height"
            note: root.popNote
            token: "islandPopH"
            value: Theme.islandPopH + " px"

            SettingsSlider {
                from: 0
                to: 24
                step: 1
                value: Theme.islandPopH
                onMoved: v => Cfg.set("islandPopH", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "pop-out drop"
            note: root.popNote
            token: "islandPopDrop"
            value: Theme.islandPopDrop + " px"

            SettingsSlider {
                from: 0
                to: 20
                step: 1
                value: Theme.islandPopDrop
                onMoved: v => Cfg.set("islandPopDrop", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "hover target growth"
            note: root.popNote
            token: "islandHitGrow"
            value: Theme.islandHitGrow + " px"

            SettingsSlider {
                from: 0
                to: 20
                step: 1
                value: Theme.islandHitGrow
                onMoved: v => Cfg.set("islandHitGrow", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }
}

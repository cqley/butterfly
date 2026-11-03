import "../core"
import QtQuick

Column {
    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "card width"
            token: "mediaPillW"
            value: Theme.mediaPillW + " px"

            SettingsSlider {
                from: 240
                to: 440
                step: 2
                value: Theme.mediaPillW
                onMoved: v => Cfg.set("mediaPillW", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "album art size"
            token: "artS"
            value: Theme.artS + " px"

            SettingsSlider {
                from: 56
                to: 120
                step: 2
                value: Theme.artS
                onMoved: v => Cfg.set("artS", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "bars"
            token: "visBars"
            value: Theme.visBars + ""

            SettingsSlider {
                from: 3
                to: 16
                step: 1
                value: Theme.visBars
                onMoved: v => Cfg.set("visBars", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "bar width"
            token: "visBarW"
            value: Theme.visBarW + " px"

            SettingsSlider {
                from: 1
                to: 8
                step: 1
                value: Theme.visBarW
                onMoved: v => Cfg.set("visBarW", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "peak height"
            token: "visMaxH"
            value: Theme.visMaxH + " px"

            SettingsSlider {
                from: 6
                to: 32
                step: 1
                value: Theme.visMaxH
                onMoved: v => Cfg.set("visMaxH", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "frame rate"
            token: "visFps"
            value: Theme.visFps + " fps"

            SettingsSlider {
                from: 24
                to: 144
                step: 1
                value: Theme.visFps
                onMoved: v => Cfg.set("visFps", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }
}

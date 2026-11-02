import "../core"
import "../wallpaper"
import QtQuick

Column {
    id: root
    readonly property var swatches: [Theme.accentAuto, "#e5534b", "#f2994a", "#f2c94c", "#6fcf97", "#56ccd0", "#5b8def", "#bb6bd9"]
    readonly property string hex: Theme.isHex(Theme.accentOverride) ? Theme.accentOverride.toLowerCase() : ""
    readonly property int swatch: root.hex === "" ? 0 : root.swatches.findIndex((c, i) => i > 0 && String(c).toLowerCase() === root.hex)

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "accent colour"
            token: "accent"
            value: root.hex === "" ? "auto" : root.hex

            SettingsColorDots {
                colors: root.swatches
                autoIndex: 0
                current: root.swatch
                onPicked: i => {
                    if (i === 0)
                        Cfg.clear("accent")
                    else
                        Cfg.set("accent", String(root.swatches[i]).toLowerCase())
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "custom colour"
            note: "six-digit hex, empty follows the wallpaper"

            SettingsField {
                placeholder: "#rrggbb"
                limit: 7
                text: root.hex
                onCommitted: t => {
                    const v = t.trim().toLowerCase()
                    if (v === "")
                        Cfg.clear("accent")
                    else if (Theme.isHex(v))
                        Cfg.set("accent", v)
                    Cfg.flush()
                }
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "choose a wallpaper"
            note: "every other colour derives from it; there is no theme list"
            showArrow: true
            onActivated: Wallpaper.open = true
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "corner rounding"
            token: "radius"
            value: Theme.radius + " px"

            SettingsSlider {
                from: 0
                to: 40
                step: 1
                value: Theme.radius
                onMoved: v => Cfg.set("radius", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "font size"
            token: "fontScale"
            value: Math.round(Theme.fontScale * 100) + "%"

            SettingsSlider {
                from: 0.8
                to: 1.4
                step: 0.05
                value: Theme.fontScale
                onMoved: v => Cfg.set("fontScale", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "settings window darkness"
            token: "settingsDarken"
            value: Math.round(Theme.settingsDarken * 100) + "%"

            SettingsSlider {
                from: 0
                to: 1
                step: 0.05
                value: Theme.settingsDarken
                onMoved: v => Cfg.set("settingsDarken", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }
    }
}

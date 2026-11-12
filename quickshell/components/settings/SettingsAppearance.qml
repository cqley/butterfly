import "../core"
import QtQuick

Column {
    id: root
    readonly property string primaryHex: Theme.isHex(Theme.primaryOverride) ? Theme.primaryOverride.toLowerCase() : ""
    readonly property string accentHex: Theme.isHex(Theme.accentOverride) ? Theme.accentOverride.toLowerCase() : ""

    function swatchOf(list, hex) {
        return hex === "" ? 0 : list.findIndex((c, i) => i > 0 && String(c).toLowerCase() === hex)
    }

    function store(key, value) {
        if (value === "")
            Cfg.clear(key)
        else
            Cfg.set(key, value)
        Cfg.flush()
    }

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "primary colour"
            token: "primary"
            value: root.primaryHex === "" ? "auto" : root.primaryHex

            SettingsColorDots {
                colors: Theme.primarySwatches
                autoIndex: 0
                current: root.swatchOf(Theme.primarySwatches, root.primaryHex)
                onPicked: i => root.store("primary", i === 0 ? "" : String(Theme.primarySwatches[i]).toLowerCase())
            }
        }

        SettingsRow {
            label: "custom colour"

            SettingsField {
                placeholder: "#rrggbb"
                limit: 7
                text: root.primaryHex
                onCommitted: t => {
                    const v = t.trim().toLowerCase()
                    if (v === "" || Theme.isHex(v))
                        root.store("primary", v)
                }
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "accent colour"
            token: "accent"
            value: root.accentHex === "" ? "auto" : root.accentHex

            SettingsColorDots {
                colors: Theme.accentSwatches
                autoIndex: 0
                current: root.swatchOf(Theme.accentSwatches, root.accentHex)
                onPicked: i => root.store("accent", i === 0 ? "" : String(Theme.accentSwatches[i]).toLowerCase())
            }
        }

        SettingsRow {
            label: "custom colour"

            SettingsField {
                placeholder: "#rrggbb"
                limit: 7
                text: root.accentHex
                onCommitted: t => {
                    const v = t.trim().toLowerCase()
                    if (v === "" || Theme.isHex(v))
                        root.store("accent", v)
                }
            }
        }

        SettingsRow {
            label: "white knobs"
            token: "whiteKnobs"

            SettingsToggle {
                checked: Theme.whiteKnobs
                onToggled: on => {
                    Cfg.set("whiteKnobs", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "white clock"
            token: "whiteClock"

            SettingsToggle {
                checked: Theme.whiteClock
                onToggled: on => {
                    Cfg.set("whiteClock", on)
                    Cfg.flush()
                }
            }
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

    }

    SettingsGroup {
        SettingsRow {
            label: "drop shadow"
            token: "shadowOn"

            SettingsToggle {
                checked: Theme.shadowOn
                onToggled: on => {
                    Cfg.set("shadowOn", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "shadow strength"
            token: "shadowOpacity"
            value: Math.round(Theme.shadowOpacity * 100) + "%"

            SettingsSlider {
                from: 0
                to: 1
                step: 0.02
                value: Theme.shadowOpacity
                onMoved: v => Cfg.set("shadowOpacity", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "shadow blur"
            token: "shadowBlur"
            value: Theme.shadowBlur + " px"

            SettingsSlider {
                from: 8
                to: 60
                step: 1
                value: Theme.shadowBlur
                onMoved: v => Cfg.set("shadowBlur", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "shadow spread"
            token: "shadowSpread"
            value: Theme.shadowSpread + " px"

            SettingsSlider {
                from: 0
                to: 20
                step: 1
                value: Theme.shadowSpread
                onMoved: v => Cfg.set("shadowSpread", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "shadow lift"
            token: "shadowOffsetY"
            value: Theme.shadowOffsetY + " px"

            SettingsSlider {
                from: 0
                to: 12
                step: 1
                value: Theme.shadowOffsetY
                onMoved: v => Cfg.set("shadowOffsetY", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }

        SettingsRow {
            label: "edge shadow"
            token: "shadowContact"
            value: Math.round(Theme.shadowContact * 100) + "%"

            SettingsSlider {
                from: 0
                to: 1
                step: 0.05
                value: Theme.shadowContact
                onMoved: v => Cfg.set("shadowContact", Math.round(v * 100) / 100)
                onCommitted: Cfg.flush()
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "wallpaper folder"
            token: "wallPath"

            SettingsField {
                width: Theme.settingsPathW
                placeholder: "~/pictures/wallpaper"
                text: Theme.wallPathShort
                onCommitted: t => root.store("wallPath", t.trim())
            }
        }
    }
}

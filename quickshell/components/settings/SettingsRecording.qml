import "../core"
import "../recording"
import QtQuick

Column {
    id: root

    function store(key, value) {
        const v = value.trim()
        if (v === "")
            Cfg.clear(key)
        else
            Cfg.set(key, v)
        Cfg.flush()
    }

    width: parent ? parent.width : 0
    spacing: Theme.settingsGroupGap

    SettingsGroup {
        SettingsRow {
            label: "desktop audio"
            token: "recordDesktopAudio"
            off: Record.canDesktopAudio ? "" : "unsupported"

            SettingsToggle {
                checked: Theme.recordDesktopAudio
                onToggled: on => {
                    Cfg.set("recordDesktopAudio", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "microphone"
            token: "recordMic"
            off: Record.canMic ? "" : "unsupported"

            SettingsToggle {
                checked: Theme.recordMic
                onToggled: on => {
                    Cfg.set("recordMic", on)
                    Cfg.flush()
                }
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "show cursor"
            token: "recordCursor"
            off: Record.canCursor ? "" : "unsupported"

            SettingsToggle {
                checked: Theme.recordCursor
                onToggled: on => {
                    Cfg.set("recordCursor", on)
                    Cfg.flush()
                }
            }
        }

        SettingsRow {
            label: "frame rate"
            token: "recordFps"
            value: Theme.recordFps + " fps"
            off: Record.canFps ? "" : "unsupported"

            SettingsSlider {
                from: 24
                to: 144
                step: 1
                value: Theme.recordFps
                onMoved: v => Cfg.set("recordFps", Math.round(v))
                onCommitted: Cfg.flush()
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            label: "recorder"
            value: Record.backendLabel
        }

        SettingsRow {
            label: "folder"
            token: "recordDir"

            SettingsField {
                width: Theme.settingsPathW
                placeholder: "~/videos/records"
                text: Theme.recordDirShort
                onCommitted: t => root.store("recordDir", t)
            }
        }
    }
}

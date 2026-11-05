import "../core"
import "../recording"
import QtQuick

Column {
    id: root

    function note(ok) {
        return ok ? "" : "unsupported"
    }

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
            value: root.note(Record.canDesktopAudio)
            enabled: Record.canDesktopAudio
            opacity: enabled ? 1 : Theme.dimMid

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
            value: root.note(Record.canMic)
            enabled: Record.canMic
            opacity: enabled ? 1 : Theme.dimMid

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
            value: root.note(Record.canCursor)
            enabled: Record.canCursor
            opacity: enabled ? 1 : Theme.dimMid

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
            value: Record.canFps ? Theme.recordFps + " fps" : root.note(false)
            enabled: Record.canFps
            opacity: enabled ? 1 : Theme.dimMid

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

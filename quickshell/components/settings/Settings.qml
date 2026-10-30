pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false
    property string screenName: ""
    property int selected: 0
    property bool keyNav: false

    readonly property var categories: [
        {
            id: "island",
            label: "island",
            icon: Theme.settingsIslandPath,
            page: "SettingsIsland.qml",
            title: "island",
            subtitle: "the pill itself — resting size, corner shape and how far it pops out under the pointer."
        },
        {
            id: "appearance",
            label: "appearance",
            icon: Theme.settingsStylePath,
            page: "SettingsAppearance.qml",
            title: "appearance",
            subtitle: "accent colour, wallpaper, type scale and the drop shadow under every surface."
        },
        {
            id: "motion",
            label: "motion",
            icon: Theme.settingsMotionPath,
            page: "SettingsMotion.qml",
            title: "motion",
            subtitle: "spring or classic easing, how fast everything moves, and the island interaction model."
        },
        {
            id: "clock",
            label: "clock & calendar",
            icon: Theme.settingsClockPath,
            page: "SettingsClock.qml",
            title: "clock & calendar",
            subtitle: "time format and size, the week strip, and how the calendar marks today."
        },
        {
            id: "media",
            label: "media",
            icon: Theme.settingsMediaPath,
            page: "SettingsMedia.qml",
            title: "media",
            subtitle: "the now-playing card and the idle-row visualizer."
        },
        {
            id: "mixer",
            label: "mixer",
            icon: Theme.settingsSlidersPath,
            page: "SettingsMixer.qml",
            title: "mixer",
            subtitle: "volume and brightness tracks — what each one shows and how far a step moves it."
        },
        {
            id: "launcher",
            label: "launcher",
            icon: Theme.settingsLauncherPath,
            page: "SettingsLauncher.qml",
            title: "launcher",
            subtitle: "the app list: how wide, how many rows and how big the icons are."
        },
        {
            id: "notifications",
            label: "notifications",
            icon: Theme.settingsBellPath,
            page: "SettingsNotifications.qml",
            title: "notifications",
            subtitle: "how long a popup stays, how much it shows, and how much history is kept."
        },
        {
            id: "system",
            label: "system",
            icon: Theme.settingsSystemPath,
            page: "SettingsSystem.qml",
            title: "system",
            subtitle: "which monitor the shell lives on, the battery indicator, and resetting everything."
        }
    ]

    readonly property int n: categories.length

    function move(d) {
        if (n <= 0)
            return
        selected = ((selected + d) % n + n) % n
    }

    onOpenChanged: {
        if (open) {
            keyNav = false
            Modal.claim("settings")
            screenName = Compositor.focusedScreenName()
        }
    }

    Component.onCompleted: Modal.register("settings", root)

    Connections {
        target: Quickshell

        function onScreensChanged() {
            if (root.screenName !== "" && !Compositor.hasScreen(root.screenName)) {
                root.open = false
                root.screenName = ""
            }
        }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
        function status(): string { return root.open ? "open " + root.screenName : "closed" }
    }
}

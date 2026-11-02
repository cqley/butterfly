pragma Singleton
import "../core"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false
    readonly property string screenName: Theme.shellScreen
    property int selected: 0
    property bool keyNav: false

    readonly property var categories: [
        {
            id: "island",
            label: "island",
            icon: Theme.settingsIslandPath,
            page: "SettingsIsland.qml",
            title: "island"
        },
        {
            id: "appearance",
            label: "appearance",
            icon: Theme.settingsStylePath,
            page: "SettingsAppearance.qml",
            title: "appearance"
        },
        {
            id: "motion",
            label: "motion",
            icon: Theme.settingsMotionPath,
            page: "SettingsMotion.qml",
            title: "motion"
        },
        {
            id: "clock",
            label: "clock & calendar",
            icon: Theme.settingsClockPath,
            page: "SettingsClock.qml",
            title: "clock & calendar"
        },
        {
            id: "media",
            label: "media",
            icon: Theme.settingsMediaPath,
            page: "SettingsMedia.qml",
            title: "media"
        },
        {
            id: "mixer",
            label: "mixer",
            icon: Theme.settingsSlidersPath,
            page: "SettingsMixer.qml",
            title: "mixer"
        },
        {
            id: "launcher",
            label: "launcher",
            icon: Theme.settingsLauncherPath,
            page: "SettingsLauncher.qml",
            title: "launcher"
        },
        {
            id: "notifications",
            label: "notifications",
            icon: Theme.settingsBellPath,
            page: "SettingsNotifications.qml",
            title: "notifications"
        },
        {
            id: "system",
            label: "system",
            icon: Theme.settingsSystemPath,
            page: "SettingsSystem.qml",
            title: "system"
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
        }
    }

    Component.onCompleted: Modal.register("settings", root)

    IpcHandler {
        target: "settings"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
        function status(): string { return root.open ? "open " + root.screenName : "closed" }
    }
}

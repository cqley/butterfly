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
            page: "SettingsIsland.qml"
        },
        {
            id: "dashboard",
            label: "dashboard",
            icon: Theme.settingsDashboardPath,
            page: "SettingsDashboard.qml"
        },
        {
            id: "appearance",
            label: "appearance",
            icon: Theme.settingsStylePath,
            page: "SettingsAppearance.qml"
        },
        {
            id: "motion",
            label: "motion",
            icon: Theme.settingsMotionPath,
            page: "SettingsMotion.qml"
        },
        {
            id: "workspaces",
            label: "workspaces",
            icon: Theme.settingsWorkspacesPath,
            page: "SettingsWorkspaces.qml"
        },
        {
            id: "icons",
            label: "icons",
            icon: Theme.settingsIconsPath,
            page: "SettingsIcons.qml"
        },
        {
            id: "clock",
            label: "clock & calendar",
            icon: Theme.settingsClockPath,
            page: "SettingsClock.qml"
        },
        {
            id: "media",
            label: "media",
            icon: Theme.settingsMediaPath,
            page: "SettingsMedia.qml"
        },
        {
            id: "mixer",
            label: "mixer",
            icon: Theme.settingsSlidersPath,
            page: "SettingsMixer.qml"
        },
        {
            id: "launcher",
            label: "launcher",
            icon: Theme.settingsLauncherPath,
            page: "SettingsLauncher.qml"
        },
        {
            id: "notifications",
            label: "notifications",
            icon: Theme.settingsBellPath,
            page: "SettingsNotifications.qml"
        },
        {
            id: "recording",
            label: "recording",
            icon: Theme.settingsRecordPath,
            page: "SettingsRecording.qml"
        },
        {
            id: "system",
            label: "system",
            icon: Theme.settingsSystemPath,
            page: "SettingsSystem.qml"
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

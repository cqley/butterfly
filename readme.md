## ipc

| target | actions |
| --- | --- |
| `launcher` | `toggle` |
| `power` | `toggle` |
| `wallpaper` | `toggle` |
| `polkit` | `status` |
| `record` | `toggle` `stop` `status` |
| `screenshot` | `toggle` `region` `window` `monitor` `active` `cancel` `status` |
| `network` | `toggle` `power` `indicator` `status` |
| `bluetooth` | `toggle` `power` `status` |
| `mixer` | `toggle` `status` |
| `brightness` | `toggle` `status` (`toggle` opens the mixer) |
| `audio` | `toggle` `status` (`toggle` opens the mixer) |
| `mic` | `toggle` `status` |
| `battery` | `toggle` `ringToggle` `status` |
| `visualizer` | `toggle` `status` |
| `notifications` | `toggle` `clear` `status` |
| `dnd` | `toggle` `status` |
| `settings` | `toggle` `open` `close` `status` |
| `island` | `dash` `week` `calendar` `media` `status` |
| `dashboard` | `toggle` `part <name>` `width <px>` `status` |
| `tray` | `toggle` `status` |
| `workspaces` | `toggle` `place <left\|right\|only>` `style <dots\|bars>` `status` |
| `modal` | `dismiss` `status` |
| `bar` | `toggle` `status` |

```
quickshell ipc call <target> <action>
```

## dependencies

| for | needs |
| --- | --- |
| shell | `quickshell`, `hyprland` `sway` `niri`, `Inter` (font) |
| network | `nmcli` |
| brightness | `brightnessctl`, `ddcutil` (external monitors) |
| recording | `gpu-screen-recorder`, `wf-recorder` or `wl-screenrec` |
| screenshot | `grim` + `wl-copy` |
| colors | `magick`, `gawk`, `awww` |
| lock | `hyprlock` `swaylock` (optional) |
| visualizer | `cava` (optional) fallback if absent|

## install

```
curl -s https://raw.githubusercontent.com/cqley/butterfly/main/install.sh | bash
```

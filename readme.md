## ipc

| target | actions |
| --- | --- |
| `launcher` | `toggle` |
| `power` | `toggle` |
| `wallpaper` | `toggle` |
| `polkit` | `status` |
| `record` | `toggle` `stop` `status` |
| `screenshot` | `toggle` `region` `window` `active` `cancel` `status` |
| `network` | `toggle` `power` `status` |
| `bluetooth` | `toggle` `power` `status` |
| `brightness` | `toggle` `status` |
| `audio` | `toggle` `status` |
| `mic` | `toggle` `status` |
| `battery` | `toggle` `status` |
| `visualizer` | `toggle` `status` |
| `notifications` | `toggle` `clear` `status` |
| `dnd` | `toggle` `status` |

```
quickshell ipc call <target> <action>
```

## dependencies

| for | needs |
| --- | --- |
| shell | `quickshell`, `hyprland`, `Inter` (font) |
| network | `nmcli` |
| brightness | `brightnessctl`, `ddcutil` (external monitors) |
| recording | `gpu-screen-recorder`, `wf-recorder` or `wl-screenrec` |
| screenshot | `hyprshot` (window/active), `grim` + `wl-copy` (region, per-monitor output, custom picker) |
| colors | `magick`, `gawk`, `awww` |
| lock | `hyprlock` |

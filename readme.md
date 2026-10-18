# butterfly

## ipc

```
quickshell ipc call <target> <action>
```

| target | actions |
| --- | --- |
| `launcher` | `toggle` |
| `power` | `toggle` |
| `wallpaper` | `toggle` |
| `polkit` | `status` |
| `record` | `toggle` `stop` `status` |
| `network` | `toggle` `power` `status` |
| `bluetooth` | `toggle` `power` `status` |
| `brightness` | `toggle` `status` |
| `audio` | `toggle` `status` |
| `mic` | `toggle` `status` |
| `battery` | `toggle` `status` |
| `visualizer` | `toggle` `status` |

## dependencies

| | |
| --- | --- |
| shell | `quickshell`, `hyprland` |
| network | `nmcli` |
| brightness | `brightnessctl`, `ddcutil` (external monitors) |
| recording | `gpu-screen-recorder`, `wf-recorder` or `wl-screenrec` |
| colors | `magick`, `gawk`, `awww` |
| lock | `hyprlock` |

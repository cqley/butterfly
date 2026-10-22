## ipc

| target | actions |
| --- | --- |
| `launcher` | `toggle` |
| `power` | `toggle` |
| `wallpaper` | `toggle` |
| `polkit` | `status` |
| `record` | `toggle` `stop` `status` |
| `screenshot` | `toggle` `region` `window` `monitor` `active` `cancel` `status` |
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
| screenshot | `grim` + `wl-copy` (region, window, monitor, active, all via custom pickers) |
| colors | `magick`, `gawk`, `awww` |
| lock | `hyprlock` |

## install

```
curl -s https://raw.githubusercontent.com/cqley/butterfly/main/install.sh | bash
```

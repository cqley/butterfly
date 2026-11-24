## ipc

| target | actions |
| --- | --- |
| `launcher` | `toggle` |
| `power` | `toggle` |
| `lock` | `toggle` `status` |
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
| `shell` | `toggle` `status` |
| `notch` | `toggle` `status` |

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
| gtk colors | `adw-gtk3` |
| qt colors | `qt6ct` (qt5ct for qt5 apps) |
| visualizer | `cava` (optional) fallback if absent|

## colors

keep colors:

| kind | names |
| --- | --- |
| shells | `bash` `zsh` `fish` |
| terminals | `kitty` `foot` `alacritty` `ghostty` |
| toolkits | `gtk` `qt` |

kitty: add `include ~/.colors/kitty.conf` to `kitty.conf`.

```
~/.config/quickshell/components/core/scripts/colors.sh --hook fish
```

## install

```
curl -s https://raw.githubusercontent.com/cqley/butterfly/main/install.sh | bash
```

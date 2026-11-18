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
| lock | `hyprlock` `swaylock` (optional) |
| visualizer | `cava` (optional) fallback if absent|

## colors

picking a wallpaper derives a palette from it and writes themes for other apps to `~/.colors`. open terminals update right away. to keep the colors in new terminals, run once per shell or terminal you use:

```
~/.config/quickshell/components/core/scripts/colors.sh --hook fish
```

| kind | names |
| --- | --- |
| shells | `bash` `zsh` `ksh` `fish` `nu` |
| terminals | `foot` `alacritty` `ghostty` |

kitty: add `include ~/.colors/kitty.conf` to `kitty.conf`. qt apps follow the palette through `~/.config/kdeglobals` when `QT_QPA_PLATFORMTHEME=kde`. if a config is read-only (home-manager), `--hook` prints the line to add yourself.

## install

```
curl -s https://raw.githubusercontent.com/cqley/butterfly/main/install.sh | bash
```

#!/usr/bin/env bash

set -euo pipefail

readonly PROG=colors
out=

: "${COLORS_DIR:=$HOME/.colors}"
: "${COLORS_MAIN_OUTPUT:=HDMI-A-1}"
: "${COLORS_CLEAR_OUTPUTS:=DP-1}"
: "${COLORS_TRANSITION:=grow}"
: "${COLORS_TRANSITION_DURATION:=1.5}"
: "${COLORS_TRANSITION_FPS:=120}"
readonly BASE=8
: "${COLORS_BRIGHTEN_PCT:=140}"
: "${COLORS_SAMPLE:=50}"
: "${COLORS_MIN_CONTRAST:=4.5}"
: "${COLORS_MIN_CHROMA:=0.15}"
: "${COLORS_DIM_CONTRAST:=3}"
: "${COLORS_ANSI_SAT:=0.6}"
: "${COLORS_ANSI_TINT:=750}"
: "${COLORS_RED:=#E5534B}"
: "${COLORS_YELLOW:=#FFCC00}"
: "${COLORS_GREEN:=#34C759}"

die() {
    printf '%s: %s\n' "$PROG" "$*" >&2
    exit 1
}

warn() {
    printf '%s: %s\n' "$PROG" "$*" >&2
}

usage() {
    cat <<EOF
usage: $PROG [options] <image>
       $PROG --hook NAME

derives a 16-color palette from <image>, sets it as the wallpaper, and renders
the palette into templates under \$COLORS_DIR.

options:
  -n, --no-wallpaper   only generate templates, do not touch the wallpaper
  -A, --no-apply       only write templates: no escape sequences, compositor
                       borders, kdeglobals, or reloading tmux, kitty, ghostty,
                       btop, zathura and qt5ct/qt6ct
  -q, --quiet          do not print the palette swatches
  -o, --out DIR        write templates to DIR instead of \$COLORS_DIR
  -m, --monitor NAME   wallpaper output to prefer (default: \$COLORS_MAIN_OUTPUT)
  -H, --hook NAME      make NAME load the palette on start: a shell (bash, zsh,
                       fish), a terminal (kitty, foot, alacritty, ghostty), an
                       app (tmux, zathura, btop) or a toolkit (gtk, qt);
                       repeatable, can be given without <image>
  -h, --help           show this help

environment:
  COLORS_DIR=$COLORS_DIR
  COLORS_MAIN_OUTPUT=$COLORS_MAIN_OUTPUT
  COLORS_CLEAR_OUTPUTS=$COLORS_CLEAR_OUTPUTS
  COLORS_TRANSITION=$COLORS_TRANSITION
  COLORS_TRANSITION_DURATION=$COLORS_TRANSITION_DURATION
  COLORS_TRANSITION_FPS=$COLORS_TRANSITION_FPS
  COLORS_BRIGHTEN_PCT=$COLORS_BRIGHTEN_PCT
  COLORS_SAMPLE=$COLORS_SAMPLE
  COLORS_MIN_CONTRAST=$COLORS_MIN_CONTRAST
  COLORS_MIN_CHROMA=$COLORS_MIN_CHROMA
  COLORS_DIM_CONTRAST=$COLORS_DIM_CONTRAST
  COLORS_ANSI_SAT=$COLORS_ANSI_SAT
  COLORS_ANSI_TINT=$COLORS_ANSI_TINT
  COLORS_RED=$COLORS_RED
  COLORS_YELLOW=$COLORS_YELLOW
  COLORS_GREEN=$COLORS_GREEN

requires: bash, magick, gawk, coreutils (awww to set the wallpaper)
templates:
  colors colors.txt colors.sh colors.fish colors.json sequences
  kitty.conf tmux.conf colors.lua colors.css gtk.css btop.theme
  zathurarc Xresources kdeglobals shell.sh shell.fish
  foot.ini alacritty.toml ghostty qtct.conf
EOF
}

need() {
    local miss=() b
    for b in "$@"; do
        command -v "$b" >/dev/null 2>&1 || miss+=("$b")
    done
    ((${#miss[@]} == 0)) || die "missing required command: ${miss[*]}"
}

sync_niri_border_color() {
    local accent=$1 cfg="$HOME/.config/niri/config.kdl" sock
    [[ -f $cfg ]] || return 0
    sed -i -E "s/^([[:space:]]*active-color )\"#[0-9A-Fa-f]{6,8}\"/\1\"${accent}FF\"/" "$cfg"
    command -v niri >/dev/null 2>&1 || return 0
    sock=$(find "/run/user/$(id -u)" -maxdepth 1 -name 'niri.wayland-*.sock' 2>/dev/null | head -n1)
    [[ -n $sock ]] && NIRI_SOCKET="$sock" niri msg action load-config-file >/dev/null 2>&1 || true
}

sync_sway_border_color() {
    local accent=$1 cfg="$HOME/.config/sway/config" sock hex='#[0-9A-Fa-f]{6,8}' sp='[[:space:]]'
    [[ -f $cfg ]] || return 0
    sed -i -E \
        -e "s/^(${sp}*client\.focused${sp}+)${hex}/\1${accent}/" \
        -e "s/^(${sp}*client\.focused(${sp}+${hex}){3}${sp}+)${hex}/\1${accent}/" \
        -e "s/^(${sp}*client\.focused(${sp}+${hex}){4}${sp}+)${hex}/\1${accent}/" \
        "$cfg"
    command -v swaymsg >/dev/null 2>&1 || return 0
    sock=${SWAYSOCK:-$(find "/run/user/$(id -u)" -maxdepth 1 -name 'sway-ipc.*.sock' 2>/dev/null | head -n1)}
    [[ -n $sock ]] && SWAYSOCK="$sock" swaymsg reload >/dev/null 2>&1 || true
}

hex_channel() {
    local h=${1#\#}
    printf '%d' "$((16#${h:$2:2}))"
}

hex_rgb() {
    local h=${1#\#}
    printf '%d %d %d' "$((16#${h:0:2}))" "$((16#${h:2:2}))" "$((16#${h:4:2}))"
}

hex_bare() {
    printf '%s' "${1#\#}"
}

brighten() {
    local r g b
    r=$(( $(hex_channel "$1" 0) * $2 / 100 ))
    g=$(( $(hex_channel "$1" 2) * $2 / 100 ))
    b=$(( $(hex_channel "$1" 4) * $2 / 100 ))
    if ((r > 255)); then r=255; fi
    if ((g > 255)); then g=255; fi
    if ((b > 255)); then b=255; fi
    printf '#%02X%02X%02X' "$r" "$g" "$b"
}

mix() {
    local i out='#'
    for i in 0 2 4; do
        local a b
        a=$(hex_channel "$1" "$i")
        b=$(hex_channel "$2" "$i")
        out+=$(printf '%02X' "$(( (a * (1000 - $3) + b * $3 + 500) / 1000 ))")
    done
    printf '%s' "$out"
}

luma601() {
    printf '%d' "$((
        299 * $(hex_channel "$1" 0) +
        587 * $(hex_channel "$1" 2) +
        114 * $(hex_channel "$1" 4)
    ))"
}

readonly AWK_COLOR='
function chan(hex, i,    c) {
    c = strtonum("0x" substr(hex, i, 2)) / 255
    return (c <= 0.04045) ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4
}
function lum(hex) {
    return 0.2126 * chan(hex, 2) + 0.7152 * chan(hex, 4) + 0.0722 * chan(hex, 6)
}
function contrast(a, b,    l1, l2, t) {
    l1 = lum(a); l2 = lum(b)
    if (l1 < l2) { t = l1; l1 = l2; l2 = t }
    return (l1 + 0.05) / (l2 + 0.05)
}
function mix(hex, target, t,    i, out, c, d) {
    out = "#"
    for (i = 2; i <= 6; i += 2) {
        c = strtonum("0x" substr(hex, i, 2))
        d = (target ~ /^#/) ? strtonum("0x" substr(target, i, 2)) : target
        out = out sprintf("%02X", int(c + (d - c) * t + 0.5))
    }
    return out
}
function lift(hex, floor,    target, t, cand) {
    if (contrast(hex, bg) >= floor) return hex
    target = (lum(bg) < 0.5) ? 255 : 0
    for (t = 0.05; t <= 1.0001; t += 0.05) {
        cand = mix(hex, target, t)
        if (contrast(cand, bg) >= floor) return cand
    }
    return (target == 255) ? "#FFFFFF" : "#000000"
}
'

pick_dim() {
    gawk -v bg="$1" -v min="$COLORS_DIM_CONTRAST" "$AWK_COLOR"'
        /^#[0-9A-Fa-f]{6}$/ && toupper($0) != toupper(bg) {
            c = contrast($0, bg)
            if (c >= min && (pick == "" || c < pickc)) { pick = $0; pickc = c }
            if (c > bestc) { bestc = c; best = $0 }
        }
        END {
            if (pick != "") { print pick; exit }
            print lift(best == "" ? bg : best, min)
        }
    '
}

pick_contrasting() {
    gawk -v bg="$1" -v min="$COLORS_MIN_CONTRAST" "$AWK_COLOR"'
        BEGIN { best = ""; bestc = 0 }
        /^#[0-9A-Fa-f]{6}$/ {
            c = contrast($0, bg)
            if (c > bestc) { bestc = c; best = $0 }
        }
        END {
            if (best == "") { print bg; exit }
            print lift(best, min)
        }
    '
}

pick_accent() {
    gawk -v bg="$1" -v min="$COLORS_MIN_CONTRAST" -v minchroma="$COLORS_MIN_CHROMA" "$AWK_COLOR"'
        function chroma(hex,    r, g, b, mx, mn) {
            r = strtonum("0x" substr(hex, 2, 2))
            g = strtonum("0x" substr(hex, 4, 2))
            b = strtonum("0x" substr(hex, 6, 2))
            mx = r; if (g > mx) mx = g; if (b > mx) mx = b
            mn = r; if (g < mn) mn = g; if (b < mn) mn = b
            return (mx - mn) / 255
        }
        BEGIN { best = ""; bestchroma = -1; ok = ""; okchroma = -1 }
        /^#[0-9A-Fa-f]{6}$/ {
            ch = chroma($0)
            if (ch > bestchroma) { bestchroma = ch; best = $0 }
            if (contrast($0, bg) >= min && ch > okchroma) { okchroma = ch; ok = $0 }
        }
        END {
            if (ok != "" && okchroma >= minchroma) { print ok; exit }
            if (best == "") { print bg; exit }
            print lift(best, min)
        }
    '
}

ansi_hues() {
    gawk -v bg="$1" -v tintc="$2" -v min="$COLORS_MIN_CONTRAST" \
        -v sat="$COLORS_ANSI_SAT" -v tint="$COLORS_ANSI_TINT" "$AWK_COLOR"'
        function k(n, h) { return (n + h / 30) % 12 }
        function f(n, h, s, l,    a, x) {
            a = s * ((l < 1 - l) ? l : 1 - l)
            x = k(n, h) - 3
            if (9 - k(n, h) < x) x = 9 - k(n, h)
            if (x > 1) x = 1
            if (x < -1) x = -1
            return l - a * x
        }
        function hsl(h, s, l) {
            return sprintf("#%02X%02X%02X", int(f(0, h, s, l) * 255 + 0.5), int(f(8, h, s, l) * 255 + 0.5), int(f(4, h, s, l) * 255 + 0.5))
        }
        BEGIN {
            dark = lum(bg) < 0.5
            split("0 125 48 215 300 180", hue, " ")
            for (pass = 0; pass < 2; pass++) {
                l = dark ? 0.58 + pass * 0.1 : 0.42 - pass * 0.1
                for (i = 1; i <= 6; i++) {
                    col = mix(hsl(hue[i], sat, l), tintc, tint / 1000)
                    print lift(col, min)
                }
            }
        }
    '
}

read_base() {
    local img=$1 raw
    if ! raw=$(magick "$img" \
        -alpha off \
        -thumbnail "${COLORS_SAMPLE}x${COLORS_SAMPLE}^" \
        -colors "$BASE" -unique-colors -depth 8 txt:- 2>&1)
    then
        warn "magick failed:"
        printf '%s\n' "$raw" >&2
        die "could not read colors from $img"
    fi

    printf '%s\n' "$raw" |
        gawk '$1 ~ /^[0-9]+,[0-9]+:$/ { print toupper($3) }' |
        while read -r hex; do
            printf '%s %s\n' "$(luma601 "$hex")" "$hex"
        done |
        sort -n -k1,1 |
        cut -d' ' -f2 |
        head -n "$BASE"
}

emit_colors() {
    printf '%s' "$img" > "$out/colors"
}

emit_txt() {
    printf '%s\n' "${c[@]}" > "$out/colors.txt"
}

emit_sh() {
    {
        local i
        for i in "${!c[@]}"; do
            printf 'color%d=%s\n' "$i" "${c[$i]}"
        done
        printf 'background=%s\n' "$bg"
        printf 'foreground=%s\n' "$fg"
        printf 'cursor=%s\n' "$cursor"
        printf 'accent=%s\n' "$accent"
        printf 'wallpaper=%s\n' "$img"
    } > "$out/colors.sh"
}

emit_fish() {
    local b=() i
    for i in "${!c[@]}"; do
        b[i]=$(hex_bare "${c[$i]}")
    done
    local bgb fgb tlb
    bgb=$(hex_bare "$bg")
    fgb=$(hex_bare "$fg")
    tlb=$(hex_bare "$tile")

    cat > "$out/colors.fish" <<EOF
set fish_color_autosuggestion ${b[8]}
set fish_color_cancel ${b[1]} --reverse
set fish_color_command ${b[10]}
set fish_color_comment ${b[8]}
set fish_color_cwd ${b[2]}
set fish_color_cwd_root ${b[1]}
set fish_color_end ${b[3]}
set fish_color_error ${b[1]}
set fish_color_escape ${b[5]}
set fish_color_history_current --bold
set fish_color_host ${b[12]}
set fish_color_host_remote ${b[12]}
set fish_color_keyword ${b[5]}
set fish_color_match --background=${b[4]}
set fish_color_normal $fgb
set fish_color_operator ${b[6]}
set fish_color_option ${b[3]}
set fish_color_param ${b[12]}
set fish_color_quote ${b[11]}
set fish_color_redirection ${b[5]}
set fish_color_search_match --background=$tlb
set fish_color_selection --background=$tlb
set fish_color_status ${b[1]}
set fish_color_user ${b[10]}
set fish_color_valid_path --underline
set fish_pager_color_background $bgb
set fish_pager_color_completion $fgb
set fish_pager_color_description --background=$tlb
set fish_pager_color_prefix ${b[10]}
set fish_pager_color_progress ${b[8]}
set fish_pager_color_secondary_background $bgb
set fish_pager_color_secondary_completion $fgb
set fish_pager_color_secondary_description ${b[8]}
set fish_pager_color_secondary_prefix ${b[10]}
set fish_pager_color_selected_background --background=$tlb
set fish_pager_color_selected_completion $fgb
set fish_pager_color_selected_description ${b[8]}
set fish_pager_color_selected_prefix ${b[10]}
EOF
}

emit_json() {
    {
        printf '{\n'
        printf '  "wallpaper": "%s",\n' "$img"
        printf '  "alpha": "100",\n'
        printf '  "special": {\n'
        printf '    "background": "%s",\n' "$bg"
        printf '    "foreground": "%s",\n' "$fg"
        printf '    "cursor": "%s",\n' "$cursor"
        printf '    "accent": "%s"\n' "$accent"
        printf '  },\n'
        printf '  "colors": {\n'
        local i last=$((${#c[@]} - 1)) comma
        for i in "${!c[@]}"; do
            comma=,
            if ((i == last)); then comma=; fi
            printf '    "color%d": "%s"%s\n' "$i" "${c[$i]}" "$comma"
        done
        printf '  }\n'
        printf '}\n'
    } > "$out/colors.json"
}

emit_sequences() {
    {
        local i
        for i in "${!c[@]}"; do
            printf '\033]4;%d;%s\007' "$i" "${c[$i]}"
        done
        printf '\033]10;%s\007' "$fg"
        printf '\033]11;%s\007' "$bg"
        printf '\033]12;%s\007' "$cursor"
    } > "$out/sequences"
}

emit_kitty() {
    {
        printf 'foreground         %s\n' "$fg"
        printf 'background         %s\n' "$bg"
        printf 'background_opacity 1.0\n'
        printf 'cursor             %s\n' "$cursor"
        printf '\n'
        printf 'active_tab_foreground     %s\n' "$bg"
        printf 'active_tab_background     %s\n' "$fg"
        printf 'inactive_tab_foreground   %s\n' "$fg"
        printf 'inactive_tab_background   %s\n' "$bg"
        printf '\n'
        printf 'active_border_color   %s\n' "$fg"
        printf 'inactive_border_color %s\n' "$bg"
        printf 'bell_border_color     %s\n' "${c[1]}"
        printf '\n'
        printf 'selection_foreground %s\n' "$bg"
        printf 'selection_background %s\n' "$fg"
        printf 'url_color            %s\n' "${c[4]}"
        printf '\n'
        local i
        for i in "${!c[@]}"; do
            printf 'color%-8d %s\n' "$i" "${c[$i]}"
        done
    } > "$out/kitty.conf"
}

foot_section() {
    local v
    v=$(foot --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -n1) || true
    if [[ $v =~ ^([0-9]+)\.([0-9]+)$ ]] && ((BASH_REMATCH[1] == 1 && BASH_REMATCH[2] < 24)); then
        printf 'colors'
    else
        printf 'colors-dark'
    fi
}

emit_foot() {
    {
        printf '[%s]\n' "$(foot_section)"
        printf 'foreground=%s\n' "$(hex_bare "$fg")"
        printf 'background=%s\n' "$(hex_bare "$bg")"
        printf 'selection-foreground=%s\n' "$(hex_bare "$bg")"
        printf 'selection-background=%s\n' "$(hex_bare "$fg")"
        printf 'urls=%s\n' "$(hex_bare "${c[4]}")"
        local i
        for i in {0..7}; do
            printf 'regular%d=%s\n' "$i" "$(hex_bare "${c[$i]}")"
        done
        for i in {0..7}; do
            printf 'bright%d=%s\n' "$i" "$(hex_bare "${c[$((i + 8))]}")"
        done
    } > "$out/foot.ini"
}

emit_alacritty() {
    local names=(black red green yellow blue magenta cyan white) i
    {
        printf '[colors.primary]\n'
        printf 'background = "%s"\n' "$bg"
        printf 'foreground = "%s"\n' "$fg"
        printf '\n[colors.cursor]\n'
        printf 'text = "%s"\n' "$bg"
        printf 'cursor = "%s"\n' "$cursor"
        printf '\n[colors.selection]\n'
        printf 'text = "%s"\n' "$bg"
        printf 'background = "%s"\n' "$fg"
        printf '\n[colors.normal]\n'
        for i in {0..7}; do
            printf '%s = "%s"\n' "${names[$i]}" "${c[$i]}"
        done
        printf '\n[colors.bright]\n'
        for i in {0..7}; do
            printf '%s = "%s"\n' "${names[$i]}" "${c[$((i + 8))]}"
        done
    } > "$out/alacritty.toml"
}

emit_ghostty() {
    {
        printf 'background = %s\n' "$bg"
        printf 'foreground = %s\n' "$fg"
        printf 'cursor-color = %s\n' "$cursor"
        printf 'cursor-text = %s\n' "$bg"
        printf 'selection-background = %s\n' "$fg"
        printf 'selection-foreground = %s\n' "$bg"
        local i
        for i in "${!c[@]}"; do
            printf 'palette = %d=%s\n' "$i" "${c[$i]}"
        done
    } > "$out/ghostty"
}

emit_tmux() {
    cat > "$out/tmux.conf" <<EOF
set -g status-style "bg=$bg,fg=$fg"
set -g status-left-style "bg=$bg,fg=${c[4]}"
set -g status-right-style "bg=$bg,fg=${c[8]}"
set -g window-status-style "bg=$bg,fg=${c[8]}"
set -g window-status-current-style "bg=$tile,fg=$fg,bold"
set -g window-status-activity-style "bg=$bg,fg=${c[3]}"
set -g pane-border-style "fg=${c[8]}"
set -g pane-active-border-style "fg=$fg"
set -g message-style "bg=$chip,fg=$fg"
set -g message-command-style "bg=$chip,fg=$fg"
set -g mode-style "bg=${c[4]},fg=$bg"
set -g display-panes-colour "${c[8]}"
set -g display-panes-active-colour "$fg"
set -g clock-mode-colour "${c[4]}"
EOF
}

emit_lua() {
    {
        printf 'return {\n'
        printf '  wallpaper = "%s",\n' "$img"
        printf '  background = "%s",\n' "$bg"
        printf '  foreground = "%s",\n' "$fg"
        printf '  cursor = "%s",\n' "$cursor"
        printf '  accent = "%s",\n' "$accent"
        printf '  color = {\n'
        local i
        for i in "${!c[@]}"; do
            printf '    [%d] = "%s",\n' "$i" "${c[$i]}"
        done
        printf '  },\n'
        printf '  rgb = {\n'
        for i in "${!c[@]}"; do
            printf '    [%d] = "rgb(%s)",\n' "$i" "$(hex_bare "${c[$i]}")"
        done
        printf '  },\n'
        printf '}\n'
    } > "$out/colors.lua"
}

emit_css() {
    {
        printf ':root {\n'
        printf '  --wallpaper: url("%s");\n' "$img"
        printf '  --background: %s;\n' "$bg"
        printf '  --foreground: %s;\n' "$fg"
        printf '  --cursor: %s;\n' "$cursor"
        printf '  --accent: %s;\n' "$accent"
        local i
        for i in "${!c[@]}"; do
            printf '  --color%d: %s;\n' "$i" "${c[$i]}"
        done
        printf '}\n'
    } > "$out/colors.css"
}

emit_gtk() {
    {
        printf '@define-color background %s;\n' "$bg"
        printf '@define-color foreground %s;\n' "$fg"
        printf '@define-color cursor %s;\n' "$cursor"
        printf '@define-color accent %s;\n' "$accent"
        local i
        for i in "${!c[@]}"; do
            printf '@define-color color%d %s;\n' "$i" "${c[$i]}"
        done
        local name
        for name in window view; do
            printf '@define-color %s_bg_color %s;\n@define-color %s_fg_color %s;\n' "$name" "$bg" "$name" "$fg"
        done
        for name in headerbar card popover dialog sidebar secondary_sidebar thumbnail; do
            printf '@define-color %s_bg_color %s;\n@define-color %s_fg_color %s;\n' "$name" "$chip" "$name" "$fg"
        done
        printf '@define-color headerbar_backdrop_color %s;\n' "$bg"
        printf '@define-color sidebar_backdrop_color %s;\n' "$bg"
        printf '@define-color secondary_sidebar_backdrop_color %s;\n' "$bg"
        printf '@define-color accent_color %s;\n' "$accent"
        printf '@define-color accent_bg_color %s;\n' "$accent"
        printf '@define-color accent_fg_color %s;\n' "$bg"
        printf '@define-color panel_bg_color %s;\n@define-color panel_fg_color %s;\n' "$chip" "$fg"
        printf '@define-color headerbar_border_color %s;\n' "$fg"
        local tone
        for name in destructive:$COLORS_RED error:$COLORS_RED warning:$COLORS_YELLOW success:$COLORS_GREEN; do
            tone=${name#*:}
            printf '@define-color %s_color %s;\n@define-color %s_bg_color %s;\n' "${name%%:*}" "$tone" "${name%%:*}" "$tone"
        done
        printf '@define-color theme_bg_color %s;\n@define-color theme_fg_color %s;\n' "$bg" "$fg"
        printf '@define-color theme_base_color %s;\n@define-color theme_text_color %s;\n' "$bg" "$fg"
        printf '@define-color theme_selected_bg_color %s;\n@define-color theme_selected_fg_color %s;\n' "$accent" "$bg"
        printf '@define-color insensitive_bg_color %s;\n' "$tile"
        printf '@define-color theme_unfocused_bg_color %s;\n@define-color theme_unfocused_fg_color %s;\n' "$bg" "$fg"
        printf '@define-color theme_unfocused_base_color %s;\n@define-color theme_unfocused_text_color %s;\n' "$bg" "$fg"
    } > "$out/gtk.css"
}

emit_btop() {
    cat > "$out/btop.theme" <<EOF
theme[main_bg]="$bg"
theme[main_fg]="$fg"
theme[title]="$fg"
theme[hi_fg]="${c[4]}"
theme[selected_bg]="$tile"
theme[selected_fg]="$fg"
theme[inactive_fg]="${c[8]}"
theme[graph_text]="$fg"
theme[meter_bg]="$chip"
theme[proc_misc]="${c[6]}"
theme[cpu_box]="${c[8]}"
theme[mem_box]="${c[8]}"
theme[net_box]="${c[8]}"
theme[proc_box]="${c[8]}"
theme[div_line]="${c[8]}"
theme[temp_start]="${c[4]}"
theme[temp_mid]="${c[5]}"
theme[temp_end]="${c[1]}"
theme[cpu_start]="${c[2]}"
theme[cpu_mid]="${c[3]}"
theme[cpu_end]="${c[1]}"
theme[free_start]="${c[2]}"
theme[free_mid]="${c[10]}"
theme[free_end]="${c[6]}"
theme[cached_start]="${c[4]}"
theme[cached_mid]="${c[12]}"
theme[cached_end]="${c[6]}"
theme[available_start]="${c[3]}"
theme[available_mid]="${c[11]}"
theme[available_end]="${c[5]}"
theme[used_start]="${c[1]}"
theme[used_mid]="${c[9]}"
theme[used_end]="${c[5]}"
theme[download_start]="${c[4]}"
theme[download_mid]="${c[12]}"
theme[download_end]="${c[6]}"
theme[upload_start]="${c[2]}"
theme[upload_mid]="${c[10]}"
theme[upload_end]="${c[3]}"
EOF
}

emit_zathura() {
    cat > "$out/zathurarc" <<EOF
set default-bg          "$bg"
set default-fg          "$fg"
set statusbar-bg        "$chip"
set statusbar-fg        "$fg"
set inputbar-bg         "$bg"
set inputbar-fg         "$fg"
set notification-bg     "$bg"
set notification-fg     "$fg"
set notification-error-bg "${c[1]}"
set notification-error-fg "$bg"
set notification-warning-bg "${c[3]}"
set notification-warning-fg "$bg"
set highlight-color     "${c[3]}"
set highlight-active-color "${c[4]}"
set completion-bg       "$bg"
set completion-fg       "$fg"
set completion-highlight-bg "$tile"
set completion-highlight-fg "$fg"
set recolor-lightcolor  "$bg"
set recolor-darkcolor   "$fg"
EOF
}

kde_rgb() {
    local r g b
    read -r r g b <<<"$(hex_rgb "$1")"
    printf '%d,%d,%d' "$r" "$g" "$b"
}

kde_group() {
    printf '[Colors:%s]\n' "$1"
    printf 'BackgroundAlternate=%s\n' "$(kde_rgb "$3")"
    printf 'BackgroundNormal=%s\n' "$(kde_rgb "$2")"
    printf 'DecorationFocus=%s\n' "$(kde_rgb "$accent")"
    printf 'DecorationHover=%s\n' "$(kde_rgb "$accent")"
    printf 'ForegroundActive=%s\n' "$(kde_rgb "$6")"
    printf 'ForegroundInactive=%s\n' "$(kde_rgb "$5")"
    printf 'ForegroundLink=%s\n' "$(kde_rgb "$6")"
    printf 'ForegroundNegative=%s\n' "$(kde_rgb "$COLORS_RED")"
    printf 'ForegroundNeutral=%s\n' "$(kde_rgb "$COLORS_YELLOW")"
    printf 'ForegroundNormal=%s\n' "$(kde_rgb "$4")"
    printf 'ForegroundPositive=%s\n' "$(kde_rgb "$COLORS_GREEN")"
    printf 'ForegroundVisited=%s\n\n' "$(kde_rgb "$6")"
}

emit_kde() {
    local muted seldim
    muted=$(mix "$bg" "$fg" 600)
    seldim=$(mix "$accent" "$bg" 400)
    {
        kde_group View "$bg" "$chip" "$fg" "$muted" "$accent"
        kde_group Window "$bg" "$chip" "$fg" "$muted" "$accent"
        kde_group Button "$chip" "$tile" "$fg" "$muted" "$accent"
        kde_group Selection "$accent" "$accent" "$bg" "$seldim" "$bg"
        kde_group Tooltip "$chip" "$tile" "$fg" "$muted" "$accent"
        kde_group Complementary "$bg" "$chip" "$fg" "$muted" "$accent"
        kde_group Header "$chip" "$tile" "$fg" "$muted" "$accent"
        kde_group 'Header][Inactive' "$bg" "$chip" "$fg" "$muted" "$accent"
        printf '[WM]\n'
        printf 'activeBackground=%s\n' "$(kde_rgb "$chip")"
        printf 'activeBlend=%s\n' "$(kde_rgb "$chip")"
        printf 'activeForeground=%s\n' "$(kde_rgb "$fg")"
        printf 'inactiveBackground=%s\n' "$(kde_rgb "$bg")"
        printf 'inactiveBlend=%s\n' "$(kde_rgb "$bg")"
        printf 'inactiveForeground=%s\n' "$(kde_rgb "$muted")"
    } > "$out/kdeglobals"
}

emit_qtct() {
    local muted seldim light dark off active disabled
    muted=$(mix "$bg" "$fg" 600)
    seldim=$(mix "$accent" "$bg" 400)
    light=$(mix "$bg" "$fg" 250)
    dark=$(mix "$bg" '#000000' 400)
    off=$(mix "$bg" "$fg" 400)
    active="$fg, $chip, $light, $tile, $dark, $chip, $fg, $fg, $fg, $bg, $bg, #000000, $accent, $bg, $accent, $accent, $chip, #000000, $chip, $fg, $muted, $accent"
    disabled="$off, $chip, $light, $tile, $dark, $chip, $off, $off, $off, $bg, $bg, #000000, $seldim, $off, $seldim, $seldim, $chip, #000000, $chip, $off, $off, $seldim"
    {
        printf '[ColorScheme]\n'
        printf 'active_colors=%s\n' "$active"
        printf 'disabled_colors=%s\n' "$disabled"
        printf 'inactive_colors=%s\n' "$active"
    } > "$out/qtct.conf"
}

emit_shell_hooks() {
    cat > "$out/shell.sh" <<EOF
case \$- in *i*) ;; *) return 0 ;; esac
[ -t 1 ] || return 0
case \$TERM in linux | dumb) return 0 ;; esac
[ -r "$dest/sequences" ] && cat "$dest/sequences"
EOF
    cat > "$out/shell.fish" <<EOF
status is-interactive; or return
test -t 1; or return
contains -- "\$TERM" linux dumb; and return
test -r "$dest/sequences"; and cat "$dest/sequences"
EOF
}

emit_xresources() {
    {
        printf '*.foreground:  %s\n' "$fg"
        printf '*.background:  %s\n' "$bg"
        printf '*.cursorColor: %s\n' "$cursor"
        local i
        for i in "${!c[@]}"; do
            printf '*.color%d: %s\n' "$i" "${c[$i]}"
        done
    } > "$out/Xresources"
}

set_wallpaper() {
    local img=$1 monitor=$2 outputs=() awww_out
    if ! command -v awww >/dev/null 2>&1; then
        warn "awww not found; skipping wallpaper"
        return 0
    fi

    if [[ -n $monitor ]] &&
        awww query 2>/dev/null | grep -q ": $monitor:"
    then
        outputs=(-o "$monitor")
    fi

    if ! awww_out=$(awww img "${outputs[@]}" "$img" \
        --transition-type "$COLORS_TRANSITION" \
        --transition-duration "$COLORS_TRANSITION_DURATION" \
        --transition-fps "$COLORS_TRANSITION_FPS" 2>&1)
    then
        warn "awww: $awww_out"
        return 0
    fi

    if ((${#outputs[@]})) && [[ -n $COLORS_CLEAR_OUTPUTS ]]; then
        awww clear --outputs "$COLORS_CLEAR_OUTPUTS" >/dev/null 2>&1 || true
    fi
}

sync_kde_colors() {
    local src=$1 cfg="${XDG_CONFIG_HOME:-$HOME/.config}/kdeglobals" tmp
    cfg=$(realpath -m -- "$cfg")
    [[ -f $cfg || ${QT_QPA_PLATFORMTHEME-} == kde ]] || return 0
    if [[ -e $cfg && ! -w $(realpath -- "$cfg") ]]; then
        warn "$cfg is not writable; skipping qt colors"
        return 0
    fi
    mkdir -p -- "$(dirname -- "$cfg")"
    tmp=$(mktemp "$cfg.XXXXXXXX")
    {
        if [[ -f $cfg ]]; then
            gawk '
                /^\[/ { skip = ($0 ~ /^\[Colors:/ || $0 == "[WM]") }
                skip { next }
                /^[[:space:]]*$/ { blank = 1; next }
                { if (blank && n) print ""; blank = 0; print; n++ }
            ' "$cfg"
        fi
        printf '\n'
        cat "$src"
    } > "$tmp"
    chmod 600 -- "$tmp"
    mv -f -- "$tmp" "$cfg"
    if command -v busctl >/dev/null 2>&1; then
        busctl --user emit /KGlobalSettings org.kde.KGlobalSettings notifyChange ii 0 0 >/dev/null 2>&1 || true
    elif command -v dbus-send >/dev/null 2>&1; then
        dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 >/dev/null 2>&1 || true
    fi
}

readonly HOOKS='bash zsh fish kitty foot alacritty ghostty tmux zathura btop gtk qt'

sync_qtct() {
    local cfg=${XDG_CONFIG_HOME:-$HOME/.config} tool conf t
    for tool in qt5ct qt6ct; do
        conf=$cfg/$tool/$tool.conf
        if [[ ! -f $conf ]] || ! grep -qxF "color_scheme_path=$cfg/$tool/colors/colors.conf" "$conf"; then continue; fi
        t=$(mktemp -p "$cfg/$tool" .colors.XXXXXXXX 2>/dev/null) && rm -f -- "$t"
    done
}

hook_line() {
    case $1 in
        bash | zsh) printf '[ -f "%s/shell.sh" ] && . "%s/shell.sh"' "$2" "$2" ;;
        fish) printf 'test -f "%s/shell.fish"; and source "%s/shell.fish"' "$2" "$2" ;;
        kitty) printf 'include %s/kitty.conf' "$2" ;;
        foot) printf 'include=%s/foot.ini' "$2" ;;
        alacritty) printf 'import = ["%s/alacritty.toml"]' "$2" ;;
        ghostty) printf 'config-file = ?%s/ghostty' "$2" ;;
        tmux) printf 'source-file -q "%s/tmux.conf"' "$2" ;;
        zathura) printf 'include "%s/zathurarc"' "$2" ;;
        gtk) printf '@import url("file://%s/gtk.css");' "$(uri_path "$2")" ;;
    esac
}

uri_path() {
    local LC_ALL=C s=$1 out='' ch i
    for ((i = 0; i < ${#s}; i++)); do
        ch=${s:i:1}
        case $ch in
            [A-Za-z0-9/._~-]) out+=$ch ;;
            *) printf -v ch '%%%02X' "'$ch"; out+=$ch ;;
        esac
    done
    printf '%s' "$out"
}

hook_file() {
    local cfg=${XDG_CONFIG_HOME:-$HOME/.config}
    case $1 in
        bash) printf '%s\n' "$HOME/.bashrc" ;;
        zsh) printf '%s\n' "${ZDOTDIR:-$HOME}/.zshrc" ;;
        fish) printf '%s\n' "$cfg/fish/conf.d/colors.fish" ;;
        kitty) printf '%s\n' "$cfg/kitty/kitty.conf" ;;
        foot) printf '%s\n' "$cfg/foot/foot.ini" ;;
        alacritty) printf '%s\n' "$cfg/alacritty/alacritty.toml" ;;
        ghostty)
            if [[ -f $cfg/ghostty/config.ghostty ]]; then
                printf '%s\n' "$cfg/ghostty/config.ghostty"
            else
                printf '%s\n' "$cfg/ghostty/config"
            fi
            ;;
        tmux)
            if [[ -f $HOME/.tmux.conf ]]; then
                printf '%s\n' "$HOME/.tmux.conf"
            else
                printf '%s\n' "$cfg/tmux/tmux.conf"
            fi
            ;;
        zathura) printf '%s\n' "$cfg/zathura/zathurarc" ;;
        gtk) printf '%s\n' "$cfg/gtk-3.0/gtk.css" "$cfg/gtk-4.0/gtk.css" ;;
    esac
}

end_line() {
    [[ -s $1 ]] || return 1
    cat -- "$1"
    [[ -z $(tail -c1 -- "$1") ]] || printf "\n"
}

touch_template() {
    [[ -e $1 ]] && return 0
    mkdir -p -- "$(dirname -- "$1")" && : > "$1"
}

writable() {
    if [[ -e $1 && ! -w $(realpath -- "$1") ]] || ! mkdir -p -- "$(dirname -- "$1")" 2>/dev/null; then
        warn "$1 is not writable; add this to your $2 config yourself:"
        printf '%s\n' "$3" >&2
        return 1
    fi
}

replace_file() {
    [[ -f $2 ]] && chmod --reference="$2" -- "$1"
    mv -f -- "$1" "$2"
}

hook_into() {
    local name=$1 line=$2 rc=$3 tmp item=$2
    [[ $name == alacritty ]] && item=${line#*[} && item=${item%]}
    if [[ -f $rc ]] && grep -qF -- "$item" "$rc"; then
        printf '%s: %s hook already in %s\n' "$PROG" "$name" "$rc"
        return 0
    fi
    writable "$rc" "$name" "$line" || return 1
    rc=$(realpath -- "$rc" 2>/dev/null || printf '%s' "$rc")
    tmp=$(mktemp "$rc.XXXXXXXX")
    case $name in
        foot)
            { printf "%s\n" "$line"; end_line "$rc" || true; } > "$tmp"
            ;;
        alacritty)
            if [[ -f $rc ]] && grep -qE '^[[:space:]]*import[[:space:]]*=' "$rc"; then
                gawk -v RS='^$' -v ORS= -v p="$item" '
                    {
                        if (!match($0, /(^|\n)[ \t]*import[ \t]*=[ \t]*\[[^]]*\]/)) { print; next }
                        head = substr($0, 1, RSTART + RLENGTH - 2)
                        tail = substr($0, RSTART + RLENGTH - 1)
                        body = head
                        sub(/[ \t\n]+$/, "", body)
                        sep = body ~ /[[,]$/ ? (body ~ /,$/ ? " " : "") : ", "
                        print body sep p substr(head, length(body) + 1) tail
                    }
                ' "$rc" > "$tmp"
            elif [[ -f $rc ]] && grep -qE '^[[:space:]]*\[general\]' "$rc"; then
                gawk -v l="$line" '{ print } !done && /^[[:space:]]*\[general\]/ { print l; done = 1 }' "$rc" > "$tmp"
            else
                { end_line "$rc" && printf "\n"; printf "[general]\n%s\n" "$line"; } > "$tmp"
            fi
            ;;
        gtk)
            if [[ -s $rc ]]; then
                gawk -v l="$line" '
                    { line[NR] = $0 }
                    stop { next }
                    incom { if (index($0, "*/")) incom = 0; next }
                    /^[[:space:]]*\/\*/ { if (!index(substr($0, index($0, "/*") + 2), "*/")) incom = 1; next }
                    /^[[:space:]]*(@import|@charset)/ { at = NR; next }
                    !/^[[:space:]]*$/ { stop = 1 }
                    END {
                        if (!at) print l
                        for (i = 1; i <= NR; i++) {
                            print line[i]
                            if (i == at) print l
                        }
                    }
                ' "$rc" > "$tmp"
            else
                printf "%s\n" "$line" > "$tmp"
            fi
            ;;
        *)
            { end_line "$rc"; printf "%s\n" "$line"; } > "$tmp"
            ;;
    esac
    replace_file "$tmp" "$rc"
    printf '%s: added %s hook to %s\n' "$PROG" "$name" "$rc"
}

gtk_theme() {
    local theme=${GTK_THEME-} ini=${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini
    theme=${theme%%:*}
    if [[ -z $theme ]] && command -v gsettings >/dev/null 2>&1; then
        theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || true)
        theme=${theme//\'/}
    fi
    if [[ -z $theme && -f $ini ]]; then
        theme=$(sed -n 's/^[[:space:]]*gtk-theme-name[[:space:]]*=[[:space:]]*//p' "$ini" | tail -n1)
    fi
    printf '%s' "${theme:-Adwaita}"
}

qtct_hook() {
    local conf=$1/${1##*/}.conf scheme=$1/colors/colors.conf src tmp
    if [[ -e $scheme && ! -L $scheme ]]; then
        warn "$scheme exists and is not a link; move it and run the qt hook again"
        return 1
    fi
    if [[ $(readlink -- "$scheme" 2>/dev/null) != "$2" ]]; then
        writable "$scheme" qt "ln -s $2 $scheme" || return 1
        ln -sfn -- "$2" "$scheme"
    fi
    src=$conf
    if [[ -f $conf ]] && grep -qxF "color_scheme_path=$scheme" "$conf" && grep -qx 'custom_palette=true' "$conf"; then
        printf '%s: qt hook already in %s\n' "$PROG" "$conf"
        return 0
    fi
    writable "$conf" qt "$(printf '[Appearance]\ncolor_scheme_path=%s\ncustom_palette=true' "$scheme")" || return 1
    conf=$(realpath -m -- "$conf")
    [[ -f $conf ]] || src=/dev/null
    tmp=$(mktemp "$conf.XXXXXXXX")
    gawk -v s="$scheme" '
        FNR == NR {
            if (/^\[/) a = ($0 == "[Appearance]")
            else if (a && /^custom_palette=/) cp = 1
            else if (a && /^color_scheme_path=/) sp = 1
            next
        }
        /^\[/ {
            a = ($0 == "[Appearance]")
            print
            if (a) {
                seen = 1
                if (!sp) print "color_scheme_path=" s
                if (!cp) print "custom_palette=true"
            }
            next
        }
        a && /^custom_palette=/ { print "custom_palette=true"; next }
        a && /^color_scheme_path=/ { print "color_scheme_path=" s; next }
        { print }
        END {
            if (!seen) {
                if (FNR) print ""
                print "[Appearance]"
                print "color_scheme_path=" s
                print "custom_palette=true"
            }
        }
    ' "$src" "$src" > "$tmp"
    replace_file "$tmp" "$conf"
    printf '%s: added qt hook to %s\n' "$PROG" "$conf"
}

install_qt_hook() {
    local cfg=${XDG_CONFIG_HOME:-$HOME/.config} tool tools=() ok=0
    if [[ ${QT_QPA_PLATFORMTHEME-} == kde ]]; then
        printf '%s: qt uses the kde platform theme, which follows the palette through kdeglobals already\n' "$PROG"
        return 0
    fi
    for tool in qt5ct qt6ct; do
        if [[ -d $cfg/$tool ]] || command -v "$tool" >/dev/null 2>&1; then
            tools+=("$tool")
        fi
    done
    ((${#tools[@]})) || tools=(qt6ct)
    for tool in "${tools[@]}"; do
        qtct_hook "$cfg/$tool" "$1/qtct.conf" || ok=1
    done
    case ${QT_QPA_PLATFORMTHEME-} in
        qt5ct | qt6ct) ;;
        *) printf '%s: qt apps read it once QT_QPA_PLATFORMTHEME=qt6ct (qt5ct for qt5 apps) is set\n' "$PROG" ;;
    esac
    return "$ok"
}

install_hook() {
    local name=$1 rc rcs=() ok=0 theme
    case $name in
        kitty) touch_template "$2/kitty.conf" ;;
        foot) touch_template "$2/foot.ini" ;;
        alacritty) touch_template "$2/alacritty.toml" ;;
        ghostty) touch_template "$2/ghostty" ;;
        tmux) touch_template "$2/tmux.conf" ;;
        zathura) touch_template "$2/zathurarc" ;;
        gtk) touch_template "$2/gtk.css" ;;
        btop)
            touch_template "$2/btop.theme"
            install_btop_hook "$2"
            return
            ;;
        qt)
            touch_template "$2/qtct.conf"
            install_qt_hook "$2"
            return
            ;;
    esac
    mapfile -t rcs < <(hook_file "$name")
    for rc in "${rcs[@]}"; do
        hook_into "$name" "$(hook_line "$name" "$2")" "$rc" || ok=1
    done
    if [[ $name == gtk ]]; then
        theme=$(gtk_theme)
        [[ ${theme,,} == adw-gtk3* ]] || select_adw_gtk3 "$theme" || ok=1
    fi
    return "$ok"
}

install_btop_hook() {
    local dir=${XDG_CONFIG_HOME:-$HOME/.config}/btop conf theme tmp src
    theme=$dir/themes/colors.theme
    conf=$dir/btop.conf
    if [[ -e $theme && ! -L $theme ]]; then
        warn "$theme exists and is not a link; move it and run the btop hook again"
        return 1
    fi
    if [[ $(readlink -- "$theme" 2>/dev/null) != "$1/btop.theme" ]]; then
        writable "$theme" btop "ln -s $1/btop.theme $theme" || return 1
        ln -sfn -- "$1/btop.theme" "$theme"
    fi
    if [[ -f $conf ]] && grep -qxE 'color_theme[[:space:]]*=[[:space:]]*"colors"' "$conf"; then
        printf '%s: btop hook already in %s\n' "$PROG" "$conf"
        return 0
    fi
    writable "$conf" btop 'color_theme = "colors"' || return 1
    conf=$(realpath -m -- "$conf")
    src=$conf
    [[ -f $conf ]] || src=/dev/null
    tmp=$(mktemp "$conf.XXXXXXXX")
    gawk '
        /^[[:space:]]*color_theme[[:space:]]*=/ { if (!done) print "color_theme = \"colors\""; done = 1; next }
        { print }
        END { if (!done) print "color_theme = \"colors\"" }
    ' "$src" > "$tmp"
    replace_file "$tmp" "$conf"
    printf '%s: added btop hook to %s\n' "$PROG" "$conf"
}

select_adw_gtk3() {
    local name=adw-gtk3-dark dir found='' ini=${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini tmp src set=0
    local dirs=("${XDG_DATA_HOME:-$HOME/.local/share}/themes" "$HOME/.themes") xdg=()
    IFS=: read -ra xdg <<<"${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    for dir in "${xdg[@]}"; do
        dirs+=("$dir/themes")
    done
    for dir in "${dirs[@]}"; do
        [[ -d $dir/$name/gtk-3.0 ]] && found=1 && break
    done
    if [[ -z $found ]]; then
        warn "gtk3 theme is $1, which follows the palette only in part; install adw-gtk3 and run the gtk hook again"
        return 1
    fi
    if command -v gsettings >/dev/null 2>&1 &&
        gsettings set org.gnome.desktop.interface gtk-theme "$name" 2>/dev/null; then
        set=1
    fi
    if [[ -f $ini && -w $(realpath -- "$ini") ]] || { ((!set)) && [[ ! -e $ini ]]; }; then
        mkdir -p -- "$(dirname -- "$ini")"
        ini=$(realpath -m -- "$ini")
        src=$ini
        [[ -f $ini ]] || src=/dev/null
        tmp=$(mktemp "$ini.XXXXXXXX")
        gawk -v n="$name" '
            /^\[/ { if (s && !done) { print "gtk-theme-name=" n; done = 1 } s = ($0 == "[Settings]") }
            s && /^[[:space:]]*gtk-theme-name[[:space:]]*=/ { if (!done) print "gtk-theme-name=" n; done = 1; next }
            { print }
            END {
                if (s && !done) print "gtk-theme-name=" n
                else if (!done) print "[Settings]\ngtk-theme-name=" n
            }
        ' "$src" > "$tmp"
        replace_file "$tmp" "$ini"
        set=1
    fi
    if ((!set)); then
        warn "could not select $name; set it as your gtk3 theme yourself"
        return 1
    fi
    printf '%s: gtk3 theme set to %s (was %s)\n' "$PROG" "$name" "$1"
    [[ -z ${GTK_THEME-} ]] || warn "GTK_THEME=$GTK_THEME overrides it; unset it or set it to $name"
}

ver_ge() {
    [[ $(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1) == "$2" ]]
}

signal_app() {
    local sig=$1 min=$2 re=$3 dir pid comm v
    for dir in /proc/[0-9]*; do
        [[ -O $dir ]] && read -r comm 2>/dev/null < "$dir/comm" && [[ $comm =~ ^($re)$ ]] || continue
        pid=${dir#/proc/}
        v=$("$dir/exe" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1) || true
        [[ -n $v ]] && ver_ge "$v" "$min" || continue
        kill -s "$sig" "$pid" 2>/dev/null || true
    done
}

reload_zathura() {
    local name
    if command -v busctl >/dev/null 2>&1; then
        for name in $(busctl --user list --no-legend 2>/dev/null | gawk '$1 ~ /^org\.pwmt\.zathura\.PID-/ { print $1 }'); do
            busctl --user call "$name" /org/pwmt/zathura org.pwmt.zathura SourceConfig >/dev/null 2>&1 || true
        done
    elif command -v dbus-send >/dev/null 2>&1; then
        for name in $(dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null |
            gawk -F'"' '$2 ~ /^org\.pwmt\.zathura\.PID-/ { print $2 }'); do
            dbus-send --session --dest="$name" /org/pwmt/zathura org.pwmt.zathura.SourceConfig >/dev/null 2>&1 || true
        done
    fi
}

reload_apps() {
    signal_app USR1 0.23 '\.?kitty(-wrapped)?'
    signal_app USR2 1.2.0 '\.?ghostty(-wrapped?)?'
    signal_app USR2 1.2.0 '\.?btop(-wrapped)?'
    reload_zathura
}

apply_sequences() {
    local pty
    shopt -s nullglob
    for pty in /dev/pts/*; do
        [[ -c $pty && -w $pty && -O $pty ]] || continue
        cat "$1/sequences" > "$pty" 2>/dev/null || true
    done
    shopt -u nullglob
}

print_swatches() {
    local hex r g b
    for hex in "${c[@]:0:$BASE}"; do
        read -r r g b <<<"$(hex_rgb "$hex")"
        printf '\033[48;2;%d;%d;%dm   \033[0m %s\n' "$r" "$g" "$b" "$hex"
    done
}

main() {
    local do_wallpaper=1 do_apply=1 do_print=1
    local dest=$COLORS_DIR
    local main_output=$COLORS_MAIN_OUTPUT
    local img=
    local hooks=()
    local args=()

    while (($#)); do
        case $1 in
            -n | --no-wallpaper) do_wallpaper=0 ;;
            -A | --no-apply) do_apply=0 ;;
            -q | --quiet) do_print=0 ;;
            -o | --out)
                [[ ${2-} ]] || die "--out needs a directory"
                dest=$2
                shift
                ;;
            -m | --monitor)
                [[ ${2-} ]] || die "--monitor needs a name"
                main_output=$2
                shift
                ;;
            -H | --hook)
                [[ ${2-} ]] || die "--hook needs a shell, terminal or toolkit"
                hooks+=("$2")
                shift
                ;;
            -h | --help)
                usage
                return 0
                ;;
            --)
                shift
                args+=("$@")
                break
                ;;
            -*) die "unknown option: $1" ;;
            *) args+=("$1") ;;
        esac
        shift
    done

    set -- "${args[@]}"
    img=${1-}
    dest=$(realpath -m -- "$dest")
    local sh
    for sh in "${hooks[@]}"; do
        case $sh in
            bash | zsh | fish | kitty | foot | alacritty | ghostty | tmux | zathura | btop | gtk | qt) ;;
            *) die "unsupported hook: $sh ($HOOKS)" ;;
        esac
    done
    if [[ -z $img ]] && ((${#hooks[@]})); then
        for sh in "${hooks[@]}"; do
            install_hook "$sh" "$dest" || true
        done
        return 0
    fi
    if [[ -z $img ]]; then
        usage >&2
        return 1
    fi
    (($# == 1)) || die "unexpected argument: ${2-}"
    [[ -f $img ]] || die "file not found: $img"
    img=$(realpath -- "$img")

    need magick gawk

    if ((do_wallpaper)); then
        set_wallpaper "$img" "$main_output"
    fi

    local base=()
    mapfile -t base < <(read_base "$img")
    ((${#base[@]})) || die "no colors extracted from $img"
    while ((${#base[@]} < BASE)); do
        base+=("${base[-1]}")
    done

    local c=() hex
    c=("${base[@]}")
    for hex in "${base[@]}"; do
        c+=("$(brighten "$hex" "$COLORS_BRIGHTEN_PCT")")
    done

    local bg=${c[0]} fg cursor accent
    fg=$(printf '%s\n' "${c[@]}" | pick_contrasting "$bg")
    cursor=$fg
    accent=$(printf '%s\n' "${c[@]}" | pick_accent "$bg")
    local dim chip tile
    dim=$(printf '%s\n' "${c[@]}" | pick_dim "$bg")
    chip=$(mix "$bg" "$fg" 110)
    tile=$(mix "$bg" "$fg" 172)

    local ansi=() i
    mapfile -t ansi < <(ansi_hues "$bg" "$accent")
    ((${#ansi[@]} == 12)) || die "could not derive the ansi hues"
    for i in {0..5}; do
        c[i + 1]=${ansi[i]}
        c[i + 9]=${ansi[i + 6]}
    done
    c[8]=$dim

    out=$(mktemp -d -t "$PROG.XXXXXXXX")
    trap 'rm -rf -- "$out"' EXIT

    emit_colors
    emit_txt
    emit_sh
    emit_fish
    emit_json
    emit_sequences
    emit_kitty
    emit_foot
    emit_alacritty
    emit_ghostty
    emit_tmux
    emit_lua
    emit_css
    emit_gtk
    emit_btop
    emit_zathura
    emit_xresources
    emit_kde
    emit_qtct
    emit_shell_hooks

    mkdir -p -- "$dest"
    local f
    for f in "$out"/*; do
        mv -f -- "$f" "$dest/"
    done

    if ((do_apply)); then
        apply_sequences "$dest"
        if command -v tmux >/dev/null 2>&1; then
            tmux source-file -q "$dest/tmux.conf" >/dev/null 2>&1 || true
        fi
        if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v hyprctl >/dev/null 2>&1; then
            hyprctl reload >/dev/null 2>&1 || true
        fi
        sync_niri_border_color "$accent"
        sync_sway_border_color "$accent"
        sync_kde_colors "$dest/kdeglobals"
        sync_qtct
        reload_apps
    fi
    if ((do_print)); then
        print_swatches
    fi
    for sh in "${hooks[@]}"; do
        install_hook "$sh" "$dest" || true
    done

    return 0
}

main "$@"

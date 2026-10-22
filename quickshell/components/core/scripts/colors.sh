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

derives a 16-color palette from <image>, sets it as the wallpaper, and renders
the palette into templates under \$COLORS_DIR.

options:
  -n, --no-wallpaper   only generate templates, do not touch the wallpaper
  -A, --no-apply       do not push escape sequences to running terminals
  -q, --quiet          do not print the palette swatches
  -o, --out DIR        write templates to DIR instead of \$COLORS_DIR
  -m, --monitor NAME   wallpaper output to prefer (default: \$COLORS_MAIN_OUTPUT)
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

requires: bash, magick, gawk, awww, coreutils
templates:
  colors colors.txt colors.sh colors.fish colors.json sequences
  kitty.conf tmux.conf colors.lua colors.css gtk.css btop.theme
  zathurarc Xresources
EOF
}

need() {
    local miss=() b
    for b in "$@"; do
        command -v "$b" >/dev/null 2>&1 || miss+=("$b")
    done
    ((${#miss[@]} == 0)) || die "missing required command: ${miss[*]}"
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

luma601() {
    printf '%d' "$((
        299 * $(hex_channel "$1" 0) +
        587 * $(hex_channel "$1" 2) +
        114 * $(hex_channel "$1" 4)
    ))"
}

pick_contrasting() {
    gawk -v bg="$1" -v min="$COLORS_MIN_CONTRAST" '
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
        function mix(hex, target, t,    i, out, c) {
            out = "#"
            for (i = 2; i <= 6; i += 2) {
                c = strtonum("0x" substr(hex, i, 2))
                out = out sprintf("%02X", int(c + (target - c) * t + 0.5))
            }
            return out
        }
        BEGIN { best = ""; bestc = 0 }
        /^#[0-9A-Fa-f]{6}$/ {
            c = contrast($0, bg)
            if (c > bestc) { bestc = c; best = $0 }
        }
        END {
            if (best == "") { print bg; exit }
            if (bestc >= min) { print best; exit }
            target = (lum(bg) < 0.5) ? 255 : 0
            for (t = 0.05; t <= 1.0001; t += 0.05) {
                cand = mix(best, target, t)
                if (contrast(cand, bg) >= min) { print cand; exit }
            }
            print (target == 255) ? "#FFFFFF" : "#000000"
        }
    '
}

pick_accent() {
    gawk -v bg="$1" -v min="$COLORS_MIN_CONTRAST" -v minchroma="$COLORS_MIN_CHROMA" '
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
        function mix(hex, target, t,    i, out, c) {
            out = "#"
            for (i = 2; i <= 6; i += 2) {
                c = strtonum("0x" substr(hex, i, 2))
                out = out sprintf("%02X", int(c + (target - c) * t + 0.5))
            }
            return out
        }
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
            if (contrast(best, bg) >= min) { print best; exit }
            target = (lum(bg) < 0.5) ? 255 : 0
            for (t = 0.05; t <= 1.0001; t += 0.05) {
                cand = mix(best, target, t)
                if (contrast(cand, bg) >= min) { print cand; exit }
            }
            print (target == 255) ? "#FFFFFF" : "#000000"
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
    local bgb fgb
    bgb=$(hex_bare "$bg")
    fgb=$(hex_bare "$fg")

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
set fish_color_search_match --background=${b[8]}
set fish_color_selection --background=${b[8]}
set fish_color_status ${b[1]}
set fish_color_user ${b[10]}
set fish_color_valid_path --underline
set fish_pager_color_background $bgb
set fish_pager_color_completion $fgb
set fish_pager_color_description --background=${b[8]}
set fish_pager_color_prefix ${b[10]}
set fish_pager_color_progress ${b[8]}
set fish_pager_color_secondary_background $bgb
set fish_pager_color_secondary_completion $fgb
set fish_pager_color_secondary_description ${b[8]}
set fish_pager_color_secondary_prefix ${b[10]}
set fish_pager_color_selected_background --background=${b[8]}
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

emit_tmux() {
    cat > "$out/tmux.conf" <<EOF
set -g status-style "bg=$bg,fg=$fg"
set -g status-left-style "bg=$bg,fg=${c[4]}"
set -g status-right-style "bg=$bg,fg=${c[8]}"
set -g window-status-style "bg=$bg,fg=${c[8]}"
set -g window-status-current-style "bg=${c[8]},fg=$fg,bold"
set -g window-status-activity-style "bg=$bg,fg=${c[3]}"
set -g pane-border-style "fg=${c[8]}"
set -g pane-active-border-style "fg=$fg"
set -g message-style "bg=${c[8]},fg=$fg"
set -g message-command-style "bg=${c[8]},fg=$fg"
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
    } > "$out/gtk.css"
}

emit_btop() {
    cat > "$out/btop.theme" <<EOF
theme[main_bg]="$bg"
theme[main_fg]="$fg"
theme[title]="$fg"
theme[hi_fg]="${c[4]}"
theme[selected_bg]="${c[8]}"
theme[selected_fg]="$fg"
theme[inactive_fg]="${c[8]}"
theme[graph_text]="$fg"
theme[meter_bg]="${c[8]}"
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
set statusbar-bg        "${c[8]}"
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
set completion-highlight-bg "${c[8]}"
set completion-highlight-fg "$fg"
set recolor-lightcolor  "$bg"
set recolor-darkcolor   "$fg"
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

    if [[ -n $monitor ]] && command -v hyprctl >/dev/null 2>&1 &&
        hyprctl monitors 2>/dev/null | grep -q "Monitor $monitor "
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
            -h | --help)
                usage
                return 0
                ;;
            --)
                shift
                break
                ;;
            -*) die "unknown option: $1" ;;
            *) break ;;
        esac
        shift
    done

    img=${1-}
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

    out=$(mktemp -d -t "$PROG.XXXXXXXX")
    trap 'rm -rf -- "$out"' EXIT

    emit_colors
    emit_txt
    emit_sh
    emit_fish
    emit_json
    emit_sequences
    emit_kitty
    emit_tmux
    emit_lua
    emit_css
    emit_gtk
    emit_btop
    emit_zathura
    emit_xresources

    mkdir -p -- "$dest"
    local f
    for f in "$out"/*; do
        mv -f -- "$f" "$dest/"
    done

    if ((do_apply)); then
        apply_sequences "$dest"
        if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v hyprctl >/dev/null 2>&1; then
            hyprctl reload >/dev/null 2>&1 || true
        fi
    fi
    if ((do_print)); then
        print_swatches
    fi

    return 0
}

main "$@"

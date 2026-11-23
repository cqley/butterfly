#!/bin/sh
cmd=$1
shift

wifi() {
    nmcli -t -f UUID,TYPE connection show | while IFS=: read -r u t; do
        [ "$t" = 802-11-wireless ] || continue
        printf '%s\t%s\n' "$u" "$(nmcli -g 802-11-wireless.ssid connection show uuid "$u" | sed 's/\\\(.\)/\1/g')"
    done
}

case $cmd in
saved)
    wifi
    ;;
prune)
    ssid=$1
    [ -n "$ssid" ] || exit 0
    shift
    wifi | while IFS="$(printf '\t')" read -r u s; do
        [ "$s" = "$ssid" ] || continue
        case " $* " in *" $u "*) continue ;; esac
        nmcli connection delete uuid "$u" >/dev/null
    done
    ;;
abort)
    nmcli -t -f UUID,TYPE,STATE connection show --active | while IFS=: read -r u t s; do
        [ "$t" = 802-11-wireless ] && [ "$s" = activating ] && nmcli connection down uuid "$u" >/dev/null
    done
    sh "$0" prune "$@"
    ;;
eap)
    u=$1
    if [ -n "$u" ]; then
        nmcli connection modify uuid "$u" 802-1x.identity "$3" || exit 1
    else
        u=$(nmcli connection add type wifi con-name "$2" ssid "$2" wifi-sec.key-mgmt wpa-eap \
            802-1x.eap peap 802-1x.phase2-auth mschapv2 802-1x.identity "$3" | grep -oE '[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}')
        [ -n "$u" ] || exit 1
    fi
    exec nmcli --ask connection up uuid "$u"
    ;;
esac
true

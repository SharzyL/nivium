readonly COMMAND="$1"
readonly DEVICE="$2"
readonly ICON="$3"


readonly HIGH_POWER=80
readonly MID_POWER=50
readonly LOW_POWER=20

function show_polybar_icon() {
    if is_device_connected "$1"; then
        POWER="$(upower -d | awk "/${1}/" RS= | grep percentage | cut -d':' -f2 | xargs | cut -d'%' -f1)"

        if [ "$POWER" -gt "$MID_POWER" ]; then
            echo "%{U#27ae60}%{+u}${2} $POWER%%{-u}"  # safe
        elif [ "$POWER" -le "$MID_POWER" ] && [ "$POWER" -gt "$LOW_POWER" ]; then
            echo "%{U#8ABEB7}%{+u}${2} $POWER%%{-u}"  # secondary
        elif [ "$POWER" -le "$LOW_POWER" ]; then
            echo "%{U#A54242}%{+u}${2} $POWER%%{-u}"  # alert
        fi
    fi
}

function show_waybar_icon() {
    if is_device_connected "$1"; then
        POWER="$(upower -d | awk "/${1}/" RS= | grep percentage | cut -d':' -f2 | xargs | cut -d'%' -f1)"

        function emit_json() {
            local percentage="$1"
            local class="$2"
            echo "{\"text\": \"$percentage\", \"class\": \"$class\", \"percentage\": $percentage}"
        }

        if [ "$POWER" -ge "$HIGH_POWER" ]; then
            emit_json "$POWER" good
        elif [ "$POWER" -ge "$MID_POWER" ]; then
            emit_json "$POWER" normal
        elif [ "$POWER" -ge "$LOW_POWER" ]; then
            emit_json "$POWER" warning
        else
            emit_json "$POWER" critical
        fi
    fi
}

function is_device_connected() {
    upower -d | awk "/${1}/" | grep . >/dev/null
}

case $COMMAND in

    "--is_device_connected")
        is_device_connected "$DEVICE"
    ;;

    "--show_polybar_icon")
        show_polybar_icon "$DEVICE" "$ICON"
    ;;

    "--show_waybar_icon")
        show_waybar_icon "$DEVICE" "$ICON"
    ;;

    *)
        echo "No command specified."
        echo "Commands availaible"
        echo "--is_device_connected : return an exit code 0 if device connected or 1 if not"
        echo "--show_icon           : show the icon"
        exit 1
    ;;
esac


#!/bin/dash
# vim:ft=sh

# Kill all descendents on exit
trap 'exit' INT TERM
trap 'kill 0' EXIT

#########################################
#          _                   _ _      #
#  ___ _ _| |___ ___ ___ _ _ _| |_|___  #
# | . | | | |_ -| -_| .'| | | . | | . | #
# |  _|___|_|___|___|__,|___|___|_|___| #
# |_|                                   #
#########################################
# Pipewire-pulseaudio module;
#  * Only needs pactl (libpulse)
#  * Needs a instance of either 'sink' or 'source'
if [ -z "${instance}" ] || [ "${instance}" = 'default' ] ; then
    instance='sink'
fi

click_left () { # Left click action
    # Toggle mute
    /usr/bin/pactl "set-${instance}-mute" \
        "@DEFAULT_$(echo ${instance} | awk '{print toupper($0)}')@" toggle
}

# Middle mouse action
click_middle () { 
    if [ "${instance}" = 'source' ] ; then
        pipewire-pulse-sink.sh -s 
    elif [ "${instance}" = 'sink' ] ; then
        pipewire-pulse-sink.sh 
    fi
}

# Right mouse action
click_right () {
    ( flock --nonblock 7 || exit 7
        if [ -x '/usr/bin/pavucontrol' ] ; then
            /usr/bin/pavucontrol
        fi
    ) 7>"${SYSINFO_FLOCK_DIR}/${name}_${IDENTIFIER}_right" >/dev/null 2>&1 &
}

# Scroll up
scroll_up () {
    if [ "${instance}" = 'source' ] ; then
        pipewire-pulse-volume.sh -s -p 1
    elif [ "${instance}" = 'sink' ] ; then
        pipewire-pulse-volume.sh -p 1
    fi
}

# Scroll down
scroll_down () {
    if [ "${instance}" = 'source' ] ; then
        pipewire-pulse-volume.sh -s -p -r 1
    elif [ "${instance}" = 'sink' ] ; then
        pipewire-pulse-volume.sh -p -r 1
    fi
}

print_info () {
    feature=''
    suf=''
    _name="$(pactl --format=json info | jq --raw-output ".default_${instance}_name")"
    _info="$(pactl --format=json list "${instance}s" | \
        jq --raw-output 'map(select(.name == "'"${_name}"'")) | .[]')"
    # Mute and volume info
    _mute="$(echo "${_info}" | jq --raw-output '.mute')"
    _volm="$(echo "${_info}" | jq --raw-output \
        '.volume | [.[].value_percent] | map(.[:-1] | tonumber?) | add / length | ceil')"
    # Get active port, and it's type
    _port="$(echo "${_info}" | jq --raw-output '.active_port')"
    _ptyp="$(echo "${_info}" | jq --raw-output '.ports | map(select(.name == "'"${_port}"'")) | .[].type')"
    # Get icon name
    _icon="$(echo "${_info}" | jq --raw-output '.properties."device.icon_name"')"
    # Check if it's a bluetooth sink, adjust suffix
    echo "${_name}" | grep -q 'bluez' && suf=' '
    if [ "${instance}" = 'sink' ] ; then 
        # Determine icon for the sink, based on device.icon_name
        case "${_name}" in
            *"HDMI"*)                                                 pre="﴿ "                   ;;
            *"DualShock"*)                                            pre=" "                   ;;
            *)
                case "${_icon}" in
                    *usb*)                                            pre="禍 "                 ;;
                    *hdmi*)                                           pre="﴿ "                  ;;
                    *headset*)            [ "${_mute}" = 'false' ] && pre=" "  || pre=" "     ;;
                    *a2dp*)               [ "${_mute}" = 'false' ] && pre="﫽 " || pre="﫾 "    ;;
                    *hifi*|*stereo*)                                  pre="﫛 "                 ;;
                    *headphone*|*lineout*)[ "${_mute}" = 'false' ] && pre=" "  || pre="ﳌ "     ;;
                    *speaker*)            [ "${_mute}" = 'false' ] && pre="蓼 " || pre="遼 "    ;;
                    *network*)                                        pre="爵 "                 ;;
                    *)                    [ "${_mute}" = 'false' ] && pre="墳 " || pre="ﱝ "     ;;
                esac
                ;;
        esac
        # # Determine icon, based on active port type
        # case "${_ptyp}" in
        #     HDMI*)       if [ "${_mute}" = 'false' ] && pre="﴿ " || pre="﴿ " ;;
        #     Line*)      if [ "${_mute}" = 'false' ] && pre=" " || pre=" " ;;
        #     Headphones) if [ "${_mute}" = 'false' ] && pre=" " || pre="ﳌ " ;;
        #     *USB*)      if [ "${_mute}" = 'false' ] && pre=" " || pre=" " ;;
        #     Speaker)    if [ "${_mute}" = 'false' ] && pre="蓼 " || pre="遼 " ;;
        #     *)          if [ "${_mute}" = 'false' ] && pre="墳 " || pre="婢 " ;;
        # esac
    elif [ "${instance}" = 'source' ] ; then
        # Determine icon for the sink
        case "${_icon}" in
            audio-card-pci) [ "${_mute}" = 'no' ] && pre=" "  || pre=" " ;;
            camera-web-usb)                          pre="犯 "             ;;
            *)              [ "${_mute}" = 'no' ] && pre=" "  || pre=" " ;;
        esac
        # Check if it's a bluetooth source
        if echo "${_icon}" | grep -q 'bluez' ; then
            suf=' '
        else
            suf=''
        fi
    else
        empty_output
        exit 1
    fi
    txt="${_volm}"
    if [ "${_mute}" = 'true' ] ; then
        feature='mute'
    fi
    # Print string
    formatted_output
}
print_loop () {
    # Print once
    print_info || exit
    pactl subscribe 2>/dev/null | while read -r _line ; do
        if echo "${_line}" | grep --quiet --ignore-case "${instance}\|'change' on server #" ; then
            print_info
        fi
    done
}

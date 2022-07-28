#!/bin/dash
# vim:ft=sh
# Script to change pulseaudio default sink volume
#   Default behavior is to increase volume of the default sink
#   -r to decrease volume
#   -s to modulate source
#   -c to specify the channel name (default is the default channel)
#   -p for percentage to modulate (default 5)

_direction='+'
_interface='sink'
_amount='5'
_name=''
while getopts ":rsc:p:" option; do
    case "${option}" in
        r)  _direction='-'      ;;
        s)  _interface='source' ;;
        c)  _name="${OPTARG}"   ;;
        p)  _amount="${OPTARG}" ;;
        ?)  exit 1              ;;
    esac
done

# Get default interface name, if we are not given the name
if [ -z "${_name}" ] ; then
    _name="$(pactl --format=json info | jq --raw-output ".default_${_interface}_name")"
fi

# Modulate volume
pactl "set-${_interface}-volume" "${_name}" "${_direction}${_amount}%"

# Get maximum volume, and the value of the loudest channel
_info="$(pactl --format=json list "${_interface}s" | \
    jq --raw-output 'map(select(.name == "'"${_name}"'")) | .[]')"
_maxvol="$(echo "${_info}" | jq --raw-output '.base_volume.value')"
_curvol="$(echo "${_info}" | jq --raw-output '.volume | [.[].value] | max')"

# If the volume is above maximum; make it 100%
if [ "${_curvol}" -ge "${_maxvol}" ] ; then
    pactl "set-${_interface}-volume" "${_name}" '100%'
fi

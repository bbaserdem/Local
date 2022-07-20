#!/bin/dash
# This script refreshes backdrop of desktops when called
# Either say refresh; which then refreshes background,
# Or theme; which only grabs the correct themed wallpaper
# Or directory, which 

# Get rectangle information of the screen
_rect="$(xdpyinfo | awk '/dimensions/ {print $2;}')"
_x="$(echo "${_rect}" | sed 's|\([0-9]*\)x\([0-9]*\)|\1|')"
_y="$(echo "${_rect}" | sed 's|\([0-9]*\)x\([0-9]*\)|\2|')"

# Set a theme, or check if things are to be refreshed
_theme=''
_img=''
_oldimg="${XDG_CACHE_HOME}/xpaper/last_wallpaper"
_thisdir=''
if [ "${1}" = 'reload' ] && [ -f "${_oldimg}" ] ; then
    _img="${_oldimg}"
elif [ -n "${1}" ] ; then
    if [ -d "${1}" ] ; then
        _thisdir="${1}"
        if [ -n "${2}" ] ; then
            _theme="${2}"
        fi
    else
        _theme="${1}"
    fi
fi

imfind_dir () {
    find "${1}" -type f -a '(' \
        -iname "${_theme}*.jpg"  -o \
        -iname "${_theme}*.jpeg" -o \
        -iname "${_theme}*.png" ')' -print 2>/dev/null \
        | shuf -n 1 -
}

if [ -n "${_img}" ] ; then
    # Use old image if already loaded
    true
elif [ -n "${_thisdir}" ]; then
    # Do this on the asked directory if asked
    if [ -d "${_thisdir}/${_x}x${_y}" ] ; then
        _img="$(imfind_dir "${_thisdir}/${_x}x${_y}")"
    else
        _img="$(imfind_dir "${_thisdir}")"
    fi
elif [ -n "${SBP_XPAPER_DIR}" ] && [ -d "${SBP_XPAPER_DIR}" ]; then
    # Try to find image; if a dir is specified
    if [ -d "${SBP_XPAPER_DIR}/${_x}x${_y}" ] ; then
        _img="$(imfind_dir "${SBP_XPAPER_DIR}/${_x}x${_y}")"
    else
        _img="$(imfind_dir "${SBP_XPAPER_DIR}")"
    fi
else
    # If the dir is not specified; try to find one in other locations
    if [ -d "/usr/share/backgrounds/${_x}x${_y}" ] ; then
        _img="$(imfind_dir "/usr/share/backgrounds/${_x}x${_y}")"
    elif [ -d '/usr/share/backgrounds' ] ; then
        _img="$(imfind_dir '/usr/share/backgrounds')"
    elif [ -d "${HOME}/Pictures/Wallpapers/${_x}x${_y}" ] ; then
        _img="$(imfind_dir "${HOME}/Pictures/Wallpapers/${_x}x${_y}")"
    elif [ -d "${HOME}/Pictures/Wallpapers" ] ; then
        _img="$(imfind_dir "${HOME}/Pictures/Wallpapers")"
    fi
fi

if [ -z "${_img}" ] ; then
    echo "No image was found"
    exit 3
fi

# Save the background location, for quick setting in the future
if [ -n "${XDG_CACHE_HOME}" ] && [ -d "${XDG_CACHE_HOME}" ] ; then 
    mkdir -p "${XDG_CACHE_HOME}/xpaper"
fi
ln -sf "${_img}" "${XDG_CACHE_HOME}/xpaper/last_wallpaper"

# Set without using Xinerama
feh --no-fehbg --bg-scale --no-xinerama "${_img}"

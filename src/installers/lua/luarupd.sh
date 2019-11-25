#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Update the version of the 'luarocks' LuaRocks package
# ----------------------------------------------------------------------------
#

ERR_WARNING=0
ERR_USAGE=1
ERR_NOSUDO=2
ERR_CMDFAIL=4
ERR_UNSPEC=8
ERR_FILEIO=16
ERR_MISSING=32
ERR_BADSWITCH=64
ERR_CANCEL=128

X_Y_VERS_GREP="[[:digit:]]+[.][[:digit:]]+"
X_Y_Z_VERS_GREP="${X_Y_VERS_GREP}[.][[:digit:]]+"

EXTRA_SCRIPT_DIR_PATH="/usr/local/bin"

LUA_FIX_SCRIPT_NAME="luafix"
LUA_FIX_SCRIPT_PATH=${EXTRA_SCRIPT_DIR_PATH}/${LUA_FIX_SCRIPT_NAME}


############################################################################
#
# Throw an error
#
# $1 = Exit code (set to '0' for 'no exit')
# $2 = Name of the script throwing the error
# $3 = Name of the function/routine throwing the error (optional)
# $4 = Message string
#
ThrowError() {

if (( $# > 3 )); then
    printf "%s: %s: error: %s \n" "${2}" "${3}" "${4}" >&2
else
    printf "%s: error: %s \n" "${2}" "${3}" >&2
fi

# Exit the script if the error code is not ERR_WARNING:
#
(( ${1} != ERR_WARNING )) && exit ${1}
}


############################################################################
#
# Get the name of this script (for 'usage')
#
# $1 = Name of the calling script
# $2 = "unwind": Okay to unwind the link redirects
#
GetScriptName() {

local SCRIPT="${1}"

CORE_SCRIPT="${BASH_SOURCE[0]}"

if [[ ${2} == [uU]nwind ]]; then

    while [[ -h "${SCRIPT}" ]]; do
        SCRIPT="$( readlink -- "${SCRIPT}" )";
    done
fi

APP_SCRIPT=$( basename "${SCRIPT}" .sh )

SCRIPT_DIR=$( cd "$( dirname "${0}" )" && pwd )
}


############################################################################
#
# Determine the OS version
#
GetOSversion() {

ARCH=$( uname -m )

DISTRO=$( lsb_release -sc )
RELEASE=$( lsb_release -sr )

FLAVOR=Unity
lsb_release -sd | grep -q GalliumOS
(( $? == 0 )) && FLAVOR=xfce

MAJOR=$( lsb_release -sr | cut -d . -f 1 )
MINOR=$( lsb_release -sr | cut -d . -f 2 )

[[ -n "${ARCH}" && -n "${DISTRO}" && -n "${RELEASE}" && \
        -n "${MAJOR}" && -n "${MINOR}" ]] && return

ThrowError "${ERR_UNSPEC}" "${CORE_SCRIPT}" "${FUNCNAME}" \
        "Could not resolve OS version value !"
}


############################################################################
#
# Simple test to see if 'sudo' has already been obtained
#
# $1 = Optional string to indicate operation requiring 'sudo'
#
QualifySudo() {

local DIAGNOSTIC="Cannot run this script without 'sudo' privileges."

[[ -n "${1}" ]] && DIAGNOSTIC="This script requires 'sudo' privileges "${1}

sudo ls /root &>/dev/null

(( $? == 0 )) || ThrowError "${ERR_NOSUDO}" "${APP_SCRIPT}" "${DIAGNOSTIC}"
}


############################################################################

GetScriptName "${0}"

USAGE="
This script updates 'luarocks' for the current version of Lua/LuaRocks.
"

realpath "$( which lua 2>&1 )" 2>&1

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "Lua does not appear to be installed..?? "

realpath "$( which luarocks 2>&1 )" 2>&1

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "LuaRocks does not appear to be installed (for this version of Lua)..?? "

# Now we need to fixup the '/etc/alternatives' softlinks that the LuaRocks
# installer clobbers:
#
if [[ ! -x "${LUA_FIX_SCRIPT_PATH}" ]]; then

    ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Cannot find script '${LUA_FIX_SCRIPT_PATH}' ! "
fi

QualifySudo
sudo -H luarocks install luarocks

(( $? == 0 )) && eval "${LUA_FIX_SCRIPT_PATH}"

############################################################################

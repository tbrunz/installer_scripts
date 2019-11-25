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

LUAROCKS_PREFIX="/usr/local"
LUAROCKS_BIN_PATH="${LUAROCKS_PREFIX}/bin"

EXTRA_SCRIPT_DIR_PATH="/usr/local/bin"
ETC_ALTS_DIR_PATH="/etc/alternatives"

LUAROCKS_APP_SCRIPT_NAME="luarocks"
LUAROCKS_ADMIN_SCRIPT_NAME="luarocks-admin"
LUAROCKS_BUSTED_NAME="busted"

LUAROCKS_APP_SCRIPT_PATH=${LUAROCKS_BIN_PATH}/${LUAROCKS_APP_SCRIPT_NAME}
LUAROCKS_ADMIN_SCRIPT_PATH=${LUAROCKS_BIN_PATH}/${LUAROCKS_ADMIN_SCRIPT_NAME}
LUAROCKS_BUSTED_PATH=${LUAROCKS_BIN_PATH}/${LUAROCKS_BUSTED_NAME}

LUAROCKS_APP_LINK_PATH=${ETC_ALTS_DIR_PATH}/${LUAROCKS_APP_SCRIPT_NAME}
LUAROCKS_ADMIN_LINK_PATH=${ETC_ALTS_DIR_PATH}/${LUAROCKS_ADMIN_SCRIPT_NAME}
LUAROCKS_BUSTED_LINK_PATH=${ETC_ALTS_DIR_PATH}/${LUAROCKS_BUSTED_NAME}


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
This script fixes up the '/usr/local/bin' links for the current version of
Lua/LuaRocks/busted.
"

realpath "$( which lua 2>&1 )" 2>&1

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "Lua does not appear to be installed..?? "

realpath "$( which luarocks 2>&1 )" 2>&1

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "LuaRocks does not appear to be installed (for this version of Lua)..?? "

QualifySudo

# We need to fixup the '/etc/alternatives' softlinks that the LuaRocks
# installer clobbers; Find out which version is hard-coded:
#
LUA_VERSION=$( egrep -o "$( which lua )${X_Y_VERS_GREP}" \
  "${LUAROCKS_APP_SCRIPT_PATH}" | egrep -o "${X_Y_VERS_GREP}" )

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "Cannot parse the Lua version in '${LUAROCKS_APP_SCRIPT_PATH}' ! "

# Change each hard-coded script LuaRocks creates into a versioned script....

# Start with the LuaRocks application script:
#
sudo mv -f "${LUAROCKS_APP_SCRIPT_PATH}" \
  "${LUAROCKS_APP_SCRIPT_PATH}${LUA_VERSION}"

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
  "Cannot rename the '${LUAROCKS_APP_SCRIPT_PATH}' file ! "

sudo ln -sf "${LUAROCKS_APP_LINK_PATH}" "${LUAROCKS_APP_SCRIPT_PATH}"

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
  "Cannot create a softlink to '${LUAROCKS_APP_SCRIPT_PATH}${LUA_VERSION}' ! "

# Then the 'luarocks-admin' script:
#
sudo mv -f "${LUAROCKS_ADMIN_SCRIPT_PATH}" \
  "${LUAROCKS_ADMIN_SCRIPT_PATH}${LUA_VERSION}"

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
  "Cannot rename the '${LUAROCKS_ADMIN_SCRIPT_PATH}' file ! "

sudo ln -sf "${LUAROCKS_ADMIN_LINK_PATH}" "${LUAROCKS_ADMIN_SCRIPT_PATH}"

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
  "Cannot create a softlink to '${LUAROCKS_ADMIN_SCRIPT_PATH}${LUA_VERSION}' ! "

# Then the 'busted' rock -- if it's installed:
#
if [[ -x "${LUAROCKS_BUSTED_PATH}" ]]; then

  sudo mv -f "${LUAROCKS_BUSTED_PATH}" \
    "${LUAROCKS_BUSTED_PATH}${LUA_VERSION}"

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Cannot rename the '${LUAROCKS_BUSTED_PATH}' file ! "

  sudo ln -sf "${LUAROCKS_BUSTED_LINK_PATH}" "${LUAROCKS_BUSTED_PATH}"

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Cannot create a softlink to '${LUAROCKS_BUSTED_PATH}${LUA_VERSION}' ! "
fi

############################################################################

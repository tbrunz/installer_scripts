#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Lua "busted" from the LuaRocks repository & set alternatives
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
# Announce that installation is complete, then
# display a prompt to press a key to confirm
#
# $1 = '-n' to suppress the "press any key" prompt
# $1 = '-p' to only show the "press any key" prompt
#
InstallComplete() {

if [[ ${1} != "-p" ]]; then
    echo
    echo "Installation of the '${SET_NAME}' package set is complete. "
fi

if [[ ${1} != "-n" ]]; then

    read -r -s -n 1 -p "Press any key to continue. "
    echo
fi

[[ -n "${POST_INSTALL}" ]] && echo "${POST_INSTALL}"

exit 0
}


############################################################################
#
# Display a prompt asking a Yes/No question, repeat until a valid input
#
# Allows for a blank input to be defaulted.  Automatically appends "(y/n)"
# to the prompt, capitalized according to the value of DEF_INPUT
#
# $1 = Default input, (y|n|<don't care>)
# $2 = Prompt
#
# Returns 0 if Yes, 1 if No
#
Get_YesNo_Defaulted() {
    local DEFAULT=${1##-}
    local PROMPT=${2}

    DEFAULT=${DEFAULT,,}
    DEFAULT=${DEFAULT:0:1}

    case ${DEFAULT} in
    y )
        PROMPT=${PROMPT}" [Y/n] "
        ;;
    n )
        PROMPT=${PROMPT}" [y/N] "
        ;;
    * )
        PROMPT=${PROMPT}" "
        ;;
    esac

    unset REPLY
    until [[ "${REPLY}" == "y" || "${REPLY}" == "n" ]]; do

        read -e -r -p "${PROMPT}"

        if [[ -z "${REPLY}" ]]
        then
            REPLY=${DEFAULT}
        else
            REPLY=${REPLY:0:1}
            REPLY=${REPLY,,}
        fi
    done

    [[ "${REPLY}" == "y" ]]
}


############################################################################
#
# Move a file (i.e., rename) while making a backup of the target.
#
# Move the ${2} file (if it exists) to a backup (deleting the backup),
# then move (rename) the ${1} file to the name provided by ${2}.
#
Move_File_with_Backup () {

  QualifySudo
  if [[ -e "${2}" ]]; then
    #
    # File ${2} already exists...  Is it the same as ${1}?
    #
    diff "${1}" "${2}" &>/dev/null

    if (( $? == 0 )); then
      #
      # The files are the same, so no need for a backup copy:
      #
      sudo rm -f "${1}"
      return
    fi

    # The files are not the same, so back up ${2}; If ${2}
    # already has a backup, then clobber the backup:
    #
    sudo mv -f "${2}" "${2}.bak" &>/dev/null
  fi

  # Now there's no ${2}, so perform the "rename":
  #
  sudo mv -f "${1}" "${2}"
}


############################################################################
#
# Generic function to locate a file versioned by name
#
# Look in the same directory as ${1} for a file starting with ${2};
# If not found, try finding a path to ${2} via $PATH;
#
# Returns a full path in ${__FILE_VERS_PATH} & $? indicating success
#
function Find_File_Version () {

  local FILE_PATH=${1}
  local FILE_VERS=${2}

  local FILE_DIR
  local FILE_LIST

  # Start by looking in the same directory as the provided path argument
  # to find files beginning with "${FILE_VERS}":

  FILE_DIR=$( dirname "${FILE_PATH}" )

  FILE_LIST=$( find "${FILE_DIR}" -type f -iname "${FILE_VERS}*" )

  # There can be 0..n matches; we need 0 or 1, so take the first one
  # by recasting the newline-separated strings into an array of strings:
  #
  readarray -t FILE_LIST < <( printf "%s" "${FILE_LIST}" )

  # This will render as an empty string if there were 0 matches:
  #
  __FILE_VERS_PATH="${FILE_LIST[0]}"

  # If the file was not found above, then use $PATH; if this fails,
  # the result will be an empty string and $? will be "fail".
  #
  [[ -e "${__FILE_VERS_PATH}" ]] || __FILE_VERS_PATH=$( which "${FILE_VERS}" )
}


############################################################################
#
# Find the priority of a Debian Alternative; value sent to stdout
#
Find_App_Alt_Priority () {

  local APP_NAME=${1}  # lua-interpreter | luarocks    | busted
  local APP_VERS=${2}  # lua5.1          | luarocks5.1 | busted5.3

  local ALT_QUERY
  local ALT_DATA=()
  local ALT_LINE
  local STATE

  ALT_QUERY=$( update-alternatives --query "${APP_NAME}" 2>&1 )

  if (( $? == 0 )); then
    #
    # If the query succeeded, parse into an array of lines for analysis:
    #
    readarray -t ALT_DATA <<< "${ALT_QUERY}"

    # Start by searching the array for an "Alternative:" line with our version;
    # If we never find one, then this alternative is new, so use the priority
    # value passed to us as a parameter; otherwise use the existing priority;
    #
    STATE="search"
    for ALT_LINE in "${ALT_DATA[@]}"; do

      if [[ "${STATE}" == "search" ]]; then
        #
        # If this line has "Alternative:" and our version, switch to parsing:
        #
        printf "%s" "${ALT_LINE}" | grep "Alternative.*${APP_VERS}" &>/dev/null
        (( $? == 0 )) && STATE="parse"
      else
        # If not searching, then the last line was the target alternative;
        # Which means, this line has the "Priority:" value we need:
        #
        printf "%s" "${ALT_LINE}" | egrep -o "[[:digit:]]+$"

        (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
          "Cannot determine Priority for Debian Alternatives '${APP_NAME}' ! "
        break
      fi
    done
  else
    return ${ERR_MISSING}
  fi
}


############################################################################
#
# Generic function to create/update a Debian Alternative
#
function Update_App_Alts () {

  local QUIET=""
  if [[ "${1}" == "--quiet" ]]; then QUIET=${1}; shift; fi

  local APP_VERS=${1}  # lua5.1          | luarocks5.1
  local APP_NAME=${2}  # lua-interpreter | luarocks
  local APP_PATH=${3}  # /usr/bin/lua    | /usr/local/bin/luarocks
  local APP_PRTY=${4}  # 100

  local SLV_VERS=${5}  # lua5.1[.1.gz]   | luarocks-admin5.1
  local SLV_NAME=${6}  # lua-manual      | luarocks-admin
  local SLV_PATH=${7}  # /usr/share/man/man1/lua.1.gz | /u/l/b/luarocks-admin

  local APP_FILE       # --> /usr/bin/lua5.1
  local SLV_FILE       # --> /usr/share/man/man1/lua5.1.1.gz

  local ALT_SLV=()

  # See if this version of the application is in its alternatives list;
  # if so, then get its priority value; if not, use the default provided:
  #
  RESULT=$( Find_App_Alt_Priority "${APP_NAME}" "${APP_VERS}" )
  (( $? == 0 )) && APP_PRTY=${RESULT}

  # At this point, we must have a minimum of 4 parameters...
  #
  (( $# > 3 )) || ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" "${FUNCNAME}" \
    "API error: Must have 4 or 7 parameters; only $# provided ! "

  # Get the path to this particular version of the application,
  # and to its slave components:
  #
  Find_File_Version "${APP_PATH}" "${APP_VERS}" || \
    ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
      "Using '${APP_PATH}' as a hint, but cannot locate app '${APP_VERS}' "

  APP_FILE="${__FILE_VERS_PATH}"

  if [[ -n "${SLV_VERS}" ]]; then
    #
    # At this point, we must have 7 parameters...
    #
    (( $# > 6 )) || ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" "${FUNCNAME}" \
      "API error: Must have 4 or 7 parameters; only $# provided ! "

    Find_File_Version "${SLV_PATH}" "${SLV_VERS}" || \
      ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        " Using '${SLV_PATH}' as a hint; cannot locate file '${SLV_VERS}\*' "

    SLV_FILE="${__FILE_VERS_PATH}"

    # ${ALT_SLV} will interpolate as a blank string if not set
    #
    ALT_SLV=(
      "--slave"
      "${SLV_PATH}"
      "${SLV_NAME}"
      "${SLV_FILE}"
      )
  fi

  # Run the update-alternatives command to install the alternative:
  #
  QualifySudo
  sudo update-alternatives ${QUIET} --install "${APP_PATH}" "${APP_NAME}" \
    "${APP_FILE}" ${APP_PRTY} "${ALT_SLV[@]}"

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Cannot set '/etc/alternatives' for '${APP_NAME}' ! "
}


############################################################################
#
# Generic function to set a Debian Alternative
#
function Set_App_Alts () {

  local QUIET=""
  if [[ "${1}" == "--quiet" ]]; then QUIET=${1}; shift; fi

  local APP_NAME=${1}  # busted
  local APP_VERS=${2}  # busted5.3

  local APP_PATH       # --> /usr/local/bin/busted5.3
  #
  # First, get the path to the app that corresponds to the desired version:
  #
  APP_PATH=$( which "${APP_VERS}" )

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Cannot find '${APP_VERS}' in \$PATH to set as default version ! "

  QualifySudo
  sudo update-alternatives ${QUIET} --set "${APP_NAME}" "${APP_PATH}"

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Could not set the alternative for '${APP_NAME}' ! "
}


############################################################################
#
# Check to see if a (set of) 'glob' file names exist, and capture the names
#
# $1  = "basename" if only the basename is to be returned
# $2  = Source directory
# $3  = Depth of search
# $4+ = Source glob(s)
#
# Returns the file list in ${FILE_LIST[@]}, $?=0 if at least one exists
#
FindGlobFilename() {

local BASE_ONLY
local FILE_GLOB
local FILE_NAME
local RESULT

BASE_ONLY=${1}
shift

FILE_DIR=${1}
shift

DEPTH=${1}
shift

GLOB_LIST=( "$@" )
FILE_LIST=()

(( DEPTH < 1 )) && ThrowError "${ERR_BADSWITCH}" "${APP_SCRIPT}" \
        "Bad value for 'depth', '${DEPTH}' !"

#
# Loop once per glob in the provided list
#
RESULT=1
for FILE_GLOB in "$@"; do

    # Resolve the glob into an array of matching filenames:
    #
    while IFS= read -rd '' FILE_NAME; do

        if [[ ${BASE_ONLY,,} == "basename" ]]; then

            FILE_LIST+=( "$( basename ${FILE_NAME} )" )
            if [[ -f "${FILE_DIR}/${FILE_NAME}" ]]; then RESULT=0; fi
        else
            FILE_LIST+=( "${FILE_NAME}" )
            if [[ -f "${FILE_NAME}" ]]; then RESULT=0; fi
        fi

    done < <( find "${FILE_DIR}" -maxdepth ${DEPTH} -type f \
            -iname "${FILE_GLOB}" -print0 2>/dev/null )
done

return ${RESULT}
}


############################################################################
#
# Translate the source 'glob' name into the actual file name (required)
#
# $1 = "basename" if only the basename is to be returned
# $2 = Source directory
# $3 = Depth of search
# $4 = Source glob(s)
#
# Returns the file list in ${FILE_LIST[@]}
#
ResolveGlobFilename() {

FindGlobFilename "$@"

# If FindGlobFilename fails to find anything, only complain using the
# first file in the list provided -- hence ${GLOB_LIST} w/o the '[@]':
#
(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
        "Cannot find a file matching '${GLOB_LIST}' in '${FILE_DIR}' !"
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
############################################################################

GetScriptName "${0}"

SET_NAME="Lua Busted"

LUAROCKS_SCRIPT_NAME="luarocks"
LUAROCKS_PATH=$( which ${LUAROCKS_SCRIPT_NAME} )

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
    "Cannot find script '${LUAROCKS_PATH}' ! "

#
# Grep patterns
#
BUSTED_VERSION_GREP="[0-9]+[.][0-9]+"
LUA_VERSION_GREP="lua${BUSTED_VERSION_GREP}"

X_Y_VERS_GREP="[[:digit:]]+[.][[:digit:]]+"
X_Y_Z_VERS_GREP="${X_Y_VERS_GREP}[.][[:digit:]]+"

LUA_VERSION_SCRIPT="luavers"

BUSTED_BIN_PATH="/usr/local/bin"
BUSTED_APP_SCRIPT_NAME="busted"
BUSTED_APP_SCRIPT_PATH="${BUSTED_BIN_PATH}/${BUSTED_APP_SCRIPT_NAME}"

ALT_PRIORITY_APP_NAME="lua-interpreter"
ALT_PRIORITY_APP_PREFIX="lua"
ALT_PRIORITY_DEFAULT="100"

USAGE="
This script installs 'busted', the Lua unit testing 'rock', from the LuaRocks
package repository.

This script installs 'busted' for any of the 5.x versions from the LuaRocks
repository (but not version 5.0); however, it only installs the version
corresponding to the current active version of Lua.  (You can determine the
active version by running 'luavers'.)

After downloading and installing a particular version of 'busted', the script
sets its alternative in '/etc/alternatives' using the Debian Alternatives
mechanism.

http://www.lua.org/
https://luarocks.org/
"

POST_INSTALL="$( ${LUAROCKS_PATH} list )


You may want to install some of the other LuaRocks packages.

Some suggestions:
bit32  lualogging  luaposix  rings  luasocket  luaunit  luacheck
"

#
# Invoked with no parameters?
#
if [[ -z "${1}" ]]; then
  echo
  echo "usage: ${APP_SCRIPT} [ -u | -n | -i ] "
  echo
  echo "This script installs the '${SET_NAME}' package set. "
  echo
  echo "Options: "
  echo "    -u --update      = Update, then install "
  echo "    -n --noupdate    = Do not update, just install "
  echo "    -i --info        = Display post-install info "

  printf %s "${USAGE}"
  echo

  exit ${ERR_USAGE}
fi

#
# Invoked with the '-i' switch?
#
if [[ "${1}" == "-i" ]]; then

  echo "${USAGE}"
  if [[ -n "${POST_INSTALL}" ]]; then
      echo "-----"
      echo "${POST_INSTALL}"
  fi
  exit
fi

# Install all teh packages!!
#
eval sudo -H "${LUAROCKS_PATH}" install "${BUSTED_APP_SCRIPT_NAME}"

sudo rm -rf "${BUSTED_APP_SCRIPT_PATH}~"


# Change the hard-coded script that LuaRocks creates into a versioned
# script; We will use Debian Alternatives to manage these, just as
# the Lua interpreter/compiler & LuaRocks versions are managed.

# Extract the Lua version number from the script file:
#
[[ -r  "${BUSTED_APP_SCRIPT_PATH}" ]] || \
  ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "Could not resolve the Lua version for '${BUSTED_APP_SCRIPT_PATH}' ! "

BUSTED_VERSION=$( egrep -h -o "${LUA_VERSION_GREP}" \
  "${BUSTED_APP_SCRIPT_PATH}" | egrep -o "${BUSTED_VERSION_GREP}" )

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "Could not resolve the Lua version for '${BUSTED_APP_SCRIPT_PATH}' ! "

# Add the version number to the script name (to prevent collisions):
#
Move_File_with_Backup "${BUSTED_APP_SCRIPT_PATH}" \
  "${BUSTED_APP_SCRIPT_PATH}${BUSTED_VERSION}"

# Determine the version, then the priority of the corresponding Lua Interpreter,
# and use that as our priority.
#
LUA_CURRENT_PATH=$( realpath "$( which lua 2>&1 )" 2>&1 )

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "${SET_NAME} is dependent on Lua, which is not installed..?? "

LUA_VERSION=$( printf "%s" "${LUA_CURRENT_PATH}" | \
  egrep -o "${X_Y_VERS_GREP}" )

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "Cannot determine a Lua version from '${LUA_CURRENT_PATH}' "

# The Lua interpreter version had better match the busted version, or ...
#
[[ "${BUSTED_VERSION}" == "${LUA_VERSION}" ]] || \
  ThrowError "${ERR_UNSPEC}" "${APP_SCRIPT}" \
  "Lua version= ${LUA_VERSION}, but busted version= ${BUSTED_VERSION} ! "

# Now determine & match the corresponding app alternative priority:
#
APP_ALT_PRIORITY=${ALT_PRIORITY_DEFAULT}

RESULT=$( Find_App_Alt_Priority "${ALT_PRIORITY_APP_NAME}" \
  "${ALT_PRIORITY_APP_PREFIX}${BUSTED_VERSION}" )

if (( $? == 0 )); then
  APP_ALT_PRIORITY=${RESULT}
else
  ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
    "Could not determine the alt priority of the Lua interpreter ! "
fi

# Now create the '/etc/alternatives' database entry for this version:
#
Update_App_Alts "${BUSTED_APP_SCRIPT_NAME}${BUSTED_VERSION}" \
  "${BUSTED_APP_SCRIPT_NAME}" "${BUSTED_APP_SCRIPT_PATH}" \
  "${APP_ALT_PRIORITY}"

#
# Now that the version-specific Lua Busted package is installed,
# set up the '/etc/alternatives' to point to the version that matches
# the current version of Lua on our system:
#
# LUA_CURRENT_APP=$( basename "${LUA_CURRENT_PATH}" )
#
# (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
#   "Could not resolve the filename for '${LUA_CURRENT_PATH}' ! "
#
# LUA_CURRENT_VERSION=$( printf "%s" "${LUA_CURRENT_APP}" | \
#   egrep -o "${X_Y_VERS_GREP}")
#
# (( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
#   "Could not resolve the file version for '${LUA_CURRENT_PATH}' ! "

# Call 'update-alternatives' to configure the matching version:
#
Set_App_Alts "--quiet" "${BUSTED_APP_SCRIPT_NAME}" \
  "${BUSTED_APP_SCRIPT_NAME}${BUSTED_VERSION}"

POST_INSTALL="$( ${LUAROCKS_PATH} list )


You may want to install some of the other LuaRocks packages.

Some suggestions:
bit32  lualogging  luaposix  rings  luasocket  luaunit  luacheck
"

eval "${LUA_VERSION_SCRIPT}"

InstallComplete

############################################################################

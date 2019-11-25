#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Co-ordinate changing the current version of Lua
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

LUA_APP_NAME="Lua interpreter"
LUAC_APP_NAME="Lua compiler"
LUA_ROCKS_NAME="LuaRocks"
LUA_BUSTED_NAME="Busted"

LUA_PKG_PREFIX="lua"
LUAC_PKG_PREFIX="luac"
LUA_ROCKS_PREFIX="luarocks"
LUA_BUSTED_PREFIX="busted"

LUA_PREFIX="/usr/bin"
LUA_LIB_PREFIX="liblua"

LUA_INTERPRETER_GREP="${LUA_PREFIX}/${LUA_PKG_PREFIX}${X_Y_VERS_GREP}"
LUA_COMPILER_GREP="${LUA_PREFIX}/${LUAC_PKG_PREFIX}${X_Y_VERS_GREP}"

LIB_DEV_GREP="${X_Y_VERS_GREP}[^[:alpha:]]+dev"
LUA_LIBDEV_GREP="^${LUA_LIB_PREFIX}${LIB_DEV_GREP}"

LUAROCKS_PREFIX="/usr/local"
LUAROCKS_BIN_PATH="${LUAROCKS_PREFIX}/bin"

ETC_ALT_PRIORITY="100"

LUA_INTERPRETER_NAME="lua-interpreter"
LUA_COMPILER_NAME="lua-compiler"
LUAROCKS_ALT_NAME="luarocks"

LUAROCKS_APP_SCRIPT_NAME="luarocks"
LUAROCKS_ADMIN_SCRIPT_NAME="luarocks-admin"

LUAROCKS_APP_SCRIPT_PATH="${LUAROCKS_BIN_PATH}/${LUAROCKS_APP_SCRIPT_NAME}"
LUAROCKS_ADMIN_SCRIPT_PATH="${LUAROCKS_BIN_PATH}/${LUAROCKS_ADMIN_SCRIPT_NAME}"

BUSTED_APP_SCRIPT_NAME="busted"

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
GetYesNo_Defaulted() {

local PROMPT

case ${1} in
y | Y)
    PROMPT=${2}" [Y/n] "
    ;;
n | N)
    PROMPT=${2}" [y/N] "
    ;;
*)
    PROMPT=${2}" "
    ;;
esac

unset REPLY
while [[ ${REPLY} != "y" && ${REPLY} != "n" ]]; do

    read -e -r -p "${PROMPT}"
    [[ -z "${REPLY}" ]] && REPLY=${1}

    REPLY=${REPLY:0:1} && REPLY=${REPLY,,}
done

[[ ${REPLY} == "y" ]] && return
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

  local ALT_QUERY
  local ALT_DATA=()
  local ALT_LINE
  local ALT_SLV=()
  local STATE

  # See if this version of the application is in its alternatives list:
  #
  ALT_QUERY=$( update-alternatives --query "${APP_NAME}" 2>&1 )

  if (( $? == 0 )); then

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
        APP_PRTY=$( printf "%s" "${ALT_LINE}" | egrep -o "[[:digit:]]+$" )

        (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
          "Cannot determine Priority for Debian Alternatives '${APP_NAME}' ! "
        break
      fi
    done
  fi

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

  local APP_NAME=${1}  # lua-interpreter
  local APP_VERS=${2}  # lua5.1

  local APP_PATH       # --> /usr/bin/lua5.1
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
# Generic function to set a Debian Alternative
#
function Check_for_Repo_Package () {

  local APP_NAME=${1}
  local TARGET_VERSION=${2}
  local PKG_PREFIX=${3}
  local PKG_GREP=${4}

  local TARGET_PKG_LIST
  local TARGET_PACKAGE
  local TARGET_PKG_MSG

  # Check if the target version has an install package:
  #
  CACHE_SEARCH=$( \
    apt-cache search "${PKG_PREFIX}${TARGET_VERSION}" 2>&1 )

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Repo search on '${PKG_PREFIX}${TARGET_VERSION}': ${CACHE_SEARCH}"

  # If so, extract the package name; there might be more than one!
  #
  TARGET_PKG_LIST=$( printf "%s" "${CACHE_SEARCH}" | \
    egrep -o "^${PKG_GREP}" )
  RESULT=$?

  TARGET_PKG_MSG="and does not have a corresponding"

  if (( RESULT == 0 )); then
    #
    # In case there is more than one, sort them and take the first (shortest):
    #
    TARGET_PKG_LIST=$( printf "%s\n" "${TARGET_PKG_LIST}" | sort )
    read -r TARGET_PACKAGE <<< "${TARGET_PKG_LIST}"

    TARGET_PKG_MSG="but there is a '${TARGET_PACKAGE}'"
  fi

  printf "${APP_NAME} v${TARGET_VERSION} is not installed, "
  printf "${TARGET_PKG_MSG} package in the repository. \n"

  exit ${RESULT}
}


############################################################################

GetScriptName "${0}"

USAGE="
This script does such-and-such, with some of this-and-that.
"

LUA_TARGET_VERSION=${1}
shift

############################################################################
############################################################################
#
# Scan to determine which Lua versions are installed, which have a
# development package available in the repo, etc.
#
LUA_WHEREIS_LIST=( $( whereis ${LUA_PKG_PREFIX} ) )

for ITEM in "${LUA_WHEREIS_LIST[@]}"; do

  # Grep out a path to a Lua app; they may be more than one installed.
  #
  LUA_APP_PATH=$( printf "%s" "${ITEM}" | egrep -o ${LUA_INTERPRETER_GREP} )
  LUA_APP_NAME=$( basename "${LUA_APP_PATH}" )

  if (( $? == 0 )); then
    LUA_VERSION=$( printf "%s" "${LUA_APP_PATH}" | \
      egrep -o ${X_Y_VERS_GREP} )

    LUA_INSTALLED_PATHS+=( "${LUA_APP_PATH}" )
    LUA_INSTALLED_PKGS+=( "${LUA_APP_NAME}" )

    LUA_INSTALLED_VERSIONS+=( "${LUA_VERSION}" )
  fi
done

LUA_WHEREIS_LIST=( $( whereis ${LUAC_PKG_PREFIX} ) )

for ITEM in "${LUA_WHEREIS_LIST[@]}"; do

  # Grep out a path to a Lua app; they may be more than one installed.
  #
  LUAC_APP_PATH=$( printf "%s" "${ITEM}" | egrep -o ${LUA_COMPILER_GREP} )
  LUAC_APP_NAME=$( basename "${LUAC_APP_PATH}" )

  if (( $? == 0 )); then
    LUAC_INSTALLED_PATHS+=( "${LUAC_APP_PATH}" )
    LUAC_INSTALLED_PKGS+=( "${LUAC_APP_NAME}" )
  fi
done

# Parse and reform ${LUA_INSTALLED_VERSIONS} as a sorted/unique array:
#
LUA_VERSIONS=$( printf "%s\n" "${LUA_INSTALLED_VERSIONS[@]}" | sort | uniq )
readarray -t LUA_INSTALLED_VERSIONS <<< "${LUA_VERSIONS}"


############################################################################
#
# If no version number is provided as a parameter, show the current
# versions for lua-interpreter, lua-compiler, and luarocks:
#
if [[ -z "${LUA_TARGET_VERSION}" ]]; then

  LUA_INTERPRETER=$( realpath "$( which lua )" 2>/dev/null | \
    egrep -o "${X_Y_VERS_GREP}" )
  (( $? == 0 )) || LUA_INTERPRETER="<not installed>"

  LUA_COMPILER=$( realpath "$( which luac )" 2>/dev/null | \
    egrep -o "${X_Y_VERS_GREP}" )
  (( $? == 0 )) || LUA_COMPILER="<not installed>"

  LUA_ROCKS=$( realpath "$( which luarocks )" 2>/dev/null | \
    egrep -o "${X_Y_VERS_GREP}" )
  (( $? == 0 )) || LUA_ROCKS="<not installed>"

  LUA_BUSTED=$( realpath "$( which busted )" 2>/dev/null | \
    egrep -o "${X_Y_VERS_GREP}" )
  (( $? == 0 )) || LUA_BUSTED="<not installed>"

  RESULT=$( which luajit )
  (( $? == 0 )) && LUA_INSTALLED_VERSIONS+=( "luajit" )

  echo
  echo "Installed versions of Lua: "
  printf "   %s" "${LUA_INSTALLED_VERSIONS[@]}"
  echo
  echo
  echo "Lua Interpreter  = ${LUA_INTERPRETER} "
  echo "Lua Complier     = ${LUA_COMPILER} "
  echo "LuaRocks version = ${LUA_ROCKS} "
  echo "Lua Busted       = ${LUA_BUSTED} "
  echo

  exit
else
  # There's an argument, but is it a version (i.e., 'X.Y')??
  #
  LUA_VERSION_GREP1=$( printf "%s" "${LUA_TARGET_VERSION}" | \
    egrep "${X_Y_VERS_GREP}" 2>/dev/null )

  if (( $? == 0 )); then
    #
    # Reject any form of '*X.Y*' except just 'X.Y'...
    #
    LUA_VERSION_GREP2=$( printf "%s" "${LUA_TARGET_VERSION}" | \
      egrep -o "${X_Y_VERS_GREP}" 2>/dev/null )
  fi

  [[ -n "${LUA_VERSION_GREP1}" && \
    "${LUA_VERSION_GREP1}" == "${LUA_VERSION_GREP2}" ]] || \
      ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
        "usage: ${APP_SCRIPT} [<version, e.g., 5.1>] "
fi

# If 'luaX.Y' is not installed, check to see if it's in the repository
#
printf "%s " "${LUA_INSTALLED_PKGS[@]}" | \
  egrep -o "${LUA_PKG_PREFIX}${LUA_TARGET_VERSION}" &>/dev/null

if (( $? != 0 )); then
  Check_for_Repo_Package "${LUA_APP_NAME}" \
    "${LUA_TARGET_VERSION}" "${LUA_PKG_PREFIX}" \
    "${LUA_PKG_PREFIX}${LUA_TARGET_VERSION}"

  exit ${ERR_MISSING}
fi

# If 'luacX.Y' is not installed, check the repo, but continue
#
LUAC_INSTALLED=true
printf "%s " "${LUAC_INSTALLED_PKGS[@]}" | \
  egrep -o "${LUAC_PKG_PREFIX}${LUA_TARGET_VERSION}" &>/dev/null

if (( $? != 0 )); then
  Check_for_Repo_Package "${LUAC_APP_NAME}" \
    "${LUA_TARGET_VERSION}" "${LUAC_PKG_PREFIX}" \
    "${LUAC_PKG_PREFIX}${LUA_TARGET_VERSION}"

  unset LUAC_INSTALLED
fi

# Is 'luarocksX.Y' installed?
#
LUAROCKS_INSTALLED=true
RESULT=$( which "${LUA_ROCKS_PREFIX}${LUA_TARGET_VERSION}" )

if (( $? != 0 )); then
  echo "${LUA_ROCKS_NAME} v${LUA_TARGET_VERSION} is not installed. "

  unset LUAROCKS_INSTALLED
fi

# Is 'bustedX.Y' installed?
#
BUSTED_INSTALLED=true
RESULT=$( which "${LUA_BUSTED_PREFIX}${LUA_TARGET_VERSION}" )

if (( $? != 0 )); then
  echo "${LUA_BUSTED_NAME} v${LUA_TARGET_VERSION} is not installed. "

  unset BUSTED_INSTALLED
fi

# If something was missing, should we continue?
#
if [[ -z "${LUAC_INSTALLED}"   || -z "${LUAROCKS_INSTALLED}" || \
      -z "${BUSTED_INSTALLED}" ]]; then

  GetYesNo_Defaulted "y" "Continue?"
  (( $? == 0 )) || exit ${ERR_CANCEL}
fi

# We need to remove any pre-existing LuaRocks scripts from the 'bin'
# directory; if they're softlinks, the "--set" operation will replace
# them anyway.  If they're files, they were rewritten by LuaRocks
# updating itself (or being installed by other than the installer script).
#
sudo rm -rf "${LUAROCKS_APP_SCRIPT_PATH}"
sudo rm -rf "${LUAROCKS_ADMIN_SCRIPT_PATH}"

# Run 'update-alternatives' to set lua-interpreter, lua-compiler, luarocks
#
LUA_CURRENT_PATH=$( realpath $( which ${LUAC_PKG_PREFIX} ) )

LUA_CURRENT_APP=$( basename "${LUA_CURRENT_PATH}" )

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
  "Could not resolve the filename for '${LUA_CURRENT_PATH}' ! "

LUA_CURRENT_VERSION=$( printf "%s" "${LUA_CURRENT_APP}" | \
  egrep -o "${X_Y_VERS_GREP}")

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "Could not resolve the file version for '${LUA_CURRENT_PATH}' ! "

# Call 'update-alternatives' to configure the matching version:
#
Set_App_Alts "--quiet" "${LUA_INTERPRETER_NAME}" \
  "${LUA_PKG_PREFIX}${LUA_TARGET_VERSION}"

[[ ${LUAC_INSTALLED} ]] && Set_App_Alts "--quiet" \
  "${LUA_COMPILER_NAME}" "${LUAC_PKG_PREFIX}${LUA_TARGET_VERSION}"

[[ ${LUAROCKS_INSTALLED} ]] && Set_App_Alts "--quiet" \
  "${LUAROCKS_ALT_NAME}" "${LUAROCKS_APP_SCRIPT_NAME}${LUA_TARGET_VERSION}"

[[ ${BUSTED_INSTALLED} ]] && Set_App_Alts "--quiet" \
  "${LUA_BUSTED_PREFIX}" "${BUSTED_APP_SCRIPT_NAME}${LUA_TARGET_VERSION}"


############################################################################

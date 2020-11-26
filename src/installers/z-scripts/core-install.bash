#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Core script for the installers, containing common routines
# ----------------------------------------------------------------------------
#

#
# Functions:
#
#   ThrowError()
#       parameters = Exit code, Script Name, [Function/Routine], Message
#
#   trim(), maketmp() tar_zip() move() copy() chgdir() makdir() makdirin()
#       Expanded versions of these commands to add error handling for scripts
#
#   AddGroup()
#       parameters = groupname, 'addgroup' parameter list
#
#   InstallComplete()
#       parameters = <suppress 'press any key'?>
#
#   Get_YesNo_Defaulted()
#       parameters = Default answer, Prompt string
#       returns = 0 for Y, 1 for N
#
#   Move_File_with_Backup()
#       Move the ${1} file to the name provided by ${2} (backing it up)
#
#   Find_File_Version()
#       Return path to file ${1} using $PATH, else look in same dir as ${2}
#
#   Update_App_Alts()
#       Create/update an '/etc/alternatives' with 0 or 1 slave alternatives
#
#   Set_App_Alts()
#       Set a particular '/etc/alternatives' version for an app
#
#   Get_Config_File_Value()
#       Return a key's value from a config file
#
#   Set_Config_File_Value()
#       Set a key-value pair in a config file section
#
#   Load_Hosts_File()
#       Populates HOSTS_FILE
#
#   Local_Hostname_to_IP()
#       parameters = hostname
#       returns = ipv4 IP number
#
#   Local_IP_to_Hostname()
#       parameters = ipv4 IP number
#       returns = hostname
#
#   GetScriptName()
#       parameters = Script Name, <unwind?>
#       returns = APP_SCRIPT, SCRIPT_DIR
#
#   GetOSversion()
#       returns = ARCH, DISTRO, RELEASE, MAJOR, MINOR
#
#   QualifySudo()
#       (returns if 'sudo' use is obtained successfully)
#
#   FindGlobFilename()
#       parameters = Source Directory, Source Glob
#       returns = FILE_LIST[] in Source Directory, $?=0 if at least one exists
#
#   ResolveGlobFilename()
#       parameters = Source Directory, Source Glob
#       returns = FILE_LIST[] in Source Directory, exits if none found
#
#   BuildTextFile()
#       parameters = <replace?> <filepath> <list of line strings>
#       returns = 0 for no file written, 1 if the 'sources' file was written
#
#   PrepBackportConfig()
#       parameters = DISTRO, BACKPORT_DISTRO
#       returns = 0 for no file written, 1 for file was written
#       dependencies = BuildTextFile()
#
#   GetUserAccountInfo()
#       returns = USER_LIST[], UID_LIST[], GID_LIST[], HOME_LIST[]
#
#   ResolveBinarySwitch()
#       parameters = Switch text to parse
#       returns = 0 if Y, 1 if N, 2 if ambiguous
#
#   PerformAppInstallation()
#       parameters = APP_SCRIPT, SET_NAME, REPO_NAME, REPO_GREP, SIGNING_KEY,
#                   BACKPORT_DISTRO, PACKAGE_SET, DEB_PACKAGE, SHELL_SCRIPT
#       dependencies = GetScriptName(), PrepBackportConfig()
#

UID_MIN=1000
UID_MAX=65000

ERR_WARNING=0
ERR_USAGE=1
ERR_NOSUDO=2
ERR_CMDFAIL=4
ERR_UNSPEC=8
ERR_FILEIO=16
ERR_MISSING=32
ERR_BADSWITCH=64
ERR_CANCEL=128

DEB_INSTALLER="dpkg -i"

APT_DIR=/etc/apt
APT_SOURCES_FILE=sources.list
APT_SOURCES_DIR=${APT_DIR}/sources.list.d

APT_CONF_FILE=01ubuntu
APT_CONF_DIR=${APT_DIR}/apt.conf.d

BACKPORT_URL=http://archive.ubuntu.com/ubuntu/
BACKPORT_REPOS="main universe"

HOSTS_FILE=/etc/hosts
HOSTS_BASE=/etc/hosts-base
THIS_HOST=$( uname -n )

X_Y_VERS_GREP="[[:digit:]]+[.][[:digit:]]+"
X_Y_Z_VERS_GREP="${X_Y_VERS_GREP}[.][[:digit:]]+"

IP_CLASS_A_GREP="([[:digit:]]+[.]){1}"
IP_CLASS_B_GREP="([[:digit:]]+[.]){2}"
IP_CLASS_C_GREP="([[:digit:]]+[.]){3}"

IP_ADDR_GREP="${IP_CLASS_C_GREP}[[:digit:]]+"
IP_CIDR_GREP="${IP_ADDR_GREP}/[[:digit:]]+"

unset USAGE
unset POST_INSTALL

unset SET_NAME
unset REPO_NAME
unset REPO_URL
unset REPO_GREP
unset SIGNING_KEY
unset PACKAGE_SET
unset PKG_VERSION
unset DEB_PACKAGE
unset SHELL_SCRIPT
unset BACKPORT_DISTRO

unset USER_LIST
unset UID_LIST
unset GID_LIST
unset HOME_LIST

declare -a USER_LIST
declare -A UID_LIST
declare -A GID_LIST
declare -A HOME_LIST


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
# Test: Is this a ChromeOS or GalliumOS or Raspberry Pi platform?
#
unset IS_CHROME_OS
unset IS_GALLIUM_OS
unset IS_RASPBIAN_OS

RESULT=$( lsb_release -sd )

[[ "${RESULT}" =~ CHROMEOS  ]] && IS_CHROME_OS=true
[[ "${RESULT}" =~ GalliumOS ]] && IS_GALLIUM_OS=true
[[ "${RESULT}" =~ Raspbian  ]] && IS_RASPBIAN_OS=true

Exit_if_OS_is_not_ChromeOS() {
    [[ ! ${IS_CHROME_OS} ]] && ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
            "Must be in ChromeOS to run '${1}' ! "
}

Exit_if_OS_is_ChromeOS() {
    [[ ${IS_CHROME_OS} ]] && ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
            "Cannot run '${1}' in ChromeOS ! "
}

Exit_if_OS_is_not_GalliumOS() {
    [[ ! ${IS_GALLIUM_OS} ]] && ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
            "Must be in GalliumOS to run '${1}' ! "
}

Exit_if_OS_is_GalliumOS() {
    [[ ${IS_GALLIUM_OS} ]] && ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
            "Cannot run '${1}' in GalliumOS ! "
}


############################################################################
#
# Replace interior whitespace in a variable with another character
#
# $1 = ["<char>"]  default = "" (i.e., remove whitespace)
#
subspace () {

    local NEWCHAR=""
    local VARIABLE

    if (( $# == 0 )); then
        printf ""
        return
    fi

    if (( $# > 1 )); then
        NEWCHAR=${1}
        shift
        VARIABLE=$( printf "%s" "$*" | tr '[:blank:]' "${NEWCHAR}" )
    else
        VARIABLE=$( printf "%s" "$*" | tr -d '[:blank:]' )
    fi

    printf "%s" "${VARIABLE}"
}


############################################################################
#
# Trim whitespace from a variable: Leading, Trailing, Both, All
#
# $1 = ( -l | -t | -b | -a ) default = -b
#
trim ()
{
    local ACTION="-b"
    local VARIABLE

    if (( $# == 0 )); then
        printf ""
        return
    fi

    if (( $# > 1 )); then
        ACTION=${1}
        shift
    fi

    VARIABLE="$*"

    case ${ACTION} in
    -l)
        VARIABLE="${VARIABLE#"${VARIABLE%%[![:space:]]*}"}"
        ;;
    -t)
        VARIABLE="${VARIABLE%"${VARIABLE##*[![:space:]]}"}"
        ;;
    -a)
        VARIABLE=$( subspace "${VARIABLE}" )
        ;&
    -b)
        VARIABLE="${VARIABLE#"${VARIABLE%%[![:space:]]*}"}"
        VARIABLE="${VARIABLE%"${VARIABLE##*[![:space:]]}"}"
        ;;
    *)
        ThrowError "${ERR_BADSWITCH}" "${APP_SCRIPT}" "${FUNCNAME}" \
                "Unrecognized switch, '${ACTION}' ! "
        ;;
    esac

    printf "%s" "${VARIABLE}"
}


############################################################################
#
# Make a temporary file or directory
#
# $1 = ( -f | -d )  default = -f
#
maketmp() {

local SWITCH=""
local TYPE="file"

if [[ "${1}" == "-d" ]]; then
    SWITCH="-d"
    TYPE="directory"
fi

TMP_PATH=$( mktemp ${SWITCH} -q )
(( $? > 0 )) && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not create a ${TYPE} in '/tmp' ! "
}


############################################################################
#
# Untar a compressed tarball
#
# $1 = <zip type, (gz|bz)>
# $2 = tarball file
#
tar_zip() {

local ZIP_TYPE

case ${1} in
gz)
    ZIP_TYPE=z
    ;;
bz)
    ZIP_TYPE=j
    ;;
*)
    ZIP_TYPE=""
    ;;
esac

shift
sudo tar -${ZIP_TYPE}xf "$@"
(( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not untar file '${1}' ! "
}


############################################################################
#
# Move (mv) file or directory
#
# $1,$2 = (file|dir), (file|dir)
#
move() {

(( $# == 2 )) && sudo mv "${1}" "${2}"

(( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not 'mv' '${1}' to '${2}' ! "
}


############################################################################
#
# Copy files to a directory
#
# $1.. = file, file, file, directory
#
copy() {

sudo cp -rf "$@"
(( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not copy files to directory '${!#}' ! "
#
# Note that ${!#} is an indirect reference to $#, the number of positional
# parameters (arguments) used to call the function.  Hence, ${!#} is the
# value of the last positional parameter, which is the directory that the
# other (file) arguments will be copied into.
}


############################################################################
#
# Change to a directory
#
# $1 = Directory name
#
chgdir() {

cd "${1}"
(( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not 'cd' to directory '${1}' ! "
}


############################################################################
#
# Set the owner:group and permissions for a directory or a file
#
# $1 = Directory or file path (full or relative)
# $2 = 'chmod' value (empty for '755')
# $3 = 'chown' user (empty for 'root')
# $4 = 'chown' group (empty for same as user name)
#
SetDirPerms() {
local USER
local GROUP

if [[ -z "${2}" ]]; then
    sudo chmod 755 ${1}
else
    sudo chmod ${2} ${1}
fi

if [[ -z "${3}" ]]; then
    sudo chown root:root ${1}

elif [[ -z "${4}" ]]; then
    USER=$( printf "%s" "${3}" | cut -d ':' -f 1 )
    GROUP=$( printf "%s" "${3}" | cut -d ':' -f 2 )

    sudo chown ${USER}:${GROUP} ${1}
else
    sudo chown ${3}:${4} ${1}
fi
}


############################################################################
#
# Create a directory path (which may exist only partially)
#
# $1 = Directory path
# $2 = 'chmod' value (empty for '755')
# $3 = 'chown' value (empty for 'root')
#
makdir() {

local NEW_DIR
local NEXT_DIR

DIR="${1}"
[[ -z "${DIR}" ]] && ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
        "Cannot create the directory '${DIR}' !"

NEW_DIR=""
shift

if [[ -d "${DIR}" ]]; then
    SetDirPerms "${DIR}" "$@"
    return
fi

while [[ ! -d "${DIR}" ]]; do
    #
    # Back up the desired directory tree until we find the existing root;
    # Note that $NEW_DIR will be *backwards*, needed for the next part...
    #
    NEW_DIR=${NEW_DIR}/$( basename ${DIR} )
    DIR=$( dirname ${DIR} )
done

while [[ ${NEW_DIR} != "/" ]]; do
    #
    # Build the non-existing part, dir by dir, setting perms along the way...
    # Note that $DIR is the part of the final path that exists now:
    #
    NEXT_DIR=$( basename ${NEW_DIR} )
    NEW_DIR=$( dirname ${NEW_DIR} )
    DIR=${DIR}/${NEXT_DIR}

    sudo mkdir -p "${DIR}"
    (( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
            "Cannot create the directory '${DIR}' !"

    SetDirPerms "${DIR}" "$@"
done
}


############################################################################
#
# Create a directory within another directory
#
# $1 = Start directory
# $2 = Directory to create
# $3 = 'chmod' value (empty for '755')
# $4 = 'chown' value (empty for 'root')
#
makdirin() {

pushd "${1}" 1>/dev/null 2>&1
(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot change directory to '${1}' !"

shift
makdir "$@"

popd 1>/dev/null 2>&1
(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot return to original directory from '${1}' !"
}


############################################################################
#
# Add a group to the system, if it doesn't already exist
#
# $1   = group name
# $2.. = Remaining 'groupadd' parameters
#
AddGroup() {

local GROUP_NAME=${1}

sudo getent group ${GROUP_NAME} 1>/dev/null
(( $? == 0 )) && return

shift
sudo groupadd "$@" "${GROUP_NAME}"
(( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Cannot create the group '${GROUP_NAME}' !"
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
# Test to see if $1 is a member of $2
#
isSubString () {
    local SUB=${1}
    local STR=${2}

    [[ -z "${SUB}" ]] && return 0
    [[ -z "${STR}" ]] && return 1

    printf "%s" "${STR}" | grep -i "${SUB}" &>/dev/null
}


############################################################################
#
# Convert the argument from '-Xyz' to 'x', 'A' to 'a', '' to ''
#
GetOpt () {
    local OPT=${1}

    if [[ -n "${OPT}" ]]; then
        OPT=${OPT##-}
        OPT=${OPT,,}
        OPT=${OPT:0:1}
    fi

    printf "%s" "${OPT}"
}


############################################################################
#
# Display a prompt asking for a one-char response, repeat until a valid input
#
# Automatically appends the default to the prompt, capitalized.
# Allows for a blank input, which is interpreted as the default.
#
# $1 = Default input (-x | x) | List of options | Prompt
# $2 = list of [<options>] | Prompt
# $3 = Prompt
#
# Returns 0 if input==default, 1 otherwise
# The first character of the user's input, lowercased, goes into $REPLY
#
# GetUserChoice --> "Continue? [Y/n]"
# GetUserChoice "<prompt>" --> "<prompt> [Y/n]"
# GetUserChoice (y|n|-y|-n) "<prompt>" --> "<prompt> ([Y/n]|[y/N])"
#
# GetUserChoice "[<list>]" "<prompt>" --> "<prompt> [<list>]"
#     No default; requires an input in the list, returned in $REPLY
#
# GetUserChoice <def> "[<list>]" "<prompt>" --> "<prompt> [<list>]"
#     Defaulted input; requires an input in the list, returned in $REPLY
#
Get_YesNo_Defaulted () {
    local OPTIONS
    local DEFAULT="y"
    local PROMPT

    if (( $# == 0 )); then
        PROMPT="Continue?"

    elif (( $# == 1 )); then
        PROMPT=${1}

    elif (( $# == 2 )); then
        PROMPT=${2}
        DEFAULT=$( GetOpt "${1}" )

        if [[ "${DEFAULT}" == "[" ]]; then
            DEFAULT=
            OPTIONS=${1}
            OPTIONS=${OPTIONS##[}
            OPTIONS=${OPTIONS%%]}
        fi
    else
        PROMPT=${3}
        DEFAULT=$( GetOpt "${1}" )
        OPTIONS=${2}

        if [[ "${DEFAULT}" == "[" ]]; then
            DEFAULT=$( GetOpt "${2}" )
            OPTIONS=${1}
        fi

        OPTIONS=${OPTIONS##[}
        OPTIONS=${OPTIONS%%]}

        isSubString "${DEFAULT}" "${OPTIONS}"
        (( $? == 0 )) || DEFAULT=
    fi

    if [[ ${OPTIONS} ]]; then
        OPTIONS=${OPTIONS,,}

        if [[ ${DEFAULT} ]]; then
            OPTIONS=${OPTIONS/${DEFAULT}/${DEFAULT^}}
        fi

        PROMPT=${PROMPT}" [${OPTIONS}] "
    else
        case ${DEFAULT} in
        y )
            PROMPT=${PROMPT}" [Y/n] "
            ;;
        n )
            PROMPT=${PROMPT}" [y/N] "
            ;;
        * )
            PROMPT=${PROMPT}" [${DEFAULT^}]"
            ;;
        esac
    fi

    unset REPLY
    until [[ "${REPLY}" == "y" || "${REPLY}" == "n" ]]; do

        read -e -r -p "${PROMPT}"

        if [[ -z "${REPLY}" ]]
        then
            REPLY=${DEFAULT}
        else
            REPLY=$( GetOpt "${REPLY}" )
            [[ "${REPLY}" == "/" ]] && REPLY=
        fi

        if [[ ${OPTIONS} && -n "${REPLY}" ]]; then
            isSubString "${REPLY}" "${OPTIONS}"

            if (( $? == 0 )); then return
            else REPLY=
            fi
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

  local APP_NAME=${1}  # lua-interpreter | luarocks
  local APP_VERS=${2}  # lua5.1          | luarocks5.1

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
# Get a Key-Value pair from a config file.
#
# $1 = Path to config file
# $2 = Section string
# $3 = Key string
#
# Returns the key's value in the script variable ${KEY_VALUE}.
#
Get_Config_File_Value() {

# Parse the config file by treating the file as a set of
# "multi-line records", where each record is composed of a
# '# section #' plus a set of 'key=value' fields.
#
# If we can't parse the file, return "?";
# If we can't find the section, return "?";
# If we can't find the key-value pair, return "%";
# if we find the key, but the value is 'missing', return "";
# Otherwise, return the value associated with the key.
#
KEY_VALUE=$( awk '

    BEGIN { FS="\n"; RS="#"                     # Separate by sections
        Key_Value = "?"                         # Default response
    }

    $1 ~ Config_Section {                       # Is this OUR section?
        Key_Match = "[ \t]*" Section_Key "[ \t]*="

        for (Field=2; Field<=NF; Field++) {     # Step through fields

            if ($Field ~ Key_Match) {           # is this OUR key?
                if (split($Field, Token_ary, "[ \t]*=") > 1)
                    Key_Value = Token_ary[2]

                else Key_Value = ""
                exit                            # If was our key, done!
            }
        }
        Key_Value = "%"                         # No key in our section
        exit
    }

    END { printf("%s\n", Key_Value) }           # Return the key value

    ' Config_Section="${2}" Section_Key="${3}" "${1}" )
}


############################################################################
#
# Set a Key-Value pair in a config file.
#
# $1 = Path to config file
# $2 = Section string
# $3 = Key string
# $4 = Value string
#
Set_Config_File_Value() {

local CONFIG_FILE
local CONFIG_PERMS
local CONFIG_OWNER
local CONFIG_GROUP

# We want the owner and permissions of the replacement file
# to match the existing file.
#
CONFIG_FILE=$( basename "${1}" )
CONFIG_PERMS=$( stat -c %a "${1}" )
CONFIG_OWNER=$( stat -c %U "${1}" )
CONFIG_GROUP=$( stat -c %G "${1}" )

# Read the config file once again, this time actually copying it to
# 'stdout'; we copy it by "multi-line records", where each record
# is a [section] + 'key=value' lines.  When we reach our key,
# we replace it with a new line we generate on the spot...
#
# We *could* test the 'awk' call to ensure it completes w/o error...
#
maketmp

awk '
    BEGIN { FS="\n"; RS="#"; OFS="\n"           # Separate by sections
    }

    $1 ~ Config_Section {                       # Is this OUR section?
        Key_Match = "[ \t]*" Section_Key "[ \t]*="

        printf("#%s\n", $1)                    # Print section header

        for (Field=2; Field<=NF; Field++) {     # Step through fields
            if ($Field !~ Key_Match)            # Print if not ours

                if ($Field !~ "^[ \t]*$")       # Is field blank?
                    print $Field
        }

        printf("%s=%s\n", Section_Key, Key_Value)     # Write our K-V
        printf("\n")                            # Blank btw sections
        next                                    # Skip to next record
    }

    {   if ($1 ~ "#")                           # Section record?
            printf("#")                         # Splitting drops this

        for (Field=1; Field<NF; Field++)        # Step through fields
            print $Field                        # Output verbatim

        if ($NF !~ "^[ \t]*$")                  # Is last field blank?
            print $NF                           # No - print it, too
    }

    ' Config_Section="${2}" Section_Key="${3}" Key_Value="${4}" \
            "${1}" > ${TMP_PATH}

Move_File_with_Backup ${TMP_PATH} "${1}"

(( $? > 0 )) && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
            "Cannot rewrite the '${1}' file ! "

sudo chmod ${CONFIG_PERMS} "${1}"
sudo chown ${CONFIG_OWNER}:${CONFIG_GROUP} "${1}"
}


############################################################################
#
# Load the 'hosts' table into a string
#
Load_Hosts_File() {

# Already done?  Then we're done!
#
[[ -n "${HOSTS_TABLE}" ]] && return

# If there's a shorter 'base' version of the 'hosts' file, then use it:
#
[[ -r "${HOSTS_BASE}" ]] && HOSTS_FILE=${HOSTS_BASE}

# Reduce the hosts table to just valid 'IP..name' lines, for later use:
#
HOSTS_TABLE=$( egrep ^${IP_ADDR_GREP} ${HOSTS_FILE} )
}


############################################################################
#
# Resolve a hostname into its IP number from the 'hosts' table
#
# Inputs:  $1 = Host to resolve
# Depends: ${HOSTS_TABLE}
# Output:  0 if successful, 1 if not found
# Globals: ${IP_NUMBER}= The matched host's IP number
#
Local_Hostname_to_IP() {

local HOST_LINE
local HOST_NAME

# Pipe the 'hosts' file into the 'while' loop's 'read' function:
#
Load_Hosts_File

while read -r IP_NUMBER HOST_LINE; do
    #
    # Attempt to match each hostname in the line with the chosen host:
    #
    for HOST_NAME in ${HOST_LINE%%#*}; do
        #
        # If the hostname matches, we're done:
        #
        [[ ${HOST_NAME} == "${1}" ]] && return
    done

done < <( echo "${HOSTS_TABLE}" )

# If we're here, then nothing matched...
#
IP_NUMBER=""
return 1
}


############################################################################
#
# Reverse an IP number (local LAN) into the corresponding hostname
#
# Inputs:  $1 = IP number
# Depends: ${HOSTS_TABLE}
# Output:  0 if successful, 1 if not found
# Globals: Sets $HOSTNAMES[], ${HOST_NAME}= The matched IP's hostname
#
Local_IP_to_Hostname() {

local IP_NUMBER
local HOST_LINE
local THIS_HOSTNAME

HOSTNAMES=( )
SELECTED_HOST=""

# Search the hosts table to match the IP number:
#
Load_Hosts_File

while read -r IP_NUMBER HOST_LINE; do
    #
    # If the IP number matches, clip off any '#' + following text:
    #
    if [[ ${IP_NUMBER} == "${1}" ]]; then
        #
        # Then step through all the hostnames the rest might contain...
        #
        for THIS_HOSTNAME in ${HOST_LINE%%#*}; do

            HOSTNAMES+=( ${THIS_HOSTNAME} )
        done
    fi

done < <( echo "${HOSTS_TABLE}" )

# If we matched at least one, take the first one (it's as good as any...)
#
HOST_NAME=${HOSTNAMES}

# If the array is empty, then nothing matched...
#
(( ${#HOSTNAMES[@]} != 0 )) && return
return 1
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

lsb_release -sd | grep -qi gallium
(( $? == 0 )) && FLAVOR=xfce

lsb_release -sd | grep -qi stretch
(( $? == 0 )) && FLAVOR=chromeos

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
# Translate the source 'glob' name into the actual file name (check only)
#
# $1 = "basename" if only the basename is to be returned
# $2 = Source directory
# $3 = Depth of search
# $4 = Source glob(s)
#
# Returns the file list in ${FILE_LIST[@]}
#
CheckGlobFilename() {
local RESULT

FindGlobFilename "$@"
RESULT=$?

# Only throw a warning if $? was not 0; Warnings will not exit the script.
# If FindGlobFilename fails to find anything, only complain using the
# first file in the list provided -- hence ${GLOB_LIST} w/o the '[@]':
#
(( $RESULT == 0 )) || ThrowError "${ERR_WARNING}" "${APP_SCRIPT}" \
        "Cannot find a file matching '${GLOB_LIST}' in '${FILE_DIR}' !"

return $RESULT
}


############################################################################
#
# Create/replace a file and insert one or more lines of text
#
# $1   = "replace": Okay to overwrite the target file
# $2   = File to create
# $3.. = Strings to put in file
#
# Returns 0 if nothing was written, 1 if a file was written
#
BuildTextFile() {

local OVERWRITE_OKAY
local TARGET_FILE

[[ -z "${1}" || -z "${2}" || -z "${3}" ]] &&
    ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" "${FUNCNAME}" \
            "Insufficient number of parameters ($#; req 3 or more)"

OVERWRITE_OKAY=${1}
shift

TARGET_FILE=${1}
shift

[[ -e "${TARGET_FILE}" && "${OVERWRITE_OKAY}" != [rR]eplace ]] && return 0

# Must do this via a temp file due to 'sudo' complications...
#
QualifySudo
maketmp -f

# There can be more than one line to put in the file...
#
for FILE_LINE in "$@"; do
    printf "%s\n" "${FILE_LINE}" >> "${TMP_PATH}"
done

# Move the file into place (will be owned by 'root'):
#
copy "${TMP_PATH}" "${TARGET_FILE}"

# Discard the temp file (not critical if this fails):
#
sudo rm -f "${TMP_PATH}"

# Make sure it was created:
#
if [[ ! -e "${TARGET_FILE}" ]]; then

    ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" "${FUNCNAME}" \
            "Cannot create the file '${TARGET_FILE}' !"
else
    sudo chmod 644 "${TARGET_FILE}"
fi

return 1
}


############################################################################
#
# Configure APT to perform a backport package installation
#
# Returns 0 if nothing was written, 1 if a file was written
#
PrepBackportConfig() {

local APT_SOURCES_FILE=${APT_SOURCES_DIR}/${BACKPORT_DISTRO}.list

#
# Make our distro the default distro for apt updates:
#
BuildTextFile "replace" "${APT_CONF_DIR}/${APT_CONF_FILE}" \
    "APT::Default-Release ${DISTRO};"
#
# (We don't care if this previous file was (re-)written or not...)

#if [[ -e "${APT_SOURCES_FILE}" ]]; then return; fi

#
# Add the 'sources.list' file for the backport version
#
BuildTextFile "noreplace" "${APT_SOURCES_FILE}" \
    "deb ${BACKPORT_URL} ${BACKPORT_DISTRO} ${BACKPORT_REPOS}" \
    "deb-src ${BACKPORT_URL} ${BACKPORT_DISTRO} ${BACKPORT_REPOS}"

# Return code indicates if the 'sources' file was written:
#
return $?
}


############################################################################
#
# If 'apt-add-repository' surreptitiously tries to add a 'deb-src' repo,
# then yank it back out again -- unless we specifically asked for it.
#
# $1 = The URL of the repository we intended to create
#
Remove_Illicit_Source_Repo () {

local RESULT

RESULT=$( printf %s "${1}" | egrep '\<deb-src\>' )

# If the URL is a 'deb-src' repo, then it's intentional:
#
[[ -n "${RESULT}" ]] && return

# Otherwise, convert it to a 'deb-src' repo and try to remove it:
#
RESULT=$( printf %s "${1}" | sed -r -e '/\<deb\>/ s/deb/deb-src/' )

[[ ${RESULT} == "${1}" ]] && return

QualifySudo
which apt-add-repository &>/dev/null
(( $? == 0 )) || sudo apt-get install -y software-properties-common

sudo apt-add-repository -r -y "${RESULT}" >/dev/null 2>&1
}


############################################################################
#
# Get lists of {account names, UID:GID, home dirs} of the system users
#
GetUserAccountInfo() {

local USER
local THIS_UID
local THIS_GID
local USER_HOME

#
# Scan the password file & extract info for the non-system UIDs (i.e., 1000+):
#
while IFS=: read -r USER _ THIS_UID THIS_GID _ USER_HOME _; do

    if (( THIS_UID >= ${UID_MIN} && THIS_UID <= ${UID_MAX} )); then

        USER_LIST+=( ${USER} )
        UID_LIST[${USER}]=${THIS_UID}
        GID_LIST[${USER}]=${THIS_GID}
        HOME_LIST[${USER}]=${USER_HOME}
    fi
done < /etc/passwd

NUM_USERS=${#USER_LIST[@]}

[[ ${NUM_USERS} -gt 0 && \
    ${#UID_LIST[@]} -eq ${NUM_USERS} && \
    ${#GID_LIST[@]} -eq ${NUM_USERS} && \
    ${#HOME_LIST[@]} -eq ${NUM_USERS} ]] && return

ThrowError "${ERR_UNSPEC}" "${CORE_SCRIPT}" "${FUNCNAME}" \
        "Could not obtain consistent user account data !"
}


############################################################################
#
# Determine if a switch is t/f, y/n, 1/0, etc.
#
# $1 = Switch text to parse
# Allows "yes", "-y", "--yes", etc.
#
# Returns 0 if Y, 1 if N, 2 if ambiguous
#
ResolveBinarySwitch() {

local ARGUMENT

#
# Convert the parameter to all lower case, and shorten it to first 5 letters:
#
ARGUMENT=${1,,}
ARGUMENT=${ARGUMENT:0:5}

#
# Check to see if it fits '-f' or '--xxx' forms (i.e., starts with '-'):
#
if [[ ${ARGUMENT:0:1} == '-' ]]; then

    if [[ ${ARGUMENT:1:1} == '-' ]]; then

        # It's in the form of '--fxx', a Long form switch; discard the '--':
        ARGUMENT=${ARGUMENT:2:3}
    else
        # Else it's in the form of '-f', a Short form switch; capture 'x':
        ARGUMENT=${ARGUMENT:1:1}
    fi
else
    ARGUMENT=${ARGUMENT:0:3}
fi

#
# Evaluate: First thing that matches, we're done...
#
case ${ARGUMENT} in

"tru" | "yes" | "on" | "1" | "t" | "y" )
    return 0
    ;;

"fal" | "no" | "off" | "0" | "f" | "n" )
    return 1
    ;;
esac

# No match := Ambiguous result
#
return 2
}


############################################################################
#
# Parse command line switches & peform the installation steps
#
# $1 = Command line switch for application installation script
#
PerformAppInstallation() {

unset INSTALL
unset UPDATE
unset PPA
unset EXTRA_SWITCH
unset RET_WHEN_DONE

local PACKAGE

#
# '-r' means "Return without running InstallComplete"
#
if [[ ${1} == "-r" ]]; then
    shift
    RET_WHEN_DONE=true
fi

#
# Convert the switch to all lower case, and shorten it:
#
SWITCH=${1,,}
SWITCH=${SWITCH:0:5}
shift

#
# Capture additional switch(es) after the main switch:
#
EXTRA_SWITCH=${1,,}
shift

if [[ -n "${EXTRA_SWITCH}" ]]; then
    #
    # Only additional switches of the form of '--reinstall' are allowed;
    # Clip off the '--' & limit to three (lowercase) characters:
    #
    if [[ ${EXTRA_SWITCH:0:2} != "--" ]]; then SWITCH=""; fi
    EXTRA_SWITCH=${EXTRA_SWITCH:2:3}
fi

#
# Decide how to install:
# NOTE: ';&' means "go on to execute the next case block", while ';;&' means
# "continue testing with the next case (as though a match hadn't occurred)".
#
case ${SWITCH} in

"-u" | "--upd")
    UPDATE=true
    ;&

"-n" | "--nou")
    INSTALL=true
    ;;

"-p" | "--ppa")
    [[ -n "${REPO_NAME}" ]] && PPA=true
    ;;

"-a" | "--apt")
    echo "REPO_NAME = '${REPO_NAME}' "
    echo "REPO_URL  = '${REPO_URL}' "
    echo "REPO_GREP = '${REPO_GREP}' "
    exit
    ;;

"-i" | "--inf")
    echo "${USAGE}"
    if [[ -n "${POST_INSTALL}" ]]; then
        echo "-----"
        echo "${POST_INSTALL}"
    fi
    exit
    ;;
esac

#
# Strip out any '%section name:%' substrings for package installation...
# ...then tokenize to strip out the newlines & extraneous spaces:
#
if [[ -n "${PACKAGE_SET}" ]]; then
    PACKAGE_SET=$( printf %s "${PACKAGE_SET}" | sed -e 's/%[^%]*%/ /g' )
    PACKAGE_SET=$( echo ${PACKAGE_SET} )
fi

#
# Display the 'usage' prompt (-h)?
#
if [[ ${SWITCH} == "-h" || ${SWITCH} == "--hel" ||
        -z "${PPA}${UPDATE}${INSTALL}" ]]; then

    if [[ ${PKG_VERSION} = *.*.* ]]; then
        VERS_FORM=" X.Y.Z     "
    elif [[ ${PKG_VERSION} = *.* ]]; then
        VERS_FORM="  M.N      "
    else
        VERS_FORM=" <version> "
    fi

    echo
    echo -n "usage: ${APP_SCRIPT} "

    [[ -n "${PKG_VERSION}" ]] && echo -n "[ $( printf %s ${VERS_FORM} ) ] "

    if [[ -n "${REPO_NAME}" ]]; then
        echo "[ -p | -u | -n | -i ] "
    else
        echo "[ -u | -n | -i ] "
    fi

    echo
    echo "This script installs the '${SET_NAME}' package set. "
    echo
    echo "Options: "

    if [[ -n "${PKG_VERSION}" ]]; then
        echo -n "   ${VERS_FORM}       = "
        echo    "Version to install (e.g., ${PKG_VERSION}) "
    fi

    if [[ -n "${REPO_NAME}" ]]; then
        echo "    -p --ppa         = Add/remove PPA only; don't install "
        echo "    -u --update      = Add PPA, update, then install "
    else
        echo "    -u --update      = Update, then install "
    fi

    echo "    -n --noupdate    = Do not update, just install "
    echo "    -i --info        = Display post-install info "

    if [[ -n "${REPO_NAME}" ]]; then
        echo
        echo "The PPA '-p' command includes these additional options: "
        echo "       --reinstall   = Attempt to install the PPA unconditionally "
        echo "       --remove      = Remove the PPA, but keep any installed pkgs "
        echo "       --purge       = Remove the PPA, revert updated packages "
    fi

    [[ -n "${USAGE}" ]] && printf %s "${USAGE}"
    echo

    exit ${ERR_USAGE}
fi

#
# Download & install a package signing key?
#
if [[ -n "${SIGNING_KEY}" ]]; then

    # There are three forms of this... Which one are we given?
    #
    QualifySudo

    if [[ "${SIGNING_KEY:0:4}" == "http" ]]; then

        wget "${SIGNING_KEY}" -O- | sudo apt-key add -

    elif [[ "${SIGNING_KEY:0:4}" == "adv " ]]; then

        sudo apt-key ${SIGNING_KEY}
    else
        sudo apt-key add "${SIGNING_KEY}"
    fi

    (( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
            "Could not add the signing key for '${SET_NAME}' !"
    echo
    echo "Added '${SET_NAME}' signing key... "
    sleep 2
    echo
fi

#
# Install a PPA/Repository?
#
if [[ -n "${REPO_NAME}" ]]; then

    # Test to see if the PPA/respository source file is present:
    #
    RESULT=$( cat ${APT_DIR}/*.list ${APT_SOURCES_DIR}/*.list 2>/dev/null | \
            grep -v '^#' | grep -v '^[ \t]*$' | grep "${REPO_GREP}" )

    # If no 'grep' string is provided, or, if one is, but the PPA/repo
    # has not yet been installed, then add the PPA/repository:
    #
    if [[ -z "${REPO_GREP}" || -z "${RESULT}" ]]; then

        case ${EXTRA_SWITCH} in
        "pur" | "rem" )
            ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
                    "This PPA isn't installed -- nothing to do !"
            ;;
        "rei" | "" )
            QualifySudo
            echo "Installing repository '${REPO_NAME}'... "
            ;;
        * )
            QualifySudo
            echo "Installing; extra argument is ignored... "
            sleep 2
            ;;
        esac

        QualifySudo
        which apt-add-repository &>/dev/null
        (( $? == 0 )) || sudo apt-get install -y software-properties-common

        sudo apt-add-repository -y "${REPO_URL}"

        (( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
                "Could not add repository '${REPO_NAME}' !"

        Remove_Illicit_Source_Repo "${REPO_URL}"
        echo
        echo "Added repository '${REPO_NAME}'... "
        sleep 2
        echo

    elif [[ -z "${EXTRA_SWITCH}" ]]; then

        if [[ ${INSTALL} != true ]]; then
            echo "Repository '${REPO_NAME}' is already installed ! "
            echo
            sleep 1
        fi

    else
        # If the string is provided, and the PPA/repo is already installed,
        # then see if we should purge it, remove it, or re-install it:
        #
        QualifySudo
        case ${EXTRA_SWITCH} in

        "pur")
            echo "Purging repository '${REPO_NAME}'... "
            sleep 2
            sudo ppa-purge "${REPO_URL}"

            (( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
                    "Could not purge repository '${REPO_NAME}' !"

            echo
            echo "Repository '${REPO_NAME}' has been purged. "
            ;;
        "rem")
            echo "Removing repository '${REPO_NAME}'... "
            sleep 2

            which apt-add-repository &>/dev/null
            (( $? == 0 )) || sudo apt-get install -y software-properties-common

            sudo apt-add-repository -r -y "${REPO_URL}"

            (( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
                    "Could not remove repository '${REPO_NAME}' !"

            echo "Repository '${REPO_NAME}' has been removed. "
            ;;
        "rei")
            echo "Re-installing repository '${REPO_NAME}'... "
            sleep 2

            which apt-add-repository &>/dev/null
            (( $? == 0 )) || sudo apt-get install -y software-properties-common

            echo "Removing repository '${RESULT}'... "
            [[ -z "${RESULT}" ]] || sudo apt-add-repository -r -y "${RESULT}"

            (( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
                    "Could not remove repository '${RESULT}' !"

            echo "Installing repository '${REPO_URL}'... "
            sudo apt-add-repository -y "${REPO_URL}"

            (( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
                    "Could not add repository '${REPO_NAME}' !"

            Remove_Illicit_Source_Repo "${REPO_URL}"
            ;;
        *)
            ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
                    "Invalid argument, '${EXTRA_SWITCH}' !"
            ;;
        esac
    fi

    # We're done if the user only wants the PPA/repo installed...
    #
    [[ -n "${PPA}" ]] && return
fi

#
# Backport a package set from a later release?
#
if [[ -n "${BACKPORT_DISTRO}" ]]; then

    PACKAGE_SET="-t ${BACKPORT_DISTRO} ${PACKAGE_SET}"
    PrepBackportConfig

    # 'PrepBackportConfig' returns >0 if a file was written...
    #
    if (( $? > 0 )); then
        echo
        echo "Added '${BACKPORT_DISTRO}' repository... "
        sleep 2
        echo
        UPDATE=true
    fi
fi

#
# Update the package list?
#
if [[ -n "${UPDATE}" ]]; then

    QualifySudo
    sudo apt-get update

    if (( $? > 0 )); then

        echo
        Get_YesNo_Defaulted "y" \
                "Errors detected with package update.. Continue?"

        (( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
                "Could not update the repository package list !"
    fi
fi

#
# Install a repository package set?
#
if [[ -n "${INSTALL}" && -n "${PACKAGE_SET}" ]]; then

    # Remove packages that are already installed and packages that are not in
    # the repositories.  Otherwise, they'll be marked "manually installed"...
    #
    if [[ -n "${PACKAGE_SET}" ]]; then

        PACKAGE_SET="  ${PACKAGE_SET}  "
        echo -n "Checking packages: "

        for PACKAGE in ${PACKAGE_SET}; do

            # If the parameter is a switch (starts with '-'), then leave it
            # in the list -- but don't try to check it:
            #
            RESULT=$( printf %s "${PACKAGE}" | grep '^[-]' )
            (( $? == 0 )) && continue

            RESULT=$( dpkg -s "${PACKAGE}" 2>/dev/null )
            if (( $? > 0 )); then

                # The package is not installed; does it exist?
                # Before checking, clip off any ":i386", etc.
                #
                BASE_PKG=${PACKAGE%:*}
                RESULT=$( apt-cache search "${BASE_PKG}" 2>/dev/null \
                        | grep "^${BASE_PKG}" )
            else
                unset RESULT
            fi
            echo -n "*"

            # If the package is not installed AND is not missing in the repo,
            # then we can leave it in the list; else we must remove it...
            #
            [[ -n "${RESULT}" ]] && continue

            PACKAGE_SET=$( printf %s "${PACKAGE_SET}" | \
                    sed -e "s/ ${PACKAGE} / /" )
        done
    fi
    echo

    QualifySudo
    sudo apt-get install -y ${PACKAGE_SET}

    if (( $? > 0 )); then
        echo
        echo "${PACKAGE_SET}"
        echo
        ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
            "Could not install the repository package set !"
    fi
fi

#
# Install one or more Debian packages?  (Must follow repo package installs)
#
if [[ -n "${INSTALL}" && -n "${DEB_PACKAGE}" ]]; then

    # The packages (files) are actually a list (array)...
    #
    QualifySudo
    if [[ ${DEB_INSTALLER} == "gdebi" ]]; then

        which gdebi 1>/dev/null

        if (( $? > 0 )); then
            sudo apt-get install -y gdebi

            (( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
                "Could not install the 'gdebi' package !"
        fi
    fi

    sudo ${DEB_INSTALLER} "${FILE_LIST[@]}"
#    (( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
#            "Could not install the debian package set !"
fi

#
# Install via a shell script or binary executable? (Needs revision!)
#
if [[ -n "${INSTALL}" && -n "${SHELL_SCRIPT}" ]]; then

    for SCRIPT in "${FILE_LIST[@]}"; do

        QualifySudo
        echo
        echo "Invoking 'bash ${SCRIPT}'... "

        sudo bash "${SCRIPT}"
#        (( $? > 0 )) && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
#            "Could not install the bash script set !"
    done
fi

#
# Did we do an install?
#
[[ -n "${RET_WHEN_DONE}" ]] && return

[[ -n "${INSTALL}" ]] && InstallComplete
}


############################################################################

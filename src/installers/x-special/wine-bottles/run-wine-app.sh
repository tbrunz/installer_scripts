# #! /usr/bin/env bash
#
# Launch or edit a Wine application in a Wine bottle. 
#
SCRIPT_VERSION=1.0

# Get the basename of this script, and use it to make the data file name:
#
SCRIPT_NAME=$( basename ${0} .sh )

#
# The key environment variables come from a DAT file, whose name is 
# derived from the name of this script.
#
DATABASE_NAME=${SCRIPT_NAME}.dat

#
# A Wine prefix requires an absolute path...  Get it from this script's path:
#
WINE_BOTTLE_ROOT=$( dirname "${0}" )

#
# If first arg is a switch, show the usage prompt:
# 
if [[ "${1:0:1}" == "-" ]]; then
    
    echo >&2 "${SCRIPT_NAME}.sh version ${SCRIPT_VERSION} "
    echo >&2 "usage: ${SCRIPT_NAME}.sh [ <command> ] "
    exit 2
fi 

#
# All error messages go to stderr, then exit with code 1:
#
SetupErr() {
    echo >&2 "${SCRIPT_NAME}: ${1}"
    exit 1
}

#
# Verify that the database file exists; can't run anything without it:
#
[[ -r "${WINE_BOTTLE_ROOT}"/"${DATABASE_NAME}" ]] || SetupErr \
        "Could not find '${DATABASE_NAME}'; Exiting. "

#
# Assume that there are no arguments & that we suppress Wine debug output: 
#
DEBUG_CMD="WINEDEBUG=-all"

#
# Enable debug mode?  Any arguments imply '-d'; 
# This includes '-d' itself, which, if present, needs to be removed: 
#
if [[ -n "${1}" ]]; then
    # 
    # Reduce the next argument to lower case & get the first two chars.
    # Note that since we're to erase DEBUG_CMD, it's a free variable here:
    #
    DEBUG_CMD=${1,,}
    DEBUG_CMD=${DEBUG_CMD:0:2}
    
    # Check for an explicit 'debug' switch:
    #
    [[ "${DEBUG_CMD}" == '-d' ]] && shift
    
    # Since '-d' was implied or expressed, do NOT turn off Wine debug:
    #
    DEBUG_CMD=""
fi

# 
# Source the key environment variable values from the DAT file:
#
source &>/dev/null "${WINE_BOTTLE_ROOT}"/"${DATABASE_NAME}"

(( $? == 0 )) || SetupErr \
        "Cannot source '${WINE_BOTTLE_ROOT}"/"${DATABASE_NAME}'; exiting. "

#
# Assemble the Wine prefix, then verify it resolves to a valid directory:
#
WINE_PREFIX=${WINE_BOTTLE_ROOT}/${BOTTLE_NAME}

[[ -x "${WINE_PREFIX}/drive_c" ]] || SetupErr \
        "Cannot find Wine Bottle '${WINE_PREFIX}'; exiting. "

#
# Determine what to do: Run the app or run a wine command on its bottle:
#
if [[ -n "${1}" ]]; then

    ${LAUNCH_ENV} WINEARCH=win32 WINEPREFIX=${WINE_PREFIX} "$@"
else

    ${LAUNCH_ENV} ${DEBUG_CMD} WINEPREFIX=${WINE_PREFIX} \
            wine start "${MENU_PATH}"
fi


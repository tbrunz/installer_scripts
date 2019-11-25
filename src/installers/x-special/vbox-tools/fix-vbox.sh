#! /usr/bin/env bash
#
# Script to kill and restart a stuck VirtualBox Manager GUI
#
#
VBOX_MGR_APP=VirtualBox
VBOX_MGR_PATH=/usr/lib/virtualbox/${VBOX_MGR_APP}

ERR=

ERR_WARNING=0
ERR_USAGE=1
ERR_NOSUDO=2
ERR_CMDFAIL=4
ERR_UNSPEC=8
ERR_FILEIO=16
ERR_MISSING=32
ERR_BADSWITCH=64


############################################################################
#
# Get the name of this script (for 'usage')
#
# $1 = Name of the calling script
# $2 = "unwind": Okay to unwind the link redirects
#
Get_Script_Name() {

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
# Throw an error
#
# $1 = Exit code (set to '0' for 'no exit')
# $2 = Name of the script throwing the error
# $3 = Name of the function/routine throwing the error (optional)
# $4 = Message string
#
Throw_Error() {

if (( $# > 3 )); then
    printf "%s: %s: error: %s \n" "${2}" "${3}" "${4}"
else
    printf "%s: error: %s \n" "${2}" "${3}"
fi

# Exit the script if the error code is not ERR_WARNING:
#
(( ${1} > ${ERR_WARNING} )) && exit
}


############################################################################
#
# Determine the OS version
#
Get_OS_Version() {

MAJOR_MINOR=$( pwd | cut -d 'a' -f 2 )

[[ -z "${MAJOR_MINOR}" ]] && MAJOR_MINOR=1310
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
############################################################################
#
# Find the PID of the stuck VirtualBox Manager app
#
VBOX_PID=$( ps -ef | grep ${VBOX_MGR_PATH}$ | awk '{ print $2 }' )

if (( VBOX_PID > 1 && VBOX_PID < 65536 )); then

    # Kill it...
    #
    sudo kill ${VBOX_PID}

    # Verify it's gone...
    #
    VBOX_PID=$( ps -ef | grep ${VBOX_MGR_PATH}$ | awk '{ print $2 }' )

    (( VBOX_PID > 1 && VBOX_PID < 65536 )) && \

        Throw_Error ${ERR_CMDFAIL} "${APP_SCRIPT}" \
                "Can't kill the VirtualBox Manager app ! "
fi

# Start it up again...
#
bash "${VBOX_MGR_APP}" 2>/dev/null &

echo "Done ! "


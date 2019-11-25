#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Separate a file containing a chunk of tokens into one token per line
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
(( ${1} > ${ERR_WARNING} )) && exit
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

GetScriptName ${0}

declare -a TOKEN_ARRAY

USAGE="usage: ${APP_SCRIPT} <file>
Takes a chunk of tokens in a file, separates them into one per line, and 
outputs to stdout. " 

if [[ -z "${1}" ]]; then
    
    echo "${USAGE}"
    exit
fi

RESULT=$( file "${1}" | grep ASCII )

(( $? > 0 )) && ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
        "Requires an input text file. "

TOKEN_ARRAY=()

while read -r -a TOKEN_ARRAY; do
    #
    # Now spit them back out...
    #
    NUM_TOKENS=${#TOKEN_ARRAY[@]}
    
    if (( NUM_TOKENS > 0 )); then
        
        for TOKEN in "${TOKEN_ARRAY[@]}"; do
            
            echo ${TOKEN}
        done
    fi
    
done < <( cat "${1}" )




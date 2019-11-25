#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install a given set of Ubuntu Personal Package Archives (PPAs)
# ----------------------------------------------------------------------------
# 

INCLUDES="core-install.bash" 

if [[ -f "${INCLUDES}" ]]; then source "${INCLUDES}" 
else 
    echo -n "$( basename "${0}" ): error: " 
    echo    "Could not source the '${INCLUDES}' file ! " 
    exit 
fi 

GetScriptName "${0}"

PPA_INSTALL_ROOT=install-ppa-
PPA_LIST_FILE=ppa-list.${1}

USAGE="
usage: ${APP_SCRIPT} <group name>

This script will install a series of PPA repositories, without performing 
repo updates (to save download time).  The list of repositories is expected 
to be in a file named 'ppa-list.<group name>'; the <group name> must be 
given as an argument when the script is run.
"

# Check for a valid argument...
#
if [[ -z "${1}" || "${1}" == "-h" || "${1}" == "--help" ]]; then

    printf %s "${USAGE}"
    echo
    exit 1
fi

# Qualify the list file...
#
[[ ! -r "${PPA_LIST_FILE}" ]] && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not open file '${PPA_LIST_FILE}' ! "

# Qualify the list file contents...
#
while read -r PPA_NAME; do
    
    [[ $( printf %s "${PPA_NAME}" | cut -c 1 ) == "#" ]] && continue
    
    PPA_SCRIPT=${PPA_INSTALL_ROOT}${PPA_NAME}.sh
    
    [[ ! -r "${PPA_SCRIPT}" ]] && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not open file '${PPA_SCRIPT}' ! "
    
done < <( cat "${PPA_LIST_FILE}" )

# Now attempt to install each repo...
#
SUCCESS_LIST=()
FAIL_LIST=()

while read -r PPA_NAME; do
    
    [[ $( printf %s "${PPA_NAME}" | cut -c 1 ) == "#" ]] && continue
    
    PPA_SCRIPT=${PPA_INSTALL_ROOT}${PPA_NAME}.sh
    
    bash ./"${PPA_SCRIPT}" -p
    
    if (( $? > 0 )); then
        FAIL_LIST+=( "${PPA_NAME}" )
    else
        SUCCESS_LIST+=( "${PPA_NAME}" )
    fi
    
done < <( cat "${PPA_LIST_FILE}" )

# Report the results...
#
echo "Successful installs: "

if (( ${#SUCCESS_LIST[@]} == 0 )); then
    echo "...None! "
else
    for REPO in "${SUCCESS_LIST[@]}"; do
        echo ${REPO}
    done
fi

echo
echo "Failed installs: "

if (( ${#FAIL_LIST[@]} == 0 )); then
    echo "...None! "
else
    for REPO in "${FAIL_LIST[@]}"; do
        echo ${REPO}
    done
fi
echo


#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Swap versions of Rhythmbox databases
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




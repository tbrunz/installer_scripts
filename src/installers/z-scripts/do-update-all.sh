#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Update all Ubuntu packages
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

QualifySudo
sudo apt-get update && sudo apt-get dist-upgrade -y


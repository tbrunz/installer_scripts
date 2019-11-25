#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Fixup CA certificates
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

GetOSversion

QualifySudo

sudo apt-get install --reinstall ca-certificates

sudo update-ca-certificates

##############################################################################

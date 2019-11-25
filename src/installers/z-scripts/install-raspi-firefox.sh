#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'firefox' in a Raspberry Pi system
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

USAGE="
This script installs Firefox in Raspian, the version of Debian Linux adapted
for the Raspberry Pi device.

    << NOT YET IMPLEMENTED >>

For more info, see https://www.raspberrypi.org/forums/viewtopic.php?t=150438
"

SET_NAME="Firefox (Raspbian)"
PACKAGE_SET="dirmngr  firefox  ppa-purge  "

REPO_NAME="${SET_NAME}"
REPO_URL="ppa:ubuntu-mozilla-security/ppa"
REPO_GREP="mozilla.*${DISTRO}"

#PerformAppInstallation "$@"
PerformAppInstallation

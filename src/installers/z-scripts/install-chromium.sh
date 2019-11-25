#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the Chromium Browser
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
This package installs the Chromium web browser, NOT the Google Chrome web
browser (which is only available for 64-bit systems).  If you are running a
32-bit system, you will have to settle for Chromium.

This script installs the latest version from the Ubuntu repos.

For more info, see https://www.chromium.org/Home
"

SET_NAME="Chromium"
PACKAGE_SET="chromium-browser  "

PerformAppInstallation "$@"

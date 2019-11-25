#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Google Chrome Browser
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
This package installs the Google Chrome web browser for 64-bit systems.
If you are running a 32-bit system, you will need to install Chromium for
32-bit systems instead.

    https://www.google.com/intl/en/chrome/browser/features.html

    https://www.chromium.org/Home

This script installs the latest stable version by adding the Google
Linux downloads repo.
"

GetOSversion
[[ "${ARCH}" == "x86_64" ]] || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Google Chrome is only supported on 64-bit; install Chromium instead ! "

SET_NAME="Google Chrome"
PACKAGE_SET="google-chrome-stable  "

#PACKAGE_SET="libxss1  "
#PACKAGE_SET="libcurl3  libgconf2-4  libnss3-1d  "

# Get the signing key & set up for a PPA installation:
#
SIGNING_KEY=https://dl-ssl.google.com/linux/linux_signing_key.pub

REPO_NAME="${SET_NAME}"
REPO_URL="deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main"
REPO_GREP="google.com.*linux.*chrome.*deb"

PerformAppInstallation "$@"

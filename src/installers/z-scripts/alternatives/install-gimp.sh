#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'gimp' using the Ubuntu repository.
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
GIMP (GNU Image Manipulation Program) is a raster graphics editor used for
image retouching and editing, free-form drawing, resizing, cropping, photo-
montages, converting between different image formats, and more specialized
tasks.

GIMP is released under LGPLv3 and GPLv3+ licenses and is available for Linux,
OS X, and Windows.

This script installs the version in the Ubuntu repository.

For more information, see http://www.gimp.org/
"

SET_NAME="gimp"
PACKAGE_SET="gimp  gimp-help-en  gimp-data-extras  "

PerformAppInstallation "$@"

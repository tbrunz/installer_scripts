#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Lua 5.4 in Ubuntu 20.04 (Focal)
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
Lua version 5.4 was released in late July, 2020, after the package list for 
Ubuntu 20.04 (Focal Fossa) was frozen.  As a result, it is not in the 20.04 
repositories.

It is, however, in the 20.10 (Groovy Gorilla) repositories, and therefore 
available for backporting.  This script sets up the repos for backporting 
and installs Lua 5.4 for Ubuntu 20.04 or earlier.
"

SET_NAME="Backport Lua 5.4"
PACKAGE_SET="lua5.4  liblua5.4-0  liblua5.4-dev  "


# Can't (easily) backport if Ubuntu version is earlier than 20.04:
#
if (( MAJOR < 20 )); then

    ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
"Backporting is not practical; upgrade your Ubuntu distro to 20.04 or later."
fi

# No need to backport if Ubuntu version is 20.10 or later:
#
GetOSversion
if (( MAJOR > 20 || MINOR == 10 )); then

    ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
"Backporting is not necessary; Lua 5.4 is in the repos for Ubuntu 20.10++."
fi

BACKPORT_DISTRO="groovy"

PerformAppInstallation "$@"


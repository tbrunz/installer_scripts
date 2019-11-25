#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'my-weather-indicator' using the author's PPA repository.
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

USAGE="
'My Weather Indicator' adds a weather conditions indicator to your panel.

Besides the info available in the appindicator (temperature, wind chill, wind
velocity, humidity, and so on), 'My Weather Indicator' also displays NotifyOSD
notifications on condition changes.  You can also get an extended weather
forecast (or forecast map) by clicking the corresponding option in its menu.
"

SET_NAME="weather-indicator"
PACKAGE_SET="my-weather-indicator  ppa-purge  "

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL="ppa:atareao/atareao"
REPO_GREP="atareao.*atareao.*${DISTRO}"

PerformAppInstallation "$@"

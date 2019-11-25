#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'calendar-indicator' using the author's PPA repository.
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
SET_NAME="Calendar Indicator"

USAGE="
'Calendar Indicator' adds the Google Calendar to your indicator panel.
"

POST_INSTALL="
    Note that in order to have the ${SET_NAME} persist in the indicator
    panel, select 'autostart' in the preferences after you've started it for
    the first time from the Dash.
"

PACKAGE_SET="calendar-indicator  ppa-purge  "

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL="ppa:atareao/atareao"
REPO_GREP="atareao.*atareao.*${DISTRO}"

PerformAppInstallation "$@"

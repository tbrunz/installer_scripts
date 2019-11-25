#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'pidgin' + 'pidgin-indicator' using the author's PPA repository.
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
This script installs Pidgin, then installs a PPA-based indicator for Pidgin.

Pidgin may not be the default IM client for a few Ubuntu releases, but it's
still a very popular application.  Pidgin uses a tray icon by default but you
can now use an AppIndicator -- which is especially useful, since the old
Unity 'systray whitelist' is no longer available.

Once installed, open Pidgin and from its menu select Tools > Plugins, then
scroll down until you see a plugin called 'Ubuntu Indicator' and enable this
plugin.
"

SET_NAME="Pidgin+Indicator"
PACKAGE_SET="pidgin  pidgin-indicator  ppa-purge  "

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL="ppa:nilarimogard/webupd8"
REPO_GREP="nilarimogard.*webupd8.*${DISTRO}"

PerformAppInstallation "$@"

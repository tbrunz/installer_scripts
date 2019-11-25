#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Clementine music player from the repository
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
Clementine is a cross-platform free and open source music player and library
organizer.  It is a port of Amarok 1.4 to the Qt 4 framework and the GStreamer
multimedia framework.  It is available for *nix, Windows, and Mac OS X.
Clementine is released under the terms of the GNU General Public License.

Clementine was created because of the Amarok transition from version 1.4 to
version 2, and the shift of focus connected with it, which was criticized by
many users. The first version of Clementine was released in February 2010.

http://www.clementine-player.org/
"

SET_NAME="Clementine"
PACKAGE_SET="clementine  python-acoustid  "

PerformAppInstallation "$@"

#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'arronax' using the author's PPA repository.
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
SET_NAME="Arronax"

USAGE="
Arronax is a program & Nautilus extension for creating & modifying launchers
('.desktop' files) for applications and locations (URLs).

Arronax can be used as a standalone application or as a plugin for Nautilus
(the default file manager of the Gnome and Unity desktop environments).

As a Nautilus plugin, Arronax adds a menu item 'Create starter for this file'
or 'Create a starter for this program' to the context menu.  If the file is an
application launcher you get an item 'Modify this starter' instead.

If you have icons on your desktop enabled, Arronax adds a menu item 'Create
starter' to your desktop context menu.
"

PACKAGE_SET="arronax  python-nautilus  ppa-purge  "

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL=" ppa:diesch/testing"
REPO_GREP="diesch.*${DISTRO}"

PerformAppInstallation "-r" "$@"

echo
echo "Installation of the '${SET_NAME}' package set is complete. "
echo
echo "Nautilus needs to be restarted to complete installation. "
echo
read -r -s -n 1 -p "Press any key to restart Nautilus, <Ctrl-C> to quit: "
echo

# Restart Nautilus in order to integrate its context menu:
#
nautilus -q
pgrep -f service.py 1>/dev/null && pgrep -f service.py | xargs kill
nohup nautilus 1>/dev/null 2>&1 &

InstallComplete

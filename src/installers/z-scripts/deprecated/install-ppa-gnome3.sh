#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Gnome Shell (GNOME 3), version 3.8
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
This script installs the latest Gnome Shell and Gnome Desktop from the Gnome
team's Ubuntu PPA.  You may get better results if you install the repository
version first (using another script), then this package.

GNOME Shell (Gnome 3) is the user interface of the GNOME desktop environment,
starting with version 3.  Released in April 2011, it provides basic desktop
functionality such as switching between windows and launching applications.
It replaces GNOME Panel (Gnome 2) and other software components from GNOME 2
to offer a user experience that breaks from the previous model of the desktop
metaphor that was used in earlier versions of GNOME.

GNOME Shell uses Mutter, a compositing window manager based on the Metacity
window manager, and the Clutter toolkit to provide visual effects and hardware
acceleration.  According to its maintainers, GNOME Shell is set up as a Mutter
plugin largely written in JavaScript.
"

POST_INSTALL="
    You may customize & apply theme(s) using the GNOME Tweak Tool.
    (Installed; Do an app search for 'tweak' to launch it.)
"

SET_NAME="Gnome 3 (PPA)"
PACKAGE_SET="gnome
gnome-themes-extras  gnome-themes-ubuntu
gnome-hearts
ppa-purge  "
#gnome-session-fallback
#dia-gnome
##gnome-shell  gnome-themes-more
##gnome-tweak-tool  gnome-sushi
##libreoffice-gnome

# Some packages are version dependent:
#
GetOSversion
if (( MAJOR > 12 )); then

    PACKAGE_SET="${PACKAGE_SET}  ubuntu-gnome-default-settings  gnome-boxes  "
fi

REPO_NAME="${SET_NAME}"
REPO_URL="ppa:gnome3-team/gnome3"
REPO_GREP="gnome3.*team.*${DISTRO}"

case ${1} in
"-n" | "-u")
    echo
    echo "Select the 'gdm' display manager to get the GNOME login screen... "
    echo
    sleep 3
    ;;
"-p" | "-i")
    PerformAppInstallation "$@"
    exit
    ;;
*)
    PerformAppInstallation
    ;;
esac

PerformAppInstallation "-r" "-u"

sudo apt-get -y dist-upgrade

InstallComplete

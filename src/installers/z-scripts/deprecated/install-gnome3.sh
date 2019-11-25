#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Gnome Shell (GNOME 3) plus extras (themes)
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

THEMES_DIR=/usr/share/themes

USAGE="
This script installs the default version of the Gnome Shell, Gnome Desktop,
and Gnome 3 themes from the Ubuntu repositories.  If you want to replace the
Unity desktop with the Gnome desktop, it is recommended that you instead
re-install using Gnome-Ubuntu.

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

SET_NAME="Gnome 3 (repo)"

PACKAGE_SET="
gnome  gnome-core
gnome-tweak-tool  gnome-sushi  dia-gnome
libreoffice-gnome  gnome-hearts
gnome-themes-standard  gnome-themes-extras  gnome-themes-ubuntu  "

# Some packages are version dependent:
#
GetOSversion
if (( MAJOR > 12 )); then

  PACKAGE_SET="${PACKAGE_SET}  ubuntu-gnome-default-settings  gnome-boxes  "
fi

if (( MAJOR > 14 )); then

  PACKAGE_SET=$( printf %s "${PACKAGE_SET}" | sed -e 's/gnome-themes-extras//' )
fi

#
# From webupd8.com:
#
# ubuntu-gnome-desktop -- Don't: it removes most of the GNOME packages!
# ubuntu-gnome-default-settings
# gnome-documents -- Don't bother; it gets installed with the others;
# gnome-boxes
#
# Remove Unity overlay scrollbars
# One thing I've noticed after following the steps above is that GNOME
# Shell continues to use Ubuntu's overlay scrollbars. If you want to use
# the GNOME 3 scrollbars instead, remove overlay scrollbars using the
# following command:
#   sudo apt-get remove overlay-scrollbar*
#
# It is also a good idea to remove the "ubuntu-settings" package:
#   sudo apt-get remove ubuntu-settings
#
# Note that by removing this package, the "ubuntu-desktop" package will be
# removed as well. This is just a meta package and your system shouldn't
# be affected by it.  The "ubuntu-settings" package is used to set various
# Ubuntu defaults, like the window button order, which Rhythmbox plugins
# are enabled by default and so on.
#

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

echo
echo "Select the 'gdm' display manager to get the GNOME login screen... "
echo
sleep 3

PerformAppInstallation "-r" "$@"

SOURCE_DIR="../gnome-themes"
SOURCE_GLOB=*tgz

FindGlobFilename "basename" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

if (( $? == 0 )); then
    #
    # Create/validate the themes directory & unpack each theme:
    #
    QualifySudo
    makdir "${THEMES_DIR}"

    for THEME_PKG in "${FILE_LIST[@]}"; do

        if [[ -f "${SOURCE_DIR}/${THEME_PKG}" ]]; then

            tar_zip "gz" "${SOURCE_DIR}/${THEME_PKG}" -C "${THEMES_DIR}"

            sudo chmod 755 "${THEMES_DIR}"/*
            sudo chown -R root:root "${THEMES_DIR}"/*

        else
            echo "Problem processing theme '${THEME_PKG}'; skipping... "
        fi
    done
fi

InstallComplete

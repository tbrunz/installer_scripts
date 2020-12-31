#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install GRUB Customizer (from PPA)
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
Grub Customizer is a graphical interface to configure GRUB2/BURG settings
and menu entries.

Features:

 * Move, remove, or rename menu entries (they stay updatable by 'update-grub')
 * Edit the contents of menu entries or create new ones (in '40_custom')
 * Support for GRUB2 and BURG bootloaders
 * Re-installation of the bootloader to the MBR (Master Boot Record)
 * Settings for default OS, kernel params, background image, text colors, etc.
 * Can change the installed operating system when running from a Live CD

https://launchpad.net/grub-customizer
"

SET_NAME="GRUB Customizer"
PACKAGE_SET="grub-customizer  ppa-purge  "

if (( MAJOR < 19 )); then
    #
    # Ubuntu 19.10 and later *finally* has this in the repos...
    # For Bionic & earlier, need to get it from the PPA.
    #
    REPO_NAME="${SET_NAME} (PPA)"
    REPO_URL="ppa:danielrichter2007/grub-customizer"
    REPO_GREP="grub-customizer.*${DISTRO}"
fi

PerformAppInstallation "$@"

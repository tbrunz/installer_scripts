#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Dropbox
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

# Workaround for Dropbox screw-up:
#
GetOSversion
[[ ${DISTRO} == "saucy" ]] && DISTRO=raring

USAGE="
Dropbox is a file hosting service operated by Dropbox, Inc., that offers
cloud storage, file synchronization, and client software.  Dropbox allows
users to create a special folder on each of their computers, which Dropbox
then synchronizes so that it appears to be the same folder (with the same
contents) regardless of which computer is used to view it.

Files placed in the Dropbox folder are also accessible through a website &
mobile phone applications.  Dropbox provides client software for Microsoft
Windows, Mac OS X, Linux, Android, iOS, BlackBerry OS, and web browsers,
as well as unofficial ports to Symbian, Windows Phone and MeeGo.

NOTE: Dropbox stopped providing a PPA after Xenial (16.04).  For later 
editions, install from the Ubuntu Software Center.

https://www.dropbox.com/
"

POST_INSTALL="
    You must restart Nautilus in order for the folder status icons and the
    'right-click' context menu to be enabled in the Nautilus file browser
    displays.  You should be prompted to do this, or you may do it manually.

        (To manually restart nautilus, open a terminal window and enter
        'nautilus -q' to cause Nautilus to shut down, which will cause it
        to close all open file browser windows.)

    You should then be prompted to start Dropbox, which should open a dialog
    to download the rest of the application (plus updates).

    A dialog will then appear asking if you already have an account. If so,
    select that option and log in.  A 'Dropbox' folder will automatically be
    added to your home account and the Dropbox icon will be added to your
    notification area.

    The 'Dropbox' folder can be easily opened by clicking the Dropbox icon
    in your desktop's notification area.
"

if (( MAJOR > 16 )); then

    echo "Dropbox stopped providing a PPA after Xenial (16.04). "
    echo "You will need to install from the Ubuntu Software Center. "
    exit ${ERR_WARNING}
fi

SET_NAME="Dropbox"
PACKAGE_SET="dropbox  "

#PACKAGE_SET="python-gpgme  "

SIGNING_KEY="adv --keyserver pgp.mit.edu --recv-keys 5044912E"

REPO_NAME="${SET_NAME}"
REPO_URL="deb http://linux.dropbox.com/ubuntu ${DISTRO} main"
REPO_GREP="linux.dropbox.com.*ubuntu"

PerformAppInstallation "-r" "$@"

[[ ${1} == "-p" ]] && exit

InstallComplete


#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Nvidia drivers from the CLI
# ----------------------------------------------------------------------------
#

DRIVER_VERSION="390"

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
This package installs the Nvidia graphics card drivers from the Ubuntu
graphics drivers PPA repository.

The script is currently hard-coded to install driver version ${DRIVER_VERSION}.

If you are installing on a laptop with Optimus, you might want to install
the 'bumblebee-nvidia' package afterwards.  This must be done manually.
"

POST_INSTALL="
If you are installing on a laptop with Optimus, you might want to install
the 'bumblebee-nvidia' to enable these hardware features.
"

SET_NAME="Nvidia drivers (PPA)"
PACKAGE_SET="nvidia-${DRIVER_VERSION}  "

#PACKAGE_SET="bumblebee-nvidia  "

# Get the signing key & set up for a PPA installation:
#
#SIGNING_KEY=https://dl-ssl.google.com/linux/linux_signing_key.pub

REPO_NAME="${SET_NAME}"
REPO_URL="ppa:graphics-drivers/ppa"
REPO_GREP="graphics-drivers.*${DISTRO}"

#
# Invoked with the '-p' or '-i' switch?
#
if [[ -z "${1}" || "${1}" == "-p" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

# If nvidia drivers are currently installed, uninstall them.
#
RESULT=$( which nvidia-xconfig )

if [[ -n "${RESULT}" ]]; then
  QualifySudo
  sudo apt-get purge *nvidia*
fi

PerformAppInstallation "$@"

: << '__COMMENT'

HOW TO (re)installing Linux graphics drivers from the CLI
===============================================================================

If in a GUI, press <Ctrl><Alt><F2> to get a console.
(Don't use <F1>, since GDM3 remapped the GUI session from <F7> to <F1>).

Log into an account that has 'sudo' privileges.

Use the below commands to install or re-install drivers.


Nvidia graphics card drivers
----------------------------------

If Nvidia drivers are already installed, remove them first using

    $ sudo apt-get purge *nvidia*


Install the PPA with the latest drivers using

    $ sudo add-apt-repository ppa:graphics-drivers/ppa

    $ sudo apt-get update


Find the latest versions using

    $ apt-cache search nvidia | grep nvidia-driver


Review the list and select a driver package.  Then

    $ sudo apt-get install nvidia-${DRIVER_VERSION}

to install the driver.  (E.g., "sudo apt-get install nvidia-390".)


Laptops with Optimus technology may benefit from installing the
"bumblebee" driver package.  If using the proprietary Nvidia graphics
drivers, use package "bumblebee-nvidia" instead.


Reboot to apply the changes.

-----

__COMMENT

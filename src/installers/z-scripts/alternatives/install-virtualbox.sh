#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install VirtualBox from the Ubuntu repo
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

VBOX_GROUP=vboxusers

USAGE="
This script installs the VirtualBox OSE Edition from the Ubuntu repositories.
You may wish to install a more recent version using either the PPA version of
this script, or by downloading the latest 'deb' packages from the VirtualBox
website and installing using the 'deb' version of this script.

Oracle VM VirtualBox (formerly Sun VirtualBox, Sun xVM VirtualBox, and innotek
VirtualBox) is an x86 and x86_64 virtualization software package, created by
software company Innotek GmbH, purchased in 2008 by Sun Microsystems, and now
developed by Oracle Corporation as part of its family of virtualization
products.

Oracle VM VirtualBox is installed on an existing host operating system as an
application; this host application allows additional guest operating systems,
each known as a Guest OS, to be loaded and run, each with its own virtual
environment.

Supported host operating systems include Linux, Mac OS X, Windows XP, Windows
Vista, Windows 7, Windows 8, Solaris, and OpenSolaris; there is also a port to
FreeBSD.  Supported guest operating systems include versions and derivations
of Windows, Linux, BSD, OS/2, Solaris and others.

Since version 4.1, Windows guests on supported hardware can take advantage of
the recently implemented WDDM driver included in the guest additions; this
allows Windows Aero to be enabled along with Direct3D support.

https://www.virtualbox.org/wiki/Downloads/
"

POST_INSTALL="
* Be sure to install the corresponding Oracle VirtualBox Extension Pack:

  Download the extension pack from the VirtualBox web site:
    https://www.virtualbox.org/wiki/Downloads

  Launch VirtualBox, then select File > Preferences > Extensions, then click
  the 'Add package' icon (gold-colored down-arrow), then locate the extension
  pack file (from this directory).

* Don't forget to install the VirtualBox Guest Additions for each VM created
  (or update for each existing VM) -- select from the 'Devices' menu.

* Install archived virtual machines by selecting Machine >> Add...
"

SET_NAME="VirtualBox (repo)"
PACKAGE_SET="virtualbox virtualbox-guest-additions-iso "
PACKAGE_SET="${PACKAGE_SET}  linux-headers-generic  libsdl1.2debian  "

PerformAppInstallation "-r" "$@"
(( $? > 0 )) && return 1

#
# Add the 'vboxusers' group that VirtualBox needs...
#
QualifySudo
AddGroup ${VBOX_GROUP} --system

#
# Ask about adding each user to the 'vboxusers' group:
#
GetUserAccountInfo
echo
echo "Do you want the following users to have VirtualBox privileges? "

for THIS_USER in "${USER_LIST[@]}"; do

    Get_YesNo_Defaulted -y "User '${THIS_USER}'?"

    if (( $? == 0 )); then

        sudo adduser ${THIS_USER} ${VBOX_GROUP}
        (( $? == 0 )) && continue

        echo -n "    Could not add '${THIS_USER}' "
        echo    "to group '${VBOX_GROUP}', skipping... "

    else
        sudo deluser ${THIS_USER} ${VBOX_GROUP}
        (( $? == 0 )) && continue

        echo -n "    Could not remove '${THIS_USER}' "
        echo    "from group '${VBOX_GROUP}', skipping... "
    fi
done

echo
getent group ${VBOX_GROUP}

InstallComplete

#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Oracle/Sun VirtualBox from Oracle's PPA
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

SUGGEST_VERSION=5.0

# System group required for users to have vbox privileges:
#
VBOX_GROUP="vboxusers"

#
# Create a usage prompt:
#
USAGE="
This script will install the latest stable version of VirtualBox by adding the
Oracle VirtualBox repository (i.e., their website) for downloading & updates.
It also adds the Oracle package signing key to your keyring, which is needed
to authenticate the VirtualBox packages.

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

  Launch VirtualBox, then select 'File > Preferences > Extensions', then click
  the 'Add package' icon (gold-colored down-arrow), then locate the extension
  pack file (from this directory).

* Don't forget to install the VirtualBox Guest Additions for each VM created
  (or update for each existing VM) -- select from the 'Devices' menu.

* Install archived virtual machines by selecting 'Machine > Add'...
"


SET_NAME="VirtualBox (PPA)"

SIGNING_KEY=http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc

REPO_NAME="${SET_NAME}"
REPO_URL="deb http://download.virtualbox.org/virtualbox/debian ${DISTRO} contrib"
REPO_GREP="virtualbox.*virtualbox.*debian"

#
# Invoked with the '-p' switch?
#
if [[ ${1} == "-p" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

#
# The user must tell us which Virtualbox version they want to install,
# And must also include an 'update' switch (-n or -u)...
#
PKG_VERSION=${1}
shift

printf %s "${PKG_VERSION}" | egrep '^[[:digit:]]+[.][[:digit:]]+$' >/dev/null

if (( $? != 0 )); then
    PKG_VERSION=${SUGGEST_VERSION}
    PerformAppInstallation
fi

if [[ ${1} == "-p" || -z "${1}" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

#
# Add the 'vboxusers' group that VirtualBox needs...
#
QualifySudo
AddGroup ${VBOX_GROUP} --system

PACKAGE_SET="virtualbox-${PKG_VERSION}  libsdl1.2debian  "
#PACKAGE_SET="virtualbox-${PKG_VERSION}  linux-headers-generic"

PerformAppInstallation "-r" "$@"
(( $? > 0 )) && return 1

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

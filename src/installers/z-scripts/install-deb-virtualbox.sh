#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Oracle/Sun VirtualBox from Oracle's PPA
# ----------------------------------------------------------------------------
#

SUGGEST_VERSION=6.10.x

INCLUDES="core-install.bash"

if [[ -f "${INCLUDES}" ]]; then source "${INCLUDES}"
else
    echo -n "$( basename "${0}" ): error: "
    echo    "Could not source the '${INCLUDES}' file ! "
    exit
fi

GetScriptName "${0}"

# VirtualBox sometimes lags the distro names...
#
GetOSversion
#(( MAJOR > 13 || MINOR == 10 )) && DISTRO=raring

# System group required for users to have vbox privileges:
#
VBOX_GROUP="vboxusers"

#
# Create a usage prompt:
#
USAGE="
This script will install a version VirtualBox from a cached '.deb' package.
(These are typically the latest versions retrieved from the website.)

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

* Add each VM user account to the VirtualBox Shared Folders group:
    sudo adduser <user> vboxsf
"


SET_NAME="VirtualBox (deb)"

#
# Invoked with the '-p' or '-i' switch?
#
if [[ -z "${1}" || "${1}" == "-p" || "${1}" == "-i" ]]; then
    PKG_VERSION=${SUGGEST_VERSION}
    PerformAppInstallation "$@"
    exit $?
fi

#
# The user must tell us which Virtualbox version they want to install,
# And must also include an 'update' switch (-n or -u)...
#
PKG_VERSION=${1}
shift

printf %s "${PKG_VERSION}" | \
        egrep '^[[:digit:]]+[.][[:digit:]]+[.][[:digit:]]+$' >/dev/null

if (( $? != 0 )); then
    PKG_VERSION=${SUGGEST_VERSION}
    PerformAppInstallation
fi

if [[ -z "${1}" || ${1} == "-p" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

#
# Adjust for installation distro change (damn Oracle!)
#
#RESULT=$( echo "${PKG_VERSION}" | cut -c 1 )
#[[ "${RESULT}" == "5" ]] && DISTRO=trusty

#
# Add the 'vboxusers' group that VirtualBox needs...
#
QualifySudo
AddGroup ${VBOX_GROUP} --system

PACKAGE_SET="
    libsdl1.2debian  libsdl-ttf2.0-0
    libqt5opengl5  libqt5printsupport5  libqt5x11extras5
    "
#PACKAGE_SET="linux-headers-generic  "

if (( MAJOR < 18 )); then PACKAGE_SET="${PACKAGE_SET}  libcurl3  "
else PACKAGE_SET="${PACKAGE_SET}  libcurl4  "
fi

SOURCE_DIR="../virtualbox/${PKG_VERSION}"

SOURCE_GLOB="*${DISTRO}*deb"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
DEB_PACKAGE=${FILE_LIST}

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

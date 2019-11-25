#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Upgrade to later Ubuntu LTS 'Enablement' (Hardware) Stack
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

KERNEL_ROOT=linux-generic-lts
SIGNED_ROOT=linux-signed-generic-lts
HEADER_ROOT=linux-headers-generic-lts
TOOLS_ROOT=linux-tools-generic-lts

SET_NAME="LTS Enablement Stack"
PKG_VERSION=xenial

USAGE="
This script installs the LTS 'Hardware Enablement' kernel/X11 stack packages.

The Ubuntu LTS HWE packages provide updated kernel and X11 support for
existing LTS releases.  These packages are installed automatically when an
Ubuntu 'Desktop' installation is updated.  However, Ubuntu 'Server' installs
default to the 'General Availability' kernel/stack and are not updated beyond
the versions installed when the LTS is first released.

For Server installations, the GA packages can be replaced with the HWE packages
using this script.  Thereafter, updates will automatically select and install
the newer interim kernel/X11 stack packages.

These newer enablement stacks are meant for desktop and server editions and are
even recommended for cloud or virtual images.  This script is particularly
useful for cases where a desktop system is installed using the Server installer
(typically in order to build the desktop system on a RAID array), then upgraded
with the desktop X11 stack.  This script completes the transition from Server
install to Desktop install.

To install, run this script with the name of the desired 'interim' distro stack
as the first parameter ('trusty', 'utopic', 'vivid', 'wily', 'xenial').  Note
that this is NOT the name of the system's installed distro; it will typically
be a later 'interim' distro.

For example, to install the Xenial Xerus stack (kernel 4.4) in a Trusty Tahr
installation (which originally shipped with kernel 3.13), enter

    ${APP_SCRIPT} xenial -n

https://wiki.ubuntu.com/Kernel/LTSEnablementStack
"

# Invoked without the distro argument?
#
#if [[ -z "${INSTALL_CHOICE}" || -z "${1}" || "${1}" == "-i" ]]; then
if [[ -z "${1}" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

# Only works for current LTS versions of Ubuntu...
#
GetOSversion
Exit_if_OS_is_ChromeOS "${APP_SCRIPT}"
Exit_if_OS_is_GalliumOS "${APP_SCRIPT}"

if (( MINOR == 04 && (MAJOR == 18 || MAJOR == 20) )); then
    
    PACKAGE_SET="linux-generic-hwe-18.04  xserver-xorg-hwe-18.04  "
    sudo apt-get install --install-recommends ${PACKAGE_SET}
    
    exit $?
fi

(( MINOR != 04 || MAJOR != 14 && MAJOR != 16 )) && \
        ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
                "This script only applies to a current LTS version of Ubuntu ! "

INSTALL_CHOICE=${1}
shift

# Do the repos contain packages for the indicated distro?
#
RESULT=$( apt-cache search ${KERNEL_ROOT}-${INSTALL_CHOICE} )

(( $? > 0 )) && ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
        "Cannot find kernel packages for '${INSTALL_CHOICE}' ! "

RESULT=$( printf %s ${RESULT} | egrep "^${KERNEL_ROOT}-${INSTALL_CHOICE}" )

(( $? > 0 )) && ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
        "Cannot find kernel packages for '${INSTALL_CHOICE}' ! "

# Determine if this install can support signed kernels (requires UEFI/64-bit)
#
SIGNED=""

if [[ "${ARCH}" == "x86_64" ]]; then

    Get_YesNo_Defaulted "n" "Do you wish to install the signed kernel?"

    (( $? == 0 )) && SIGNED="-signed"
fi

LATENCY="-generic"
Get_YesNo_Defaulted "n" "Do you wish to install the low-latency kernel?"
(( $? == 0 )) && LATENCY="-lowlatency"


# Determine if we're a server or desktop installation...
# (( IS_SERVER == 0 )) if this is a Desktop installation:
#
IS_SERVER=$( ls /usr/bin/*session* | grep gnome )
IS_SERVER=$?

XSERVER_XORG=""

if (( MAJOR == 14 )); then

    LINUX_KERNEL="linux${SIGNED}${LATENCY}-lts-xenial"

    if (( IS_SERVER == 0 )); then
        XSERVER_XORG=${XSERVER_XORG}"  xserver-xorg-lts-xenial"
        XSERVER_XORG=${XSERVER_XORG}"  xserver-xorg-core-lts-xenial"
        XSERVER_XORG=${XSERVER_XORG}"  xserver-xorg-input-all-lts-xenial"
        XSERVER_XORG=${XSERVER_XORG}"  xserver-xorg-video-all-lts-xenial"
        XSERVER_XORG=${XSERVER_XORG}"  libwayland-egl1-mesa-lts-xenial"
        XSERVER_XORG=${XSERVER_XORG}"  libgl1-mesa-glx-lts-xenial"
        XSERVER_XORG=${XSERVER_XORG}"  libgl1-mesa-glx-lts-xenial:i386"
        XSERVER_XORG=${XSERVER_XORG}"  libglapi-mesa-lts-xenial:i386"
    fi
else

    LINUX_KERNEL="linux${SIGNED}${LATENCY}-hwe-${MAJOR}.${MINOR}"

    (( IS_SERVER == 0 )) && XSERVER_XORG="xserver-xorg-hwe-${MAJOR}.${MINOR}"
fi

QualifySudo
sudo apt-get install --install-recommends ${LINUX_KERNEL} ${XSERVER_XORG}


# Older version of this script did things manually/brute-force (wrong?):
#
PACKAGE_SET="${SIGNED_KERNEL}
${KERNEL_ROOT}-${INSTALL_CHOICE}
${HEADER_ROOT}-${INSTALL_CHOICE}
${TOOLS_ROOT}-${INSTALL_CHOICE}  "

#PerformAppInstallation "$@"
InstallComplete

#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install base set of 'extras' packages
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

EDITORS_SOURCE_DIR=../editors

DESKTOP_LAUNCHER_DIR=/usr/share/applications
DESKTOP_FILE_EXT=desktop

GNOME_ICONS_DIR=/usr/share/icons/gnome

GPRENAME_APP_NAME=gprename
GPRENAME_SRC_DIR=${EDITORS_SOURCE_DIR}/${GPRENAME_APP_NAME}
GPRENAME_LAUNCHER_FILE=${GPRENAME_APP_NAME}.${DESKTOP_FILE_EXT}

GRPN_APP_NAME=grpn
GRPN_LAUNCHER_FILE=${DESKTOP_LAUNCHER_DIR}/${GRPN_APP_NAME}.${DESKTOP_FILE_EXT}
GRPN_ICON_FILE=${GNOME_ICONS_DIR}/48x48/apps/accessories-calculator.png

SET_NAME="Base"

#
# The following package list serves two purposes:
#
#   * Form a list of Ubuntu packages for installation by 'apt-get'
#
#   * Structure the list in such a way that it can also be displayed
#     on the console for the user to review
#
# To serve as a display aid, anything between '%' characters will be
# deleted when converting the following string into a tokenized list
# for submission to 'apt-get'.
#
PACKAGE_SET="
%SYSTEM FUNCTIONS:%
ssh  dkms  exfat-utils  indicator-multiload
gparted  indicator-cpufreq  apt-transport-https  
nautilus-open-terminal  iptables-persistent  
  gnome-schedule  
%%
%SYSTEM TOOLS:%
byobu  ack-grep  ghex  hexer  tweak  ethtool
partclone  gdebi  synaptic  bash-completion
curl gdisk  txt2regex  bridge-utils  xsel  
tree  pv  zip  unzip  pigz  p7zip-rar  dolphin
%%
%UTILITIES:%
colordiff  gthumb  gpicview  rdesktop  pandoc  
mutt  bwm-ng  dconf-editor  atop  htop  iftop  
stow  gnome-tweaks  
%%
%CONVERTERS:%
tofrodos  gprename  nautilus-image-converter
pdftk  units
%%
%CD-DVD-ISO AUTHORING:%
isomaster  cdrdao  cdck  normalize-audio
k3b  k3b-extrathemes  libk3b6-extracodecs
%%
%SECURITY/RECOVERY/CRYPTO:%
gsmartcontrol  smart-notifier  cryptsetup  pmount
libudf0  udftools  nmap  zenmap  kpartx  testdisk
seahorse-nautilus
%%
%APPLICATIONS:%
dillo  lynx  links  links2  grpn  cheese
gnumeric-plugins-extra %(installs all of Gnumeric)%
abiword-plugin-grammar %(installs all of AbiWord)%  "

#
# Add items for specific distros:
#
GetOSversion

# Check to see if we're using the xfce desktop (GalliumOS)
#
if [[ "${FLAVOR}" == "xfce" ]]; then

    for PACKAGE_TO_RETRACT in gnome-schedule  nautilus-open-terminal  \
        nautilus-image-converter  seahorse-nautilus  dolphin  \
        k3b  k3b-extrathemes  libk3b6-extracodecs
    do
        PACKAGE_SET=$( printf "%s" "${PACKAGE_SET}" | \
               sed -e "s/  ${PACKAGE_TO_RETRACT}//" )
    done
fi

# Are we a Xenial installation?
#
if (( MAJOR == 16 )); then

    for PACKAGE_TO_RETRACT in gnome-tweaks
    do
        PACKAGE_SET=$( printf %s "${PACKAGE_SET}" | \
               sed -e "s/  ${PACKAGE_TO_RETRACT}//" )
    done
fi

# Are we a Trusty (or later) installation?
#
if (( MAJOR >= 14 )); then

PACKAGE_SET="${PACKAGE_SET}
%%
%SPECIFIC TO UBUNTU 14.04+:%
pdf2svg  libreoffice-style-sifr  "
fi

# Adjustments for Vivid & later
#
if (( MAJOR > 14 )); then

    for PACKAGE_TO_RETRACT in gnome-schedule  nautilus-open-terminal
    do
        PACKAGE_SET=$( printf %s "${PACKAGE_SET}" | \
               sed -e "s/  ${PACKAGE_TO_RETRACT}//" )
    done
fi

#
# 'indicator-multiload' finally got updated; must be installed via its PPA:
#
#REPO_NAME="${SET_NAME} (PPA)"
#REPO_URL="ppa:indicator-multiload/stable-daily"
#REPO_GREP="indicator-multiload.*${DISTRO}"

#
# Strip out (only) the individual '%' characters for usage display,
# then strip out extraneous blank lines:
#
DISPLAY_SET=$( printf "%s" "${PACKAGE_SET}" | sed -r -e '/^[[:space:]]*$/d' )
DISPLAY_SET=$( printf "%s" "${DISPLAY_SET}" | sed -r -e 's/%//g' )

USAGE="
This 'meta-package' installs a 'base' set of useful packages
from the Ubuntu repos:

${DISPLAY_SET}
"

#
# Are we a VirtualBox VM?  If so, don't install the CPU speed meter...
#
if (( $# > 0 )); then
    QualifySudo
    read _ VENDORNAME < <( sudo dmidecode -t0 | grep Version )
fi

if [[ ${VENDORNAME} == "VirtualBox" ]]; then

    PACKAGE_SET=$( printf %s "${PACKAGE_SET}" | sed -e 's/indicator-cpufreq//' )
fi

#
# Make sure we're not on a server!  (Don't install GUI apps...)
#
RESULT=$( ls /usr/bin/*session* | grep gnome )
RESULT=$?

[[ "${FLAVOR}" == "xfce" ]] && RESULT=0

if (( RESULT > 0 )); then

    RESULT=$( ls /usr/bin/*session* | grep lxsession )

    if (( $? > 0 )); then

        Get_YesNo_Defaulted "y" \
            "Desktop environment not detected.. Is this a desktop system?"

        (( $? > 0 )) && ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
            "This script is not appropriate for server systems ! "
    else
        Get_YesNo_Defaulted "y" \
            "LXDE desktop environment detected.. Is this a server system?"

        (( $? == 0 )) && ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
            "This script is not appropriate for server systems ! "
    fi
fi

PerformAppInstallation "-r" "$@"

# Xenial's 'gprename' package forgot to make an icon.. Oy.
#
# Did we install it?  If not, we're done.
#
which ${GPRENAME_APP_NAME} >/dev/null
if (( $? == 0 )); then

    # If it's installed, is a '.desktop' file installed?  If so, we're done.
    #
    if [[ ! -r "${DESKTOP_LAUNCHER_DIR}/${GPRENAME_LAUNCHER_FILE}" ]]; then

       # If no '.desktop' file, then can we read one from the installer?
       #
       if [[ -r "${GPRENAME_SRC_DIR}/${GPRENAME_LAUNCHER_FILE}" ]]; then

           copy "${GPRENAME_SRC_DIR}/${GPRENAME_LAUNCHER_FILE}" \
               "${DESKTOP_LAUNCHER_DIR}/"

           SetDirPerms "${DESKTOP_LAUNCHER_DIR}/${GPRENAME_LAUNCHER_FILE}" 644
       else
           ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
               "'${GPRENAME_APP_NAME}' is missing a '.desktop' file ! "
       fi
    fi
fi

# The maker of the 'grpn' package forgot to make an icon.. Oy.
#
# Did we install it?  If not, we're done.
#
which ${GRPN_APP_NAME} >/dev/null
if (( $? == 0 )); then

    # If it's installed, is a '.desktop' file installed?  If not, we're done.
    #
    if [[ -e "${GRPN_LAUNCHER_FILE}" ]]; then

       # If a '.desktop' file, then can we read the icon file?
       #
       if [[ -r "${GRPN_ICON_FILE}" ]]; then
       
           sudo sed -i -r -e "s|^Icon=.*$|Icon=${GRPN_ICON_FILE}|" \
               "${GRPN_LAUNCHER_FILE}"
       else
           ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
               "Can't read '${GRPN_ICON_FILE}' for '${GRPN_APP_NAME}' ! "
       fi
    fi
fi

InstallComplete


#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install base set of 'extras' packages for a headless server
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
    ssh  dkms  exfat-utils  bash-completion
    apt-transport-https  iptables-persistent  

%SYSTEM TOOLS:%
    txt2regex  tre-agrep  ack-grep  tweak  
    ethtool  bridge-utils  curl  zip  unzip  
    pigz  p7zip-rar  hexer  nmap  pv  bwm-ng  

%UTILITIES:%
    byobu  mutt  colordiff  kpartx  gdisk  
    tree  stow  atop  htop  iftop  

%FILE CONVERTERS:%
    pdftk  tofrodos

%SECURITY/RECOVERY/CRYPTO:%
    testdisk  gddrescue  dcfldd  dares  gzrt
    libudf0  udftools  cryptsetup  pmount

%APPLICATIONS:%
    lynx  links  links2  elinks  elinks-doc  "

#
# Add items for specific distros:
#
GetOSversion

#
# Strip out (only) the individual '%' characters for usage display,
# then strip out extraneous blank lines:
#
DISPLAY_SET=$( printf %s "${PACKAGE_SET}" | sed -e 's/%//g' )
DISPLAY_SET=$( printf %s "${DISPLAY_SET}" | sed -e '/^    $/d' )

USAGE="
This 'meta-package' installs a 'base' set of useful packages
for headless server installations:
${DISPLAY_SET}
"

PerformAppInstallation "-r" "$@"

sudo dpkg-reconfigure dash

InstallComplete

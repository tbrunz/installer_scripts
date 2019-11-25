#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the Rhythmbox media player (backport)
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

USAGE="
Rhythmbox is an audio player that plays and helps organize digital music.  
Rhythmbox is free software, designed to work well under the GNOME Desktop 
using the GStreamer media framework.  However, Rhythmbox functions on 
desktop environments other than GNOME.

Rhythmbox uses the GStreamer media framework for actual playback and other 
functionality, so in general Rhythmbox plays exactly those formats that are 
supported by GStreamer.  GStreamer, on the other hand, uses a plugin system 
where each format is supported by a plugin.  Thus, the formats supported by 
GStreamer (and Rhythmbox) depends on which plugins you have installed.  
Different distributions may ship with a different set of plugins by default.

Plugins for GStreamer are at http://gstreamer.freedesktop.org/documentation
& for Rhythmbox at https://wiki.gnome.org/Apps/Rhythmbox/Plugins/ThirdParty

Note that the repositories for older versions of Ubuntu contain versions 
of Rhythmbox that may cause database version issues when trying to install 
a dual-boot system with later versions of Ubuntu.  

Therefore, this script sets up the repos for backporting and installs the 
latest version.
"

SET_NAME="Rhythmbox (backport)"
PACKAGE_SET="rhythmbox  "

# Will backport if Ubuntu version is 15.10 or earlier:
#
GetOSversion
if (( MAJOR < 16 )); then

    BACKPORT_DISTRO="xenial"
fi

#PerformAppInstallation "$@"
echo
echo "This script does NOT work to backport the Xenial Rhythmbox to Trusty ! "
echo


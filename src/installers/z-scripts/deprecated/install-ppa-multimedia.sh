#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install multi-media packages using the 'mc3man' PPA
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

SET_NAME="multi-media support (PPA)"
SOURCE_DIR="../multimedia"

# This is a work-around to use the newest version, which is not in the repos
#
ADOBE_FLASH_PLUGIN_PKG=adobe-flashplugin

REPO_NAME="${SET_NAME}"
REPO_URL="ppa:mc3man/trusty-media"
REPO_GREP="mc3man.*trusty-media.*${DISTRO}"

PACKAGE_SET="
%*% ubuntu-restricted-extras  lame  %(MP3, Flashplugin, DVD playback)%
%*% ffmpeg  libav-tools  %(codec libraries for audio-video streaming)%
%* Microsoft fonts & codecs  (either the 32-bit or 64-bit version)%
%*% browser-plugin-vlc  gxineplugin  mencoder  %(A-V players & converters)%
%*% icedax  tagtool  easytag-nautilus  id3tool %(tools for tagging MP3's)%
%*% mpg321 nautilus-script-audio-convert %(A-V conversion tools)%

Please note that if using this PPA, you should *not* try upgrading your
distro directly.  Instead, do a fresh install.  The intent of this repo
is just for users wishing to stay on Ubuntu 14.04.  If upgrading anyway,
use 'ppa-purge' first to purge this repo and its packages.

Also note that using this PPA, then disabling it, may cause issue for
installing i386 packages like those used by Wine.  So, once enabled,
leave it enabled or purge it before removing.

https://launchpad.net/~mc3man/+archive/ubuntu/trusty-media
"

: <<'__COMMENT'

%*% libdvd-pkg %(allows you to 'rip' or play DVDs) -- optional%

# Already installed with Ubuntu 16.04:
libdvdread4
libdvdnav4
gstreamer1.0-tools
gstreamer1.0-x
gstreamer1.0-clutter-3.0
gstreamer1.0-pulseaudio
gstreamer1.0-alsa
gstreamer1.0-plugins-base
gstreamer1.0-plugins-base-apps

Installed by 'ubuntu-restricted-extras':
gstreamer1.0-plugins-ugly

# Not installed in 16.04:
ffmpeg
gstreamer1.0-packagekit
gstreamer1.0-crystalhd
gstreamer1.0-vaapi
gstreamer1.0-clutter

# Also installed with this script:
lame
libav-tools (installs 'ffmpeg')
mencoder (installs mplayer)
gxineplugin (installs gxine)
icedax cdrkit-doc
tagtool
easytag-nautilus
id3tool
nautilus-script-audio-convert
__COMMENT

#
# Strip out (only) the individual '%' characters for usage display:
#
DISPLAY_SET=$( printf %s "${PACKAGE_SET}" | sed -e 's/%//g' )

USAGE="
Due to redistribution limitations, Ubuntu distributions cannot install
many useful multi-media applications, drivers, libraries, and/or codecs
by default.  This script installs these items, plus other useful MM
applications from cached packages and the Ubuntu repositories:
${DISPLAY_SET}
"

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

Get_YesNo_Defaulted "n" "Do you want to install 'dvd-css'?"
LIBDVDCSS=$?

GetOSversion
if [[ ${ARCH} == "x86_64" ]]; then

    SOURCE_GLOB="*w64*.deb"
    (( $LIBDVDCSS == 0 )) && SOURCE_GLOB="*amd*.deb"
else
    SOURCE_GLOB="*w32*.deb"
    (( $LIBDVDCSS == 0 )) && SOURCE_GLOB="*386*.deb"
fi

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
DEB_PACKAGE=${FILE_LIST}

echo "
Note that this installation requires user input mid-way through to confirm
an End User License Agreement for installing font packages.  (Use the <tab>
key to jump between response fields, and <Enter> to select a response.)
"
sleep 3

PerformAppInstallation "-r" "$@"

# Workaround: Enable the 'partners' repo for APT...
#
sudo sed -r -i -e "/deb http.*partner/ s/# //" "${APT_DIR}/${APT_SOURCES_FILE}"

# Then install the more up-to-date Flashplugin:
#
PACKAGE_SET=${ADOBE_FLASH_PLUGIN_PKG}
PerformAppInstallation "-u"

#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'banshee' using the author's PPA repository.
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

GetOSversion
SET_NAME="Banshee"

USAGE="
Banshee is a cross-platform, open-source media player, called 'Sonance' until
2005.  Built upon Mono and Gtk#, it uses the GStreamer multimedia platform
for encoding and decoding various media formats, including Ogg Vorbis, MP3,
and FLAC.

Banshee can play and import audio CDs and supports many portable media
players, including Apple's iPod, Android devices, and Creative's ZEN players.
Other features include Last.fm integration, album artwork fetching, smart
playlists, and podcast support.

Banshee is released under the terms of the MIT License.  Stable versions are
available for many Linux distributions, as well as a beta preview for OS X
and an alpha preview for Windows.

For more information, see
    http://banshee.fm/
"

POST_INSTALL="
    You will need to install the multi-media package in order to use
    some of the features of ${SET_NAME}.
"

PACKAGE_SET="banshee  ppa-purge  "

if (( MAJOR < 14 || MAJOR > 15 )); then

    PACKAGE_SET="${PACKAGE_SET}}  banshee-community-extensions  "
fi

PerformAppInstallation "$@"

: <<'COMMENT'
if (( MAJOR > 15 )); then

    echo "You must install Banshee from the tarball located in '../banshee' ! "
    exit ${CMDFAIL}
fi

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL="ppa:banshee-team/ppa"
REPO_GREP="banshee.*team.*${DISTRO}"

PerformAppInstallation "-r" "$@"

if [[ ${1} == "-p" ]]; then exit; fi

InstallComplete

COMMENT

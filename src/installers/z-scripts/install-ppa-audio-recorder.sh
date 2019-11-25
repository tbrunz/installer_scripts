#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'audio-recorder' using the author's PPA repository.
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

USAGE="
This is an audio recorder application for the GNOME 3 and Ubuntu Unity
desktop environments.

This program allows you to record music and audio to a file.  It can record
audio from your soundcard, microphones, browsers, webcams, and more.  It can
also record your Skype/Ekiga/GoogleTalk calls automatically.  Put simply,
if it plays out of your loudspeakers, you can record it.

It has an advanced timer that can:
* Start, stop or pause recording at a given clock time.
* Start, stop or pause after a time period.
* Stop when the recorded file size exceeds a limit.
* Start recording on voice or sound (the user can set the audio threshold).
* Stop or pause recording on 'silence' (user can set the threshold & delay).

The recording can be atomatically controlled by MPRIS2-compatible media
players.  It can also record all your VOIP calls without user interaction.

This program supports several audio (output) formats such as OGG audio,
Flac, MP3, and WAV.

For more information, see
    https://launchpad.net/~osmoma/+archive/audio-recorder
"

SET_NAME="audio-recorder"
PACKAGE_SET="audio-recorder  ppa-purge  "

#
# The original PPA for this package is good for Ubuntu up to 14.10...
# For Ubuntu 15.04 onward, there is a new PPA that must be used.
#
GetOSversion

if (( MAJOR > 14 )); then

    # If this system were upgraded from < 15.04 and was using the old PPA,
    # then it needs to be removed first.  Attempt to remove the old repo,
    # but ignore any error thrown if it does not exist.
    #
    QualifySudo
    echo "Attempting to remove old ${SET_NAME} PPA repository... "
    echo
    sudo add-apt-repository --remove ppa:osmoma/audio-recorder

    REPO_NAME="${SET_NAME} (PPA)"
    REPO_URL="ppa:audio-recorder/ppa"
    REPO_GREP="audio-recorder.*${DISTRO}"
else
    REPO_NAME="${SET_NAME} (PPA)"
    REPO_URL="ppa:osmoma/audio-recorder"
    REPO_GREP="osmoma.*audio-recorder.*${DISTRO}"
fi

PerformAppInstallation "$@"

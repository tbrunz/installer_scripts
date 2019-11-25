#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install GoogleTalk Browser Plug-in
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
Install the GoogleTalk plugin in order to provide GoogleTalk capability within
Gmail to provide voice and video conversations from your computer.

Note that 'GoogleTalk' is now deprecated in preference to Google 'Hangouts',
and is itself an update to 'Chat'.  You may still wish to install it in order
to make voice calls from Gmail, however, rather than using Google+.

https://www.google.com/tools/dlpage/hangoutplugin

This script installs the latest version by adding the GoogleTalk repo.
"

SET_NAME="GoogleTalk plugin"
PACKAGE_SET="google-talkplugin  "

SIGNING_KEY=https://dl-ssl.google.com/linux/linux_signing_key.pub

REPO_NAME="${SET_NAME}"
REPO_URL="deb http://dl.google.com/linux/talkplugin/deb/ stable main"
REPO_GREP="google.com.*linux.*talkplugin.*deb"

PerformAppInstallation "$@"

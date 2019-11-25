#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the wallpaper changer 'variety' using the author's PPA repository.
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
Variety changes the desktop wallpaper on a regular basis, using user-specified
or automatically downloaded images.

Variety sits conveniently as an indicator in the panel and can be easily paused
and resumed.  The mouse wheel can be used to scroll wallpapers back and forth
until you find the perfect one for your current mood.

In addition to displaying images from local folders, several different online
sources can be used to fetch wallpapers according to user-specified criteria.

Variety can also automatically apply various filters to the images displayed --
charcoal painting, oil painting, heavy blurring, etc. -- so that your desktop is
always fresh and unique.

With Variety you'll get cool, fresh wallpapers throughout the day.  From the
App Indicator you can quickly switch to the next (random) wallpaper or copy a
wallpaper to your favorites, for later use.

Variety was developed by Peter Levi as part of the Ubuntu App Showdown in 2012.
"

SET_NAME="variety"
PACKAGE_SET="variety  trash-cli  ppa-purge  "

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL="ppa:peterlevi/ppa"
REPO_GREP="peterlevi.*ppa.*${DISTRO}"

PerformAppInstallation "$@"

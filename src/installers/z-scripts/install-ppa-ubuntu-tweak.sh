#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Ubuntu Tweak (from PPA)
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
Unity Tweak Tool is an alternative application (part of the Ubuntu repository)
that does the same thing, but is arranged differently with a different set of
configuration controls.  Unity Tweak Tool is only available in Ubuntu 13.04 and
later.)

Ubuntu Tweak is an application (from a PPA) to configure Ubuntu/Unity to make
it easier to use.  It provides many useful desktop and system options that the
default desktop environment doesn't provide.  Unfortunately, it does not work
with 'systemd', which replaced Upstart beginning with Ubuntu 15.04 (Wily).

Consequently, this script also installs 'dconf-editor', a GUI for 'gsettings',
which allows manual tweaking of some of the interface settings that Ubuntu Tweak
sets (such as 'menus have icons').

You may wish to experiment with these tools (in Unity); unfortunately, neither
tweak tool will work with Gnome Shell.

http://ubuntu-tweak.com/
"

POST_INSTALL="
 To set 'menus have icons', run 'dconf editor' from the Dash, then surf to
'org > gnome > desktop > interface' and search for 'menus-have-icons'.
"

SET_NAME="Ubuntu Tweak Tools"
PACKAGE_SET="dconf-editor  "

# As of 18.04, Ubuntu is now Gubuntu, Ubuntu with Gnome: No Unity tools...
#
if (( MAJOR > 17 )); then

    PACKAGE_SET="${PACKAGE_SET}  gnome-tweaks  "
    
    PerformAppInstallation "$@"
    exit $?
fi

# 'Ubuntu Tweak' is not available in 16.04 (last maintenance was for 14.04).
#
if (( MAJOR < 16 )); then

    PACKAGE_SET="ubuntu-tweak  "

    REPO_NAME="${SET_NAME} (PPA)"
    REPO_URL="ppa:tualatrix/ppa"
    REPO_GREP="tualatrix.*${DISTRO}"
fi

# If installing in 12.04, we must skip the 'unity-tweak-tool' package.
#
if (( MAJOR > 12 )); then

    PACKAGE_SET="${PACKAGE_SET}  unity-tweak-tool  "
fi

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

Exit_if_OS_is_ChromeOS "${APP_SCRIPT}"
Exit_if_OS_is_GalliumOS "${APP_SCRIPT}"

RESULT=$( echo ${DESKTOP_SESSION} )
if [[ "${RESULT}" =~ gnome ]]; then
    ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
            "This application is not compatible with Gnome Shell !"
fi

if [[ "${RESULT}" =~ xfce ]]; then
    ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
            "This application is not compatible with Xfce !"
fi

PerformAppInstallation "$@"

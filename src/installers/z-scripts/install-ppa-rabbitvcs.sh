#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the RabbitVCS ("TortoiseSVN for Linux") suite from PPA
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
RabbitVCS is a set of graphical tools written to provide simple &
straightforward access to the version control systems you use.
Currently, it is integrated into the Nautilus file manager, the Gedit
text editor, and supports Subversion, Git, and Mercurial, with a goal
to incorporate other version control systems as well as other file
managers.

It is inspired primarily by TortoiseSVN.

RabbitVCS is Free/Open Source Software written in the Python language
and is based on the PyGTK library.

http://rabbitvcs.org/
"

SET_NAME="RabbitVCS"
PACKAGE_SET=""

# 'rabbitvcs' is now available in the main repositories for 16.04.
#
if (( MAJOR > 15 )); then

PACKAGE_SET="${PACKAGE_SET}
rabbitvcs-core  rabbitvcs-cli  rabbitvcs-gedit  rabbitvcs-nautilus  "
else
PACKAGE_SET="${PACKAGE_SET}
rabbitvcs-core  rabbitvcs-cli  rabbitvcs-gedit  rabbitvcs-nautilus3
python-nautilus  python-configobj  python-gtk2  python-glade2
python-svn  python-dbus  python-dulwich  python-fastimport  meld
ppa-purge  "

    REPO_NAME="${SET_NAME} (PPA)"
    REPO_URL="ppa:rabbitvcs/ppa"
    REPO_GREP="rabbitvcs.*${DISTRO}"
fi

#
# Invoked with the '-p' switch?
#
if [[ -z "${1}" || "${1}" == "-p" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

#
# Only works with Ubuntu
#
Exit_if_OS_is_ChromeOS "${APP_SCRIPT}"
Exit_if_OS_is_GalliumOS "${APP_SCRIPT}"

#
# Verify that Subversion has been installed already:
#
svn --version &>/dev/null

if (( $? > 0 )); then

    MSG="${SET_NAME} is dependent on Subversion, which has not been installed. "

    if [[ -z "${1}" ]]; then

        USAGE=$( printf "%s \n \n%s \n \n" "${USAGE}" "${MSG}" )
        set --
    else
        ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" "${MSG}"
    fi
fi

PerformAppInstallation "-r" "$@"

echo
echo "Installation of the '${SET_NAME}' package set is complete. "
echo
echo "Nautilus needs to be restarted to complete installation. "
echo
read -r -s -n 1 -p "Press any key to restart Nautilus, <Ctrl-C> to quit: "
echo

# Restart Nautilus in order to integrate its context menu:
#
nautilus -q
pgrep -f service.py 1>/dev/null && pgrep -f service.py | xargs kill
nohup nautilus &>/dev/null &

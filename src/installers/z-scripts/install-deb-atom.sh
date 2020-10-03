#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install GitHub's Atom Editor
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
Atom is a free and open-source text and source code editor for MacOS, Linux,
and Windows with support for plug-ins written in Node.js, and embedded Git
Control, developed by GitHub.

Atom is a desktop (GUI) application built using web technologies.  Most of
the extending packages have free software licenses and are community-built
and maintained.  Atom is based on Electron (formerly known as Atom Shell),
a framework that enables cross-platform desktop applications using Chromium
and Node.js.  It is written in CoffeeScript and Less.

Atom was released from beta, as version 1.0, on June 25, 2015.

Atom's developers call it a 'hackable text editor for the 21st Century'.
It can be used as an integrated development environment (IDE).

https://atom.io/
https://github.com/bemeurer/beautysh
"

SET_NAME="Atom Editor"
PACKAGE_SET="gconf2  gconf-service  shellcheck
    python-pip  python3-pip  "

GetOSversion
#
# Atom requires libcurl3 or libcurl4; however, the host distro
# determines which one is available to install...
#
if (( MAJOR > 16 )); then
    PACKAGE_SET="${PACKAGE_SET}  libcurl4  "

    if (( MAJOR > 19 )); then
	ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
	    "Cannot install in 20.04+; use 'install-atom' instead. "
    fi
else
    PACKAGE_SET="${PACKAGE_SET}  libcurl3  "
fi

# Atom requires 64-bit for Linux...
#
[[ ${ARCH} != "x86_64" ]] && ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Atom is only supported on Linux for 64-bit; Try 'geany' instead ! "

#
# Verify that Git has been installed already:
#
git --version >/dev/null 2>&1

if (( $? > 0 )); then

    MSG="${SET_NAME} is dependent on Git, which has not been installed. "

    if [[ -z "${1}" ]]; then

        USAGE=$( printf "%s \n \n%s \n \n" "${USAGE}" "${MSG}" )
        set --
    else
        ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" "${MSG}"
    fi
fi

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

SOURCE_DIR="../editors/atom"
SOURCE_GLOB="atom-amd64.deb"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
DEB_PACKAGE=${FILE_LIST}

PerformAppInstallation "-r" "$@"

QualifySudo
sudo -H pip  install beautysh
sudo -H pip3 install beautysh

InstallComplete

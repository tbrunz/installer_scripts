#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Atom in a snap package
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

SET_NAME="Atom Editor (snap)"

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

#
# Requires a snap package install
#
QualifySudo
sudo snap install atom --classic

#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'diodon' clipboard manager using the author's PPA repository.
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
Diodon is a lightweight clipboard manager for Linux written in Vala which 'aims
to be the best integrated clipboard manager for the Gnome/GTK+ desktop'.

It doesn't have as many features as Glippy, Pastie, and so on but it's a lot
lighter and uses less than 3MB of RAM.

Diodon features include an Ubuntu indicator, clipboard sync (primary selection
and Ctrl+C / Ctrl+V clipboard), and an option to set the clipboard size.

Diodon gives you a list of the last N things you've copied to the clipboard,
which you can see/select from for pasting by clicking an an icon of a paperclip
in the app indicator bar.
"

SET_NAME="diodon"
PACKAGE_SET="diodon  diodon-plugins  ppa-purge  "

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL="ppa:diodon-team/stable"
REPO_GREP="diodon.*team.*${DISTRO}"

PerformAppInstallation "$@"

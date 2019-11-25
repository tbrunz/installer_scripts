#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Subversion
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
Apache Subversion (often abbreviated SVN, after the command name 'svn') is
a software versioning and revision control system distributed under an open
source license.  Developers use SVN to maintain current and historical
versions of files such as source code, web pages, and documentation.  Its
goal is to be a mostly-compatible successor to the widely-used Concurrent
Versions System (CVS).

This script will install either the current Ubuntu repository version of
Apache Subversion, or will backport Subversion (1.7.x or later) from the
repository of a more recent version of Ubuntu.

This resolves an issue with Subversion v1.6.x, which drops '.svn' folders
into EVERY folder of a working copy.  Version 1.7 & later put only ONE
'.svn' folder in the root of the working copy.

Ubuntu 12.04 installs v1.6.17, whereas the repositories for Ubuntu 12.10
and later contain v1.7.x, which can be backported to 12.04.  This script
sets up the repositories and performs a backport installation from the
latest repositories.

Note that if you install Subversion with this script and you also plan to
install the Apache Web Server ('Apache2'), you will need to install
'Apache2' using the 'install-apache' script, since Apache2 will also need
to be backported to avoid dependency issues.
"

POST_INSTALL="
    If you plan to run the Apache Web Server, you will need to install it
    using the 'apache' installer (part of this installer set), which will
    similarly backport AWS in order to prevent library dependency problems.
"

# Current backport is from 13.10 to any earlier version:
#
GetOSversion
#if [[ ${MAJOR} -lt 13 ]]; then
#
#    BACKPORT_DISTRO="quantal"
#fi

SET_NAME="Subversion"
PACKAGE_SET="subversion  subversion-tools  "

PerformAppInstallation "-r" "$@"

[[ -z "${BACKPORT_DISTRO}" ]] && exit

InstallComplete

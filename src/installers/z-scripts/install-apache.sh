#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the Apache Web Server
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
The Apache HTTP Server (commonly referred to as 'Apache') is an HTTP web
server program typically run on a Unix-like operating system, having been
developed for use on Linux.

Apache is developed and maintained by an open community of developers
under the auspices of the Apache Software Foundation.  The application
is available for a wide variety of operating systems, including Unix,
FreeBSD, Linux, Solaris, Novell NetWare, OS X, Microsoft Windows, OS/2,
TPF, and eComStation.  Released under the Apache License, Apache is open-
source software.

Since April 1996, Apache has been the most popular HTTP server software
in use on the Internet.  As of June 2013, Apache was estimated to serve
54% of all active websites and 53% of the top servers across all domains.

Note that the repositories for older versions of Ubuntu contain versions
of Apache that may cause dependency issues when trying to install other
packages (such as SVN or Bloodhound) that require specific Apache web
server libraries.

Therefore, this script sets up the repos for backporting and installs the
latest version.
"

SET_NAME="Apache Web Server"
PACKAGE_SET="apache2  apache2-doc  libapache2-mod-wsgi  "

# Will backport if Ubuntu version is 13.10 or earlier:
#
GetOSversion
if (( MAJOR < 14 )); then

    BACKPORT_DISTRO="trusty"
fi

PerformAppInstallation "$@"

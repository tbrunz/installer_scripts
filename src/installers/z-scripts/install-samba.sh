#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Samba (SMB/CIFS) and supporting packages
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
Samba is a free software re-implementation of the SMB/CIFS networking
protocol, originally developed by Andrew Tridgell.  As of version 3, Samba
provides file and print services for various Microsoft Windows clients and
can integrate with a Windows Server domain, either as a Primary Domain
Controller (PDC) or as a domain member.  It can also be part of an Active
Directory domain.

Samba runs on most Unix and Unix-like systems, such as Linux, Solaris, AIX,
and the BSD variants, including Apple's Mac OS X Server and Mac OS X client
(version 10.2 and greater).  Samba is standard on nearly all distributions
of Linux and is commonly included as a basic system service on other Unix-
based operating systems as well.  Samba is released under the terms of the
GNU General Public License.  The name Samba comes from SMB (Server Message
Block), the name of the standard protocol used by the Microsoft Windows
network file system.

https://www.samba.org/
"

SET_NAME="Samba/CIFS"
PACKAGE_SET="samba  smbclient  cifs-utils  smbc  winbind  "

GetOSversion

# Note that 16.04 does not have a SAMBA password sync package...
#
if (( MAJOR > 14 )); then

    PerformAppInstallation "$@"
    exit $?
fi

PerformAppInstallation "-r" "$@"

echo
Get_YesNo_Defaulted -y \
        "Should the system automatically synchronize user->samba passwords?"

if (( $? > 0 )); then

    InstallComplete
    exit $?
fi

PACKAGE_SET="libpam-smbpass  "

PerformAppInstallation "$@"

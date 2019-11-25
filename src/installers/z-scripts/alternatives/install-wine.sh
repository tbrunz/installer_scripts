#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install WINE from the repository
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
This script installs the default version of Wine from the distro repositories.
The PPA version of this script will install a more up-to-date version.  Note
that the Pipelight script will install Wine as a dependency; this script will
conflict with that, so install either Pipelight or Wine, but not both.

Wine is a free and open source software application that allows applications
designed for Microsoft Windows to run on Unix-like operating systems.  Wine
also provides a software library, known as Winelib, against which developers
can compile Windows applications to help port them to Unix-like systems.

Wine is a compatibility layer.  It duplicates functions of Windows by providing
alternative implementations of the DLLs that Windows programs call, as well as
a process to substitute for the Windows NT kernel.  This method of duplication
differs from other methods that might also be considered emulation, where
Windows programs run in a virtual machine.  Wine is predominantly written using
'black-box testing' reverse-engineering to avoid copyright issues.

In Wine, the Windows app's compiled x86 code runs at full native speed on the
computer's x86 processor, just as it does when running under Windows.  Windows
API calls and services are not emulated either, but rather substituted with
Linux equivalents that are compiled for x86 and run at full, native speed.

In a 2007 survey by desktoplinux.com of 38,500 Linux desktop users, 31.5% of
respondents reported using Wine to run Windows applications.  This plurality
was larger than all x86 virtualization programs combined, as well as larger
than the 27.9% who reported not running Windows applications.

http://www.winehq.org/
"

POST_INSTALL="
    To configure Wine, search for the Wine configuration tool,
    'configure wine' using the Dash.
"

SET_NAME="Wine (repo)"
PACKAGE_SET="wine  "

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

INST_VERS=$( wine --version 2>/dev/null | \
        egrep -o '[[:digit:]]+[.][[:digit:]]' )

if (( $? == 0 )); then

    Get_YesNo_Defaulted -y \
"Wine version ${INST_VERS} is already installed.
Co-installing multiple versions of wine is not recommended.
Continue?"
fi

(( $? > 0 )) && exit

: <<__COMMENT
Get_YesNo_Defaulted -y \
"Be aware that 'pipelight' installs its own customized version of 'wine',
and that co-installing multiple versions of wine is not recommended.
Do you intend to install 'pipelight'?"

(( $? == 0 )) && exit
__COMMENT

echo "
Note that this installation requires user input mid-way through to confirm
an End User License Agreement for installing font packages.  (Use the <tab>
key to jump between response fields, and <Enter> to select a response.)
"
sleep 3

PerformAppInstallation "$@"

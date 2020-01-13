#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the latest WINE from the PPA
# ----------------------------------------------------------------------------
#

INCLUDES="core-install.bash"

if [[ -f "${INCLUDES}" ]]; then source "${INCLUDES}"
else
    echo -n "$( basename "${0}" ): error: "
    echo    "Could not source the '${INCLUDES}' file ! "
    exit
fi

#
# 'winetricks' is installable from the Ubuntu repos, but is OLD...
# Install it, but install it from the developer's GitHub repo.
#
WINETRICKS_FILENAME=winetricks

WINETRICKS_GITHUB_REPO=https://raw.githubusercontent.com
WINETRICKS_URL=${WINETRICKS_GITHUB_REPO}/Winetricks/winetricks/master/src

#
# Wine channel types are "stable", "devel", and "staging"; Default one:
#
SUGGEST_VERSION="staging"

GetScriptName "${0}"
GetOSversion

USAGE="
This script installs the latest stable version of Wine from the WineHQ PPA.
Note that the Pipelight script will install Wine as a dependency; this script
will conflict with that, so install either Pipelight or Wine, but not both.

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

This package installs a bonus app, 'Wine Launcher Creator', which can be used
to extract icon files from an EXE or to add an icon file when creating a
launcher for a Wine app that isn't installed by running an installer app.
Refer to the README file in the 'crossover' folder for details on using this
tool.

http://www.winehq.org/
https://code.google.com/archive/p/wine-launcher-creator/
"

POST_INSTALL="
Note that 'Wine Launcher Creator' has also been installed; Refer to
'http://code.google.com/p/wine-launcher-creator/', or to the README
file in the 'wine' folder in this installer repo for more information.

"

SET_NAME="Wine (PPA)"

#
# No parameters?  Show the usage prompt and quit:
#
PKG_VERSION="${SUGGEST_VERSION}"

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

#
# Invoked with the '-p' switch?
#
if [[ ${1} == "-p" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

#
# The user must tell us which Wine channel they want to install,
# And must also include the 'update' switch...
#
PKG_VERSION=${1}
shift

printf "%s" "${PKG_VERSION}" | egrep '^(stab|deve|stag)' >/dev/null

if [[ -z "${1}" || "${1}" == "-i" ]]; then
    PKG_VERSION="${SUGGEST_VERSION}"
    PerformAppInstallation "$@"
fi

#
# Normalize the wine channel selected to the name the repo uses:
#
WINE_CHANNEL=${PKG_VERSION:0:4}

case ${WINE_CHANNEL,,} in
stab )
    WINE_CHANNEL="stable"
    ;;
stag )
    WINE_CHANNEL="staging"
    ;;
deve )
    WINE_CHANNEL="devel"
    ;;
* )
    WINE_CHANNEL=
    ;;
esac

[[ ${WINE_CHANNEL} ]] || ThrowError "${ERR_BADSWITCH}" "${APP_SCRIPT}" \
        "Bad wine channel, '${PKG_VERSION}'! (Use stable|staging|devel). "

#
# Determine if we already have a version of wine installed...
#
INST_VERS=$( wine --version 2>/dev/null | \
        egrep -o '[[:digit:]]+[.][[:digit:]]' )

if [[ "${INST_VERS}" ]]; then

    Get_YesNo_Defaulted -n \
"Wine version ${INST_VERS} is already installed.
Co-installing multiple versions of wine is not recommended.
Continue?"
fi

#
# If the test above fails (i.e., 'wine' is not installed), then the user will
# not be queried... But the bash 'test' will succeed, so $? will end up 0!
#
# However, if the test above succeeds, (i.e, 'wine' was already installed),
# we query the user, and the resulting answer sets $?: Only 'y' returns 0...
#
(( $? == 0 )) || exit

###########################
: <<__COMMENT
Get_YesNo_Defaulted -y \
"Be aware that 'pipelight' installs its own customized version of 'wine',
and that co-installing multiple versions of wine is not recommended.
Do you intend to install 'pipelight'?"

(( $? == 0 )) && exit

echo "
Note that this installation requires user input mid-way through to confirm
an End User License Agreement for installing font packages.  (Use the <tab>
key to jump between response fields, and <Enter> to select a response.)
"
sleep 3
__COMMENT
###########################

PACKAGE_SET="ppa-purge  "

#
# If installing on a 64-bit system, then we need to add the 32-bit repo:
#
if [[ ${ARCH} == "x86_64" ]]; then

    QualifySudo
    sudo dpkg --add-architecture i386
fi

#
# Install the SDL2 backport (Ubuntu dropped 'libfaudio0' from its repos):
#
if (( MAJOR > 16 )); then
    REPO_NAME="sdl2-backport"
    REPO_URL="ppa:cybermax-dexter/sdl2-backport"
    REPO_GREP="cybermax-dexter.*ubuntu.*${DISTRO}"
fi

PerformAppInstallation "-r" "$@"

#
# NOW install Wine...
#
PACKAGE_SET="--install-recommends  
winehq-${WINE_CHANNEL}  wine-${WINE_CHANNEL}  wine-${WINE_CHANNEL}-i386  
icoutils  python-qt4  "

#SIGNING_KEY=https://dl.winehq.org/wine-builds/Release.key
SIGNING_KEY=../wine/winehq.key

REPO_NAME="${SET_NAME}"
REPO_URL="https://dl.winehq.org/wine-builds/ubuntu/"
REPO_GREP="winehq.org.*ubuntu.*${DISTRO}"

#
# Include installation of the Wine Launcher Creator application:
#
SOURCE_DIR="../wine"

SOURCE_GLOB="*deb"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
DEB_PACKAGE=${FILE_LIST}

PerformAppInstallation "-r" "$@"

#
# Wine may fail for lack of i386 packages...  Fix it:
#
QualifySudo
sudo apt-get install -f

###############################################################################
#
# Install 'winetricks' from the GitHub repo (to get the latest)
#
# First, we need to determine where the 'wine' executable is, and
# install 'winetricks' in the same directory:
#
WHICH_WINE_PATH=$( which wine )
WHICH_WINE_DIR=$( dirname "${WHICH_WINE_PATH}" )

[[ -x "${WHICH_WINE_PATH}" ]] || ThrowError "${ERR_FILEIO}" \
        "${APP_SCRIPT}" "Cannot locate the Wine executable !"

#
# This is (typically) a soft-linked file; find the actual executable file.
# If it IS the actual executable, then 'readlink' returns nothing.
#
WINE_EXE_PATH=$( readlink "${WHICH_WINE_PATH}" || echo "${WHICH_WINE_PATH}" )
WINE_EXE_DIR=$( dirname "${WINE_EXE_PATH}" )

#
# Change to the directory with the actual executable & download 'winetricks':
#
cd "${WINE_EXE_DIR}"

sudo wget ${WINETRICKS_URL}/"${WINETRICKS_FILENAME}"

sudo chmod +x "${WINETRICKS_FILENAME}"

#
# Finally, set a parallel softlink in the same location as the wine link,
# but only do this if 'which wine' actually returns a softlink:
#
if [[ $( readlink "${WHICH_WINE_PATH}" ) ]]; then

    sudo ln -sf "${WINE_EXE_DIR}"/"${WINETRICKS_FILENAME}" "${WHICH_WINE_DIR}"
fi

###############################################################################

#
# Copy the wine icon
#
# If the wine launcher icon for some reason corrupts (displays an irrelevant
# wine or Crossover app icon incorrectly), then you can correct this by
# copying 'wine.svg' from '/usr/share/icons..' to '~/.local/share/icons'.
#
##### MAY NOT NEED TO DO THIS #####


InstallComplete

###############################################################################

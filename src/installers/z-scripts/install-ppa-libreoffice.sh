#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the latest LibreOffice from PPA packages
# ----------------------------------------------------------------------------
#

SUGGEST_VERSION=6.3

INSTALLED_DPKG_GREP="libreoffice.*core"
APT_PKG_LOCATIONS="/etc/apt/sources.list /etc/apt/sources.list.d"

INCLUDES="core-install.bash"

if [[ -f "${INCLUDES}" ]]; then source "${INCLUDES}"
else
    echo -n "$( basename "${0}" ): error: "
    echo    "Could not source the '${INCLUDES}' file ! "
    exit
fi

GetScriptName "${0}"
GetOSversion


APT_DIR=/etc/apt
APT_SOURCES_DIR=${APT_DIR}/sources.list.d


USAGE="
This script installs the lastest stable version of LibreOffice from the
LibreOffice PPA.

LibreOffice is a powerful office suite; its clean interface and powerful tools
let you unleash your creativity and grow your productivity.  LibreOffice embeds
several applications that make it the most powerful Free & Open Source Office
suite on the market:

* Writer, the word processor,
* Calc, the spreadsheet application,
* Impress, the presentation engine,
* Draw, our drawing and flowcharting application,
* Base, our database and database frontend,
* Math for editing mathematics.

http://www.webupd8.org/2015/08/install-libreoffice-50-in-ubuntu-or.html
http://www.libreoffice.org/discover/libreoffice/
"

SET_NAME="LibreOffice (PPA)"
PACKAGE_SET="libreoffice  libreoffice-help-en-us  ppa-purge
libreoffice-lightproof-en  libreoffice-report-builder
libreoffice-sdbc-postgresql  libreoffice-mysql-connector
openclipart2-libreoffice  openclipart-libreoffice  pstoedit
crystalcursors  fonts-crosextra-caladea  fonts-crosextra-carlito fonts-stix
libreoffice-style-oxygen  libreoffice-style-tango  libreoffice-style-breeze
myspell-en-us  mythes-en-us  
"
#libreoffice-style-hicontrast  libreoffice-style-sifr

#
# Start with the assumption that the user doesn't provide a version;
# In this case, use the suggested version as a stand-in for 'usage':
#
PKG_VERSION=${SUGGEST_VERSION}

VERSION_MAJOR=$( printf "%s" "${PKG_VERSION}" | cut -d '.' -f 1 )
VERSION_MINOR=$( printf "%s" "${PKG_VERSION}" | cut -d '.' -f 2 )

REPO_NAME="${SET_NAME}"
# Note this "version-less" URL installs the latest *stable* version, not
# the alpha or beta releases.  The versioned URL provides direct control.
#REPO_URL="deb http://ppa.launchpad.net/libreoffice/ppa/ubuntu ${DISTRO} main"
REPO_URL="ppa:libreoffice/libreoffice-${VERSION_MAJOR}-${VERSION_MINOR}"
REPO_GREP=".*libreoffice.*${DISTRO}"

#
# Invoked with the '-p' or '-i' switch?
#
if [[ -z "${1}" || "${1}" == "-p" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

#
# The user must tell us which LibreOffice version they want to install,
# And must also include an 'update' switch (-n or -u)...
#
PKG_VERSION=${1}
shift

printf %s "${PKG_VERSION}" | \
        egrep '^[[:digit:]]+[.][[:digit:]]+$' >/dev/null

if (( $? != 0 )); then
    PKG_VERSION=${SUGGEST_VERSION}
    PerformAppInstallation
fi

if [[ -z "${1}" || ${1} == "-p" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

#
# At this point we have a desired version provided by the user;
# Use this 'X.Y' to (re)form the PPA name needed for the installation:
#
VERSION_MAJOR=$( printf "%s" "${PKG_VERSION}" | cut -d '.' -f 1 )
VERSION_MINOR=$( printf "%s" "${PKG_VERSION}" | cut -d '.' -f 2 )

if (( MAJOR < 18 && (VERSION_MAJOR > 6 || 
    (VERSION_MAJOR == 6 && VERSION_MINOR > 2) ) )); then

    ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
    "This distro does not have a repo for ${VERSION_MAJOR}.${VERSION_MINOR} !"
fi

REPO_URL="ppa:libreoffice/libreoffice-${VERSION_MAJOR}-${VERSION_MINOR}"

#
# Check this version against any installed version... If LibreOffice is already
# installed, and its major/minor version differs from this version, the install
# will merely re-install the current version -- even if the current version is
# purged first.  What's required is to purge any existing PPA first.
#
# The following will either return an empty string (not installed), or the
# full package name, which includes the version number string:
#
INSTALLED_VERSION=$( dpkg -l 2>&1 | \
        grep ${INSTALLED_DPKG_GREP} | awk '{ print $3 }')

#
# If there is no installed version, then we're done here; do the install...
#
[[ -z "${INSTALLED_VERSION}" ]] && PerformAppInstallation "$@"

#
# Otherwise, we should remove the installed version first (recommended).
# Determine what's installed, tell the user, and suggest what to do.
#
# The following grep result could be more than one 'hit', resulting in more
# than one line; Get just the first result and parse its fields:
#
read -r INSTALLED_VERSION < <( printf "%s" "${INSTALLED_VERSION}" | \
        egrep -o '[[:digit:]]+[.][[:digit:]]+[.][[:digit:]]+' )

#
# Now extract the major and minor version numbers from the version string:
#
INSTALLED_MAJOR=$( printf "%s" "${INSTALLED_VERSION}" | cut -d '.' -f 1 )
INSTALLED_MINOR=$( printf "%s" "${INSTALLED_VERSION}" | cut -d '.' -f 2 )

INSTALLED_VERSION=${INSTALLED_MAJOR}.${INSTALLED_MINOR}

[[ -z "${INSTALLED_MINOR}" ]] && INSTALLED_VERSION=${INSTALLED_MAJOR}

if [[ -n "${INSTALLED_VERSION}" ]]; then
    echo
    echo -n "Detected LibreOffice ${INSTALLED_VERSION} "
    echo    "is installed on this system. "
fi

if (( INSTALLED_MAJOR == VERSION_MAJOR && INSTALLED_MINOR == VERSION_MINOR ))
then
    echo "This is the same version that this script installs. "
else
    echo -n "This script installs version ${VERSION_MAJOR}.${VERSION_MINOR} "
    echo    "from a LibreOffice PPA. "
fi

#
# Now ask what to do...  If the answer is "no", proceed with the installation.
#
Get_YesNo_Defaulted -y "Remove the installed version first? (recommended)"

(( $? > 0 )) && PerformAppInstallation "$@"

#
# Otherwise, explain how to remove the installed version & quit so that
# the user can do so manually.  This script will need to be re-run to do
# the installation, and will then drop straight into the install procedure.
#
INSTALLED_REPO_NAME="libreoffice-${INSTALLED_MAJOR}-${INSTALLED_MINOR}"

grep -r --include '*.list' '^deb ' ${APT_PKG_LOCATIONS} | \
grep -q ${INSTALLED_REPO_NAME}

    if (( $? == 0 )); then

echo
echo
echo -n "Your current LibreOffice ${INSTALLED_MAJOR}.${INSTALLED_MINOR} "
echo -n "is installed from the "
echo    "LibreOffice-${INSTALLED_MAJOR}-${INSTALLED_MINOR} PPA. "
echo

echo -n "Use the 'PPA-Manager' app to purge the "
echo    "${INSTALLED_MAJOR}.${INSTALLED_MINOR} PPA repository/installation. "

echo "The PPA purge will downgrade LibreOffice to the repo version. "
echo

echo -n "Next, use ' sudo rm -rf ${APT_SOURCES_DIR}/libreoffice.*${DISTRO} ' "
echo "to remove the PPA. "
echo "Then use ' sudo apt-get purge libreoffice* ' to remove the repo version. "
echo
echo -n "Finally, re-run this script to add the "
echo    "${VERSION_MAJOR}.${VERSION_MINOR} PPA & install LibreOffice. "

    else

echo
echo "Your current LibreOffice is installed from the Ubuntu repository. "
echo
echo "Use ' sudo apt-get purge libreoffice* ' to remove the repo version. "
echo
echo -n "Then re-run this script to add the "
echo    "${VERSION_MAJOR}.${VERSION_MINOR} PPA & install LibreOffice. "

    fi

#####

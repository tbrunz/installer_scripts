#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the latest 'mawk' maintained by Tom Dickey
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

MAWK_PKG="mawk.tar.gz"
SOURCE_URL=http://invisible-island.net/datafiles/release/${MAWK_PKG}

AwkVersion() {
local AWK_VERSION
AWK_VERSION=$( ${1} -W version 2>&1 | egrep -i 'awk\b' \
                | grep '[[:digit:]][.][[:digit:]]' )

if [[ -z "${AWK_VERSION}" ]]; then
    printf "<not installed>"
else
    printf %s "${AWK_VERSION}"
fi
}

WhichAwk() {
AWK_VERSION="
You can check the version of AWK by entering '[m]awk -W version'.

Current versions:
 awk = $( AwkVersion awk )
mawk = $( AwkVersion mawk )
gawk = $( AwkVersion gawk )
"
}

WhichAwk

USAGE="
This script will download and install the latest version of 'mawk' from the
current maintainer's website,

    ${SOURCE_URL}

\"Michael's AWK\", or 'mawk', is the default AWK for Ubuntu.  It is named for
its author, Michael Brennan; when 'mawk' development fell dormant after 1996
(v1.3.3), Thomas Dickey adopted it and is now maintaining it.  He does not use
an Ubuntu PPA; his latest version must be downloaded as source and compiled.

After downloading completes, this script will automatically start compiling
(resulting in a VERY long & cryptic output!), then install as 'mawk'.

Note that the default 'awk' (which is always a link) will remain pointing
to the distro-installed 'awk', which is 'mawk' version 1.3.3.  To invoke
this updated version of 'mawk', invoke it as 'mawk', not 'awk'.
${AWK_VERSION}"

SET_NAME="mawk (from PPA)"
unset PACKAGE_SET

PerformAppInstallation "-r" "$@"

# Create a temporary directory we can download to & do the build:
#
QualifySudo
maketmp -d
chgdir "${TMP_PATH}"

# Download & do a check to be sure that we actually have it:
#
wget "${SOURCE_URL}"

if [[ $? -ne 0 || ! -e "${MAWK_PKG}" ]]; then
    cd /
    sudo rm -rf "${TMP_PATH}"
    ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
            "Could not download the 'mawk' package ! "
fi

# Uncompress & expand the tarball package:
#
tar_zip "gz" "${MAWK_PKG}"
chgdir mawk-*

# Run the sequence of 'make' apps to build & install:
#
sudo sh ./configure
sudo make
sudo make check
sudo make install

# Remove the build directory:
#
cd /
sudo rm -rf "${TMP_PATH}"

WhichAwk
printf "%s\n" "${AWK_VERSION}"

InstallComplete

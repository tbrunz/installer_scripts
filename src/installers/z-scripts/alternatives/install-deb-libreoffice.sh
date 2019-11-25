#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the latest LibreOffice from tgz deb packages
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
This script installs LibreOffice from a .deb tarball downloaded from the
LibreOffice website.  While these are typically newer than what's in the Ubuntu
repos, the newest versions are in the LibreOffice PPA, and are installed using
the PPA version of this script (recommended).

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

http://www.libreoffice.org/discover/libreoffice/
"

SET_NAME="LibreOffice (deb)"
PACKAGE_SET=""

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

GetOSversion
if [[ ${ARCH} == "x86_64" ]]; then

    SOURCE_GLOB="*_x86-64_*tar.gz"
else
    SOURCE_GLOB="*_x86_*tar.gz"
fi

SOURCE_DIR="../libreoffice"
ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

# Make a temporary directory and copy all the matching tarballs into it...
#
maketmp -d

for TARBALL in "${FILE_LIST[@]}"; do
    copy "${TARBALL}" "${TMP_PATH}"
done

# Untar & make a list of deb files to install...
#
cd "${TMP_PATH}"

    SOURCE_GLOB="LibreOffice*"
    ResolveGlobFilename "basename" "." 1 "${SOURCE_GLOB}"

    for TARBALL in "${FILE_LIST[@]}"; do
        tar_zip gz "${TARBALL}"
    done

    SOURCE_GLOB="*deb"
    ResolveGlobFilename "fullpath" "${TMP_PATH}" 3 "${SOURCE_GLOB}"

cd - 2>/dev/null

DEB_PACKAGE=${FILE_LIST}

PerformAppInstallation "-r" "$@"

sudo rm -rf "${TMP_PATH}"

InstallComplete

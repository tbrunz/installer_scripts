#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install latest gawk
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
This script will install gawk, either from source, from the repo, or, for
Ubuntu versions before 'trusty', as a backpart.  ('gawk' is not installed
by default on Ubuntu; 'mawk' is the default version.)

After installation, the default 'awk' (which is always a link) will be
changed to point to this version of 'gawk'.  (The distro installation is
'mawk' version 1.3.3.)
${AWK_VERSION}"

SET_NAME="gawk (GNU awk)"
PACKAGE_SET="gawk-doc  "

APP_NAME="gawk"

CONFIG_OPTIONS="--sysconfdir=/etc"

# Just display the usage prompt?
#
[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

Get_YesNo_Defaulted -y "Do you want to install the latest from source?"

if (( $? > 0 )); then

    # Backport from the current to any earlier version:
    #
    GetOSversion
    if (( MAJOR < 14 )); then

        BACKPORT_DISTRO="trusty"
    fi

    PACKAGE_SET="${PACKAGE_SET}  gawk  "

    PerformAppInstallation "-r" "$@"
else

    # Verify that the install package tarball is present:
    #
    SOURCE_DIR="../${APP_NAME}"
    SOURCE_GLOB="${APP_NAME}*gz"
    BUILD_DIR="${APP_NAME}*"

    # On detecting the tarball, set GAWK_PKG_PATH to be the path to this file:
    #
    ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
    GAWK_PKG_PATH=${FILE_LIST}

    [[ -e "${GAWK_PKG_PATH}" ]] || ThrowError "${ERR_CMDFAIL}" \
            "${APP_SCRIPT}" "Could not find the '${APP_NAME}' package ! "

    PerformAppInstallation "-r" "$@"

    # Create a temporary directory we can use to do the build:
    #
    QualifySudo
    maketmp -d
    BUILD_PATH="${TMP_PATH}"

    # Copy the builder tarball to the temp directory:
    #
    echo
    copy ${GAWK_PKG_PATH} ${BUILD_PATH}

    # Uncompress & expand the tarball package:
    #
    chgdir "${BUILD_PATH}"
    tar_zip "gz" ${SOURCE_GLOB}
    chgdir ${BUILD_DIR}

    # Run the sequence of 'make' apps to build & install:
    #
    sh ./configure ${CONFIG_OPTIONS}
    (( $? > 0 )) && \
            ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
            "Could not configure '${APP_NAME}' for building ! "

    make
    (( $? > 0 )) && \
            ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
            "Could not build the '${APP_NAME}' application ! "

    make check
    (( $? > 0 )) && \
            ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
            "'${APP_NAME}' did not build correctly ! "

    sudo make install
    (( $? > 0 )) && \
            ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
            "Could not install the '${APP_NAME}' application ! "

    # Remove the build directory:
    #
    cd /
    sudo rm -rf "${TMP_PATH}"
fi

WhichAwk
printf "%s\n" "${AWK_VERSION}"

InstallComplete

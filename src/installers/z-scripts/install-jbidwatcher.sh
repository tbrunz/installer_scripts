#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# jBidWatcher - Ebay auction sniping application (Java)
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

SET_NAME="jBidWatcher"
PACKAGE_SET=""
[[ "${FLAVOR}" != "xfce" ]] && PACKAGE_SET="alacarte  "

APP_NAME="jbidwatcher"
INSTALL_DIR="/opt/${APP_NAME}"

SOURCE_DIR="../jbidwatcher"
CheckGlobFilename "basename" "${SOURCE_DIR}" 1 "*.jar"

SYSTEM_LAUNCHER_DIR=/usr/share/applications

USAGE="
JBidWatcher is an eBay sniping tool that enables you to automatically place
last-moment eBay bids without having to use eBay's own bidding system (which
could potentially encourage other bids, needlessly running up the price).

Since JBidWatcher runs on your own computer and places bids directly from it,
it is not necessary for JBidWatcher.com to know your eBay login or password.
And since the application is open-source, it is secure, in that no personal
information is sent to any party other than eBay during the sniping process.

JBidWatcher supports group sniping (also known as contingency sniping), in
which you place snipes for multiple similar items, all of which are all
cancelled as soon as you win any one of them.

JBidWatcher is written in Java; you will need to visit the JBidWatcher website
to get updates for its '.jar' file:

http://www.jbidwatcher.com/
"

: << COMMENT
POST_INSTALL="
To make a menu launcher:

    Search for the application 'alacarte' (in 'Main Menu')
    Click on 'Internet'
    Click 'New Item' and set the following:

        Type = 'Application'
        Name = jBidWatcher
        Command = java -Xmx512m -jar ${INSTALL_DIR}/${FILE_LIST}
        Comment = Ebay auction sniper

    Load the icon using ${INSTALL_DIR}/${APP_NAME}.png

Note that you will need to log out and log back in for the Dash to find
the app.
"
COMMENT

#
# Verify that Java has been installed already:
#
java -version >/dev/null 2>&1

if (( $? > 0 )); then

MSG="This ${SET_NAME} is dependent on Java, which has not been installed. "

    if [[ -z "${1}" || "${1}" == "-i" ]]; then

        USAGE=$( printf "%s \n \n%s \n \n" "${USAGE}" "${MSG}" )
        set --
    else
        ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" "${MSG}"
    fi
fi

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

#
# Ensure that the needed files are present in our repo before installing;
#
# Note that on failure, the 'check' routine will throw a warning error &
# return, whereas the 'resolve' routine will throw an error and quit.
# Therefore, if the first fails and the second passes, we must exit manually.
#
CheckGlobFilename "basename" "${SOURCE_DIR}" 1 "*.png"
JBID_CHECK=$?

ResolveGlobFilename "basename" "${SOURCE_DIR}" 1 "*.jar"
(( $JBID_CHECK > 0 )) && exit

PerformAppInstallation "-r" "$@"

#
# Create the installation directory (owned by root) &
# copy files to the installation directory:
#
QualifySudo
makdir "${INSTALL_DIR}"

copy "${SOURCE_DIR}"/* "${INSTALL_DIR}"/

sudo chmod a+rX "${INSTALL_DIR}"/*

SOURCE_GLOB="*.jar"
ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

JAR_FILE_PATH=${FILE_LIST}
sudo chmod 755 "${JAR_FILE_PATH}"

#
# Copy the .desktop launcher file into place and customize for this app:
#
SOURCE_GLOB="*.desktop"
ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

APP_LAUNCHER_PATH=${FILE_LIST}

sudo desktop-file-install --dir=${SYSTEM_LAUNCHER_DIR} --mode=644 \
--set-name="${SET_NAME}" \
--set-comment="Ebay auction sniper" \
--set-icon="${INSTALL_DIR}/${APP_NAME}.png" \
--set-key="Exec"        --set-value="java -Xmx512m -jar ${JAR_FILE_PATH}" \
--set-key="Terminal"    --set-value="false" \
--set-key="Type"        --set-value="Application" \
--set-key="Categories"  --set-value="Network;" \
${APP_LAUNCHER_PATH}

InstallComplete

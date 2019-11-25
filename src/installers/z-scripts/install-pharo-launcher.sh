#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install PharoLauncher, the Pharo (Smalltalk) image manager
# ----------------------------------------------------------------------------
#

#
# Source our includes, get our script name, etc. -- The usual...
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

SET_NAME="Pharo-Launcher"

SOURCE_DIR=../pharo
PHARO_PKG_DIR="pharo-launcher"
APP_PKG_PATH=${SOURCE_DIR}/${PHARO_PKG_DIR}

# Does our source file directory exist?
#
[[ -d "${APP_PKG_PATH}" ]] || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
    "Could not find the source directory, '${APP_PKG_PATH}' !"

# Where in our system do we put things?
# Needed directories will be created...
#
PHARO_DIR_PATH="${HOME}/Pharo"
PHARO_DIR_NAME="pharolauncher"

APP_FILE_NAME="pharo-launcher"
ICON_DIR_NAME="icons"

CHEAT_SHEET="TerseGuideToPharo.st"
CHEAT_SHEET_DIR=${PHARO_DIR_PATH}/${PHARO_DIR_NAME}

LAUNCHER_DIR_PATH=~/.local/share/applications

# We prefer the original Pharo icon, not the Launcher icon...
#
#ICON_FILE_NAME="pharo-launcher.png"
ICON_FILE_NAME="Pharo.png"

# Linux VMs have the option of using a threaded heartbeat (preferred)
#
THREADED_HB_DIR="/etc/security/limits.d"
PHARO_HB_CONF_FILEPATH="${THREADED_HB_DIR}/pharo.conf"
SQUEAK_HB_CONF_FILEPATH="${THREADED_HB_DIR}/squeak.conf"
NEWSPEAK_HB_CONF_FILEPATH="${THREADED_HB_DIR}/nsvm.conf"

# Make the paths to the installation components.
# Some of these are needed for creating the '.desktop' file.
#
APP_DIR_PATH=${PHARO_DIR_PATH}/${PHARO_DIR_NAME}
APP_FILE_PATH=${APP_DIR_PATH}/${APP_FILE_NAME}

ICON_DIR_PATH=${APP_DIR_PATH}/${ICON_DIR_NAME}
ICON_FILE_PATH=${ICON_DIR_PATH}/${ICON_FILE_NAME}

# Create the usage prompt text:
#
USAGE="
Installs the latest Pharo (Smalltalk) Launcher application, which automates
downloading & managing collections of Pharo 'images' (environment snapshots).

Pharo is an open-source programming language that is dynamic, object-oriented,
and reflective.  Pharo was inspired by the Smalltalk programming language and
environment, with updates & extentions for modern systems.  Pharo offers strong
live programming features such as immediate object manipulation, live update,
and hot recompilation.  The live programming environment is at the heart of the
system.

Pharo-Launcher is itself implemented as a Pharo app.  The Launcher lists
local and remote image files, and can download images from repositories along
with the appropriate VMs needed to run them.  Local images can be imported,
configured, and launched directly from the Pharo-Launcher GUI.

https://pharo.org/about
https://pharo.org/download
https://files.pharo.org/pharo-launcher/
https://github.com/pharo-project/pharo-launcher
"

POST_INSTALL="
The Pharo-Launcher app is installed in '${PHARO_DIR_PATH}'.

A desktop launcher file for Pharo-Launcher has been created; you may wish to
add it to your favorites/dock for convenience when starting Pharo-Launcher.

To update the installer packages, surf to https://pharo.org/web/download.

"

# Invoked with the '-i' switch?
#
if [[ -z "${1}" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

# To continue, we require the 'unzip' package be installed on this system:
#
which unzip &>/dev/null

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
    "Could not find the 'unzip' command !"

# Determine the architecture bitness, and install 32-bit support
# if we're on a 64-bit system.  This allows running 32-bit images.
#
PHARO_BITNESS="x86"
if [[ ${ARCH} == "x86_64" ]]; then
    PHARO_BITNESS="x64"

    QualifySudo
    sudo dpkg --add-architecture i386

    PACKAGE_SET="libx11-6:i386  libgl1-mesa-glx:i386
        libfontconfig1:i386  libssl1.0.0:i386  "

    PerformAppInstallation "-r" "-u"
fi

# Form the target glob from the desired bitness:
#
PHARO_PKG_GLOB="PharoLauncher*${PHARO_BITNESS}.zip"

# Locate the target file, based on the desired bitness:
#
ResolveGlobFilename "fullpath" "${APP_PKG_PATH}" 1 ${PHARO_PKG_GLOB}
APP_PKG_FILE=${FILE_LIST}

# Create the destination directory, as needed...
#
mkdir -p "${ICON_DIR_PATH}"

(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
    "Could not locate/create '${ICON_DIR_PATH}' !"

# Unzip the package file into the app directory:
#
echo
unzip "${APP_PKG_FILE}" -d "${PHARO_DIR_PATH}"

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Could not unzip the '${APP_PKG_FILE}' package to '${PHARO_DIR_PATH}' !"

# Add the Smalltalk cheat sheet
#
cp "${SOURCE_DIR}/${CHEAT_SHEET}" "${CHEAT_SHEET_DIR}"
sudo chmod 644 "${CHEAT_SHEET_DIR}/${CHEAT_SHEET}"

# Allow for using the "Pharo" icon in place of the "Pharo-Launcher" icon:
#
copy "${SOURCE_DIR}/${ICON_FILE_NAME}" "${ICON_FILE_PATH}"

#
# Copy the .desktop launcher file into place and customize for this app:
#
SOURCE_GLOB="*.desktop"

ResolveGlobFilename "fullpath" "${APP_PKG_PATH}" 1 ${SOURCE_GLOB}
APP_LAUNCHER_PATH=${FILE_LIST}

QualifySudo "to install the PharoLauncher '.desktop' file."

sudo desktop-file-install --dir=${LAUNCHER_DIR_PATH} --mode=644 \
    --set-name="Pharo Launcher" \
    --set-generic-name="Programming" \
    --set-comment="Pharo Smalltalk image file manager" \
    --set-icon=${ICON_FILE_PATH} \
    --set-key="Exec"        --set-value="${APP_FILE_PATH}" \
    --set-key="Terminal"    --set-value="false" \
    --set-key="Type"        --set-value="Application" \
    --set-key="Categories"  --set-value="Development;" \
    "${APP_LAUNCHER_PATH}"

#
# Put a copy of the '.desktop' (launcher) file in the Pharo-Launcher 'icons'
# directory as a backup.
#
cp "${LAUNCHER_DIR_PATH}"/"$( basename ${APP_LAUNCHER_PATH} )" \
    "${ICON_DIR_PATH}"/

(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
    "Could not copy the '.desktop' file to '${ICON_DIR_PATH}' !"

#
# Set the owner, icons, & desktop file permissions.
#
sudo chmod 644 "${LAUNCHER_DIR_PATH}"/*
sudo chown -R $( id -un ):$( id -gn ) "${LAUNCHER_DIR_PATH}"/*

sudo chmod 644 "${ICON_DIR_PATH}"/*
sudo chown -R $( id -un ):$( id -gn ) "${ICON_DIR_PATH}"/*

#
# Need the following for Linux systems to use the threaded heartbeat VM:
#
QualifySudo "to install the threaded heartbeat configuration for Pharo."
makdir "${THREADED_HB_DIR}"

maketmp
cat > "${TMP_PATH}" << __HB_CONF_EOL
*       hard    rtprio  2
*       soft    rtprio  2
__HB_CONF_EOL

sudo chmod 644 "${TMP_PATH}"

copy "${TMP_PATH}" "${PHARO_HB_CONF_FILEPATH}"
copy "${TMP_PATH}" "${SQUEAK_HB_CONF_FILEPATH}"
copy "${TMP_PATH}" "${NEWSPEAK_HB_CONF_FILEPATH}"

rm -rf "${TMP_PATH}"

InstallComplete

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

LAUNCHER_SOURCE_PKG_URL="https://files.pharo.org/pharo-launcher"
LAUNCHER_LINUX_X64_PKG_URL="${LAUNCHER_SOURCE_PKG_URL}/linux64"
LAUNCHER_LINUX_X86_PKG_URL="${LAUNCHER_SOURCE_PKG_URL}/linux32"
LAUNCHER_WINDOWS_PKG_URL="${LAUNCHER_SOURCE_PKG_URL}/windows"

LAUNCHER_BITNESS="x86"
[[ "${ARCH}" == "x86_64" ]] && LAUNCHER_BITNESS="x64"

LAUNCHER_PKG_NAME_GREP="pharo.*launcher.*[.][[:digit:]]+[.]"
LAUNCHER_PKG_NAME_GLOB="PharoLauncher*${LAUNCHER_BITNESS}.zip"

SOURCE_DIR=../pharo
LAUNCHER_SOURCE_PKG_DIR_NAME="pharo-launcher"

APP_SOURCE_PKG_DIR_PATH=${SOURCE_DIR}/${LAUNCHER_SOURCE_PKG_DIR_NAME}
WIN_SOURCE_PKG_DIR_PATH="../../windows/Packages/pharo"

# We prefer the original Pharo icon, not the Launcher icon...
#
#ICON_SOURCE_FILE_NAME="pharo-launcher.png"
ICON_SOURCE_FILE_NAME="Pharo.png"
ICON_SOURCE_FILE_PATH="${APP_SOURCE_PKG_DIR_PATH}/${ICON_SOURCE_FILE_NAME}"

# Where in our system do we put things?
#
PHARO_DIR_PATH="${HOME}/Pharo"
DESKTOP_FILE_DIR_PATH="${HOME}/.local/share/applications"

# Linux VMs have the option of using a threaded heartbeat (preferred)
#
THREADED_HB_DIR_PATH="/etc/security/limits.d"
PHARO_HB_CONF_FILE_PATH="${THREADED_HB_DIR_PATH}/pharo.conf"
SQUEAK_HB_CONF_FILE_PATH="${THREADED_HB_DIR_PATH}/squeak.conf"
NEWSPEAK_HB_CONF_FILE_PATH="${THREADED_HB_DIR_PATH}/nsvm.conf"

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

To install from cached packages, rather than downloading from the internet,
include a '-c' switch after the command.

https://pharo.org/about
https://pharo.org/download
https://files.pharo.org/pharo-launcher/
https://github.com/pharo-project/pharo-launcher
"

POST_INSTALL="
The Pharo-Launcher app is installed in '${PHARO_DIR_PATH}'.

A desktop launcher file for Pharo-Launcher has been created; you may wish to
add it to your favorites/dock for convenience when starting Pharo-Launcher.

"

# Invoked with the '-i' switch?
#
if [[ -z "${1}" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

# Do our source directories exist?
#
[[ -d "${APP_SOURCE_PKG_DIR_PATH}" ]] || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
    "Could not find the source directory, '${APP_SOURCE_PKG_DIR_PATH}' !"

[[ -r "${ICON_SOURCE_FILE_PATH}" ]] || \
    ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
    "Cannot find the launcher icon file, '${ICON_SOURCE_FILE_PATH}' !"

# We require the 'wget' & 'unzip' packages be installed on this system:
#
PACKAGE_SET=""

RESULT=$( which zip )
[[ -n "${RESULT}" ]] || PACKAGE_SET="${PACKAGE_SET}  zip"

RESULT=$( which unzip )
[[ -n "${RESULT}" ]] || PACKAGE_SET="${PACKAGE_SET}  unzip"

RESULT=$( which wget )
[[ -n "${RESULT}" ]] || PACKAGE_SET="${PACKAGE_SET}  wget"

# Determine the architecture bitness, and install 32-bit support
# if we're on a 64-bit system.  This allows running 32-bit images.
#
if [[ ${ARCH} == "x86_64" ]]; then

    QualifySudo
    sudo dpkg --add-architecture i386

    PACKAGE_SET="${PACKAGE_SET}  libx11-6:i386  libgl1-mesa-glx:i386
        libfontconfig1:i386  libssl1.0.0:i386  "
fi

# If any packages are needed, install them now.
#
[[ -n "${PACKAGE_SET}" ]] && PerformAppInstallation "-r" "-u"

# Make a temporary directory to land the downloaded installer packages.
#
maketmp -d

# We can be invoked with a switch to use the locally-cached packages.
#
unset NEW_PKG_DOWNLOADED

if [[ "${1}" == "-c" ]]; then
    shift
    echo "Using cached packages... "

    # Locate the installer package, based on the desired bitness:
    #
    ResolveGlobFilename "fullpath" \
        "${APP_SOURCE_PKG_DIR_PATH}" 1 ${LAUNCHER_PKG_NAME_GLOB}
    APP_PKG_FILE=${FILE_LIST}

    copy "${APP_PKG_FILE}" "${TMP_PATH}/"
else
    # Download the entire set of the current Pharo-Launcher installers.
    #
    for URL in "LAUNCHER_LINUX_X64_PKG_URL" "LAUNCHER_LINUX_X86_PKG_URL" \
        "LAUNCHER_WINDOWS_PKG_URL"; do

        wget -O- "${URL}" > "${TMP_PATH}/"
    done



    if (( $? == 0 )) then
        curl "${PHARO_LINUX_URL}"/"${PHARO_PKG}" > "${APP_PKG_PATH}"
    else
        wget -O- "${PHARO_LINUX_URL}"/"${PHARO_PKG}" > "${APP_PKG_PATH}"
    fi

    (( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
            "Could not download the '${PHARO_PKG}' package !"

    # Check to see if we downloaded a new package.
    #
    diff -cs "${APP_PKG_PATH}" "${SOURCE_DIR}"/"${PHARO_PKG}" > /dev/null
    (( $? == 0 )) || NEW_PKG_DOWNLOADED=true
fi

#
# Unzip the downloaded package into the directory where we placed it:
#
unzip "${APP_PKG_PATH}" -d "${VIRTUALS_DIR_PATH}"

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not unzip the '${PHARO_PKG}' package in '${VIRTUALS_DIR_PATH}' !"

#
# Verify that the application directory that was created by unzipping
# the package really exists as expected.  (This could have changed...)
#
[[ -e "${APP_DIR_PATH}" ]] || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "The install package did not unzip to create '${APP_DIR_PATH}' !"

##########################





# Check to see if the "landing zones" for downloaded packages already
# have downloaded packages in them.  If so, archive them.
#
pushd "${APP_SOURCE_PKG_DIR_PATH}" 1>/dev/null 2>&1
(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot change directory to '${APP_SOURCE_PKG_DIR_PATH}' !"






# Get a list of any existing package files in this directory.
#
PACKAGE_LIST=()
while read LAUNCHER_PACKAGE; do
    PACKAGE_LIST+=( "${LAUNCHER_PACKAGE}" )
done < <( ls -1 | egrep -i ${LAUNCHER_PKG_NAME_GREP} )

# If there are any existing package files, archive them.
#
if (( ${#PACKAGE_LIST[@]} > 0 )); then
    mkdir -p archive
    for PACKAGE in "${PACKAGE_LIST[@]}"; do
        mv -f "${PACKAGE}" archive/
    done
fi

popd 1>/dev/null 2>&1
(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot return to original directory from '${1}' !"

### put downloaded ZIP packages into ${APP_SOURCE_PKG_DIR_PATH}
### put downloaded MSI packages into ${WIN_SOURCE_PKG_DIR_PATH}






### unzip launcher ZIP package into ${PHARO_DIR_PATH}

LAUNCHER_APP_DIR_NAME="pharolauncher"  # TODO: Get this from zip package

LAUNCHER_APP_FILE_NAME="pharo-launcher"  # TODO: Get this from zip package

ICON_TARGET_DIR_NAME="icons"           # TODO: Get this from zip package




# Make the paths to the installation components.
# Some of these are needed for creating the '.desktop' file.
#
LAUNCHER_APP_DIR_PATH=${PHARO_DIR_PATH}/${LAUNCHER_APP_DIR_NAME}
LAUNCHER_APP_FILE_PATH=${LAUNCHER_APP_DIR_PATH}/${LAUNCHER_APP_FILE_NAME}

ICON_TARGET_DIR_PATH=${LAUNCHER_APP_DIR_PATH}/${ICON_TARGET_DIR_NAME}
ICON_TARGET_FILE_PATH=${ICON_TARGET_DIR_PATH}/${ICON_SOURCE_FILE_NAME}

# Form the target glob from the desired bitness:
#
LAUNCHER_PKG_NAME_GLOB="PharoLauncher*${LAUNCHER_BITNESS}.zip"

# Locate the target file, based on the desired bitness:
#
ResolveGlobFilename "fullpath" "${APP_SOURCE_PKG_DIR_PATH}" 1 ${LAUNCHER_PKG_NAME_GLOB}
APP_PKG_FILE=${FILE_LIST}

# Create the destination directory, as needed...
#
mkdir -p "${LAUNCHER_APP_DIR_PATH}"

(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
    "Could not locate/create '${PHARO_DIR_PATH}' !"

# Unzip the package file into the app directory:
#
echo
unzip "${APP_PKG_FILE}" -d "${PHARO_DIR_PATH}"

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Could not unzip the '${APP_PKG_FILE}' package to '${PHARO_DIR_PATH}' !"

# Allow for using the "Pharo" icon in place of the "Pharo-Launcher" icon:
#
cp "${ICON_SOURCE_FILE_PATH}" "${ICON_TARGET_FILE_PATH}"

#
# Copy the .desktop launcher file into place and customize for this app:
#
SOURCE_GLOB="*.desktop"

ResolveGlobFilename "fullpath" "${APP_SOURCE_PKG_DIR_PATH}" 1 ${SOURCE_GLOB}
APP_LAUNCHER_PATH=${FILE_LIST}

QualifySudo "to install the PharoLauncher '.desktop' file."

sudo desktop-file-install --dir=${DESKTOP_FILE_DIR_PATH} --mode=644 \
    --set-name="Pharo Launcher" \
    --set-generic-name="Programming" \
    --set-comment="Pharo Smalltalk image file manager" \
    --set-icon=${ICON_TARGET_FILE_PATH} \
    --set-key="Exec"        --set-value="${LAUNCHER_APP_FILE_PATH}" \
    --set-key="Terminal"    --set-value="false" \
    --set-key="Type"        --set-value="Application" \
    --set-key="Categories"  --set-value="Application;Development;" \
    ${APP_LAUNCHER_PATH}

#
# Put a copy of the '.desktop' (launcher) file in the Pharo 'icons'
# directory as a backup.
#
cp "${DESKTOP_FILE_DIR_PATH}"/"$( basename ${APP_LAUNCHER_PATH} )" \
    "${ICON_TARGET_DIR_PATH}"/

(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
    "Could not copy the '.desktop' file to '${ICON_TARGET_DIR_PATH}' !"

#
# Set the icons & desktop file permissions.
#
chmod 644 "${ICON_TARGET_DIR_PATH}"/*

#
# Need the following for Linux systems to use the threaded heartbeat VM:
#
QualifySudo "to install the threaded heartbeat configuration for Pharo."
makdir "${THREADED_HB_DIR_PATH}"

maketmp
cat > "${TMP_PATH}" << __HB_CONF_EOL
*       hard    rtprio  2
*       soft    rtprio  2
__HB_CONF_EOL

sudo chmod 644 "${TMP_PATH}"

copy "${TMP_PATH}" "${PHARO_HB_CONF_FILE_PATH}"
copy "${TMP_PATH}" "${SQUEAK_HB_CONF_FILE_PATH}"
copy "${TMP_PATH}" "${NEWSPEAK_HB_CONF_FILE_PATH}"

rm -rf "${TMP_PATH}"

InstallComplete

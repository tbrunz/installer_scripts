#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install latest stable version of Pharo from the Pharo website.
# ----------------------------------------------------------------------------
#

#
# Where in our system do we put things? (Directories will be created.)
#
VIRTUALS_DIR_PATH=${HOME}/Virtual

#
# The Pharo project defines these for their packages & files...
#
PHARO_LINUX_URL="http://files.pharo.org/platform"
PHARO_ARM_URL="http://files.pharo.org/vm/pharo-spur32/linux/armv6"

PHARO32_PKG="Pharo6.1-linux.zip"
PHARO32_DIR_NAME="pharo6.1"

PHARO64_PKG="Pharo6.1-64-linux.zip"
PHARO64_DIR_NAME="pharo6.1-64"

PHAROARM_PKG="latest.zip"
PHAROARM_DIR_NAME="pharo6.1"

APP_FILE_NAME="pharo"
ICON_DIR_NAME="icons"
ICON_FILE_NAME="Pharo.png"

APP_SHARED_DIR_NAME="shared"
APP_IMAGE_DIR_NAME="image"

THREADED_HB_DIR="/etc/security/limits.d"
SQUEAK_HB_CONF_FILEPATH="${THREADED_HB_DIR}/squeak.conf"
NEWSPEAK_HB_CONF_FILEPATH="${THREADED_HB_DIR}/nsvm.conf"

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

SET_NAME="Pharo Smalltalk"
PACKAGE_SET="alacarte  "

SOURCE_DIR=../pharo

SYSTEM_LAUNCHER_DIR=/usr/share/applications

#
# Resolve the appropriate package for our architecture, and set the
# package name and unpacked directory names accordingly.
#
if [[ ${IS_RASPBIAN_OS} ]]
then
    PHARO_PKG=${PHARO32_PKG}
    PHARO_DIR_NAME=${PHARO32_DIR_NAME}

elif [[ "${ARCH}" == "x86_64" ]]
then
    PHARO_PKG=${PHARO64_PKG}
    PHARO_DIR_NAME=${PHARO64_DIR_NAME}
else
    PHARO_PKG=${PHARO32_PKG}
    PHARO_DIR_NAME=${PHARO32_DIR_NAME}
fi

#
# Based on the above, make the paths to the installation components.
# Some of these are needed for creating the '.desktop' file.
#
APP_PKG_PATH=${VIRTUALS_DIR_PATH}/${PHARO_PKG}
ARM_PKG_PATH=${VIRTUALS_DIR_PATH}/${PHAROARM_PKG}

APP_DIR_PATH=${VIRTUALS_DIR_PATH}/${PHARO_DIR_NAME}
APP_FILE_PATH=${APP_DIR_PATH}/${APP_FILE_NAME}

ICON_DIR_PATH=${APP_DIR_PATH}/${ICON_DIR_NAME}
ICON_FILE_PATH=${ICON_DIR_PATH}/${ICON_FILE_NAME}

APP_SHARED_PATH=${APP_DIR_PATH}/${APP_SHARED_DIR_NAME}
APP_IMAGE_PATH=${APP_DIR_PATH}/${APP_IMAGE_DIR_NAME}

#
# Create the usage prompt text:
#
USAGE="
Installs the Pharo Smalltalk environment using the appropriate 'platform'
package, which bundles the image, changes, & sources files along with the
corresponding machine's VM.

This script installs 32-bit Pharo properly on 64-bit Linux systems.
As of v6.0, Pharo has been implemented in 64-bit; this script will
install the 64-bit version if the platform is 64-bit.

To install from cached packages, rather than downloading from the internet,
include a '-c' switch after the command.

http://pharo.org/about
http://pharo.org/gnu-linux-installation
"

POST_INSTALL="
A desktop launcher file for Pharo has been created; you may wish to add it to
your favorites/dock for convenience when starting Pharo.

The '${PHARO_PKG}' file is in '${VIRTUALS_DIR_PATH}', which you may keep
as a backup.  The application is installed in '${APP_DIR_PATH}'.

The image files in '${APP_SHARED_PATH}' have been copied into
'${APP_DIR_PATH}/image' as a convenience for making new images.

Note that you can maintain multiple (uniquely named) Pharo images in the \
'${APP_SHARED_DIR_NAME}'
folder in '${APP_DIR_PATH}'.  If more than one image is found
in '${APP_SHARED_DIR_NAME}' when Pharo starts, it will open a dialog box \
showing the images
available and asking you to select one to open.
"

#
# Invoked with no parameters or the '-i' switch?
#
[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

#
# To continue, we require the 'unzip' package be installed on this system:
#
which unzip &>/dev/null

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
        "Could not find the 'unzip' command !"

#
# Need to be sure that the destination directory exists...
#
mkdir -p "${VIRTUALS_DIR_PATH}"

(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not locate/create '${VIRTUALS_DIR_PATH}' !"

#
# Check to see if the package file or the application directory already exist.
# If either does, notify the user and allow them to back up or delete first.
# Since the user might want to bail here, do this before anything else.
#
unset BAK_EXT

for TARGET in "${APP_PKG_PATH}" "${APP_DIR_PATH}"
do
    if [[ -e "${TARGET}" ]]
    then
        echo
        echo "'${TARGET}' already exists on this system. "
        Get_YesNo_Defaulted -y "Do you wish to replace it (by overwriting it)?"

        if (( $? == 0 ))
        then
            rm -rf "${TARGET}"
            (( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
                    "Could not delete '${TARGET}' !"
        else
            Get_YesNo_Defaulted -y "Do you wish to back it up (by renaming it)?"

            (( $? == 0 )) || exit ${ERR_CANCEL}
            #
            # Get a temporary file so that we can use its (random) name:
            #
            if [[ ! ${BAK_EXT} ]]; then
                maketmp -f
                BAK_EXT=$( basename "${TMP_PATH}"  | cut -d '.' -f 2 )
                rm "${TMP_PATH}"
            fi
            #
            # Then rename the pre-existing file/directory.
            # Note: 'move()' requires 'sudo' privileges.
            #
            QualifySudo
            move "${TARGET}" "${TARGET}"_${BAK_EXT}
        fi
    fi
done

#
# We can be invoked with a switch to use the locally-cached packages:
#
unset NEW_PKG_DOWNLOADED
unset NEW_ARM_DOWNLOADED

if [[ "${1}" == "-c" ]]
then
    shift
    echo "Using cached packages... "

    cp "${SOURCE_DIR}"/"${PHARO_PKG}" "${VIRTUALS_DIR_PATH}"/

    (( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not copy cached package '${SOURCE_DIR}/${PHARO_PKG}' !"

	if [[ ${IS_RASPBIAN_OS} ]]
	then
		cp "${SOURCE_DIR}"/"${PHAROARM_PKG}" "${VIRTUALS_DIR_PATH}"/

		(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
			"Could not copy cached package '${SOURCE_DIR}/${PHAROARM_PKG}' !"
	fi

    sleep 2
else
    #
    # Download the Pharo VM, sources, changes, and image.
    # Note that if 'curl' is not installed, we can use 'wget' instead...
    #
    which curl >/dev/null
    RESULT=$?

    if (( RESULT == 0 ))
    then
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

  	if [[ ${IS_RASPBIAN_OS} ]]
  	then
  		if (( RESULT == 0 ))
  		then
  			curl "${PHARO_ARM_URL}"/"${PHAROARM_PKG}" > "${ARM_PKG_PATH}"
  		else
  			wget -O- "${PHARO_ARM_URL}"/"${PHAROARM_PKG}" > "${ARM_PKG_PATH}"
  		fi

  		(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
              "Could not download the '${PHAROARM_PKG}' package !"

      # Check to see if we downloaded a new package.
      #
      diff -cs "${ARM_PKG_PATH}" "${SOURCE_DIR}"/"${PHAROARM_PKG}" > /dev/null
      (( $? == 0 )) || NEW_ARM_DOWNLOADED=true
  	fi
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

#
# Now create a new directory to hold a copy of the image files.
# This directory does NOT exist in the package, so we must create it.
#
mkdir -p "${APP_IMAGE_PATH}"

(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not create the '${APP_IMAGE_PATH}' directory !"

#
# Now make a backup copy of the virgin image files by copying them into
# the backup directory we just created.
#
cp "${APP_SHARED_PATH}"/*.image "${APP_SHARED_PATH}"/*.changes \
        "${APP_SHARED_PATH}"/*.sources "${APP_IMAGE_PATH}"/

(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not copy the image files to the '${APP_IMAGE_PATH}' directory !"

#
# Copy the .desktop launcher file into place and customize for this app:
#
SOURCE_GLOB="*.desktop"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
APP_LAUNCHER_PATH=${FILE_LIST}

QualifySudo "to install the Pharo launcher (.desktop) file."

sudo desktop-file-install --dir=${SYSTEM_LAUNCHER_DIR} --mode=644 \
--set-name="Pharo Smalltalk" \
--set-generic-name="Programming" \
--set-comment="Pharo Smalltalk environment" \
--set-icon=${ICON_FILE_PATH} \
--set-key="Exec"        --set-value="${APP_FILE_PATH}" \
--set-key="Terminal"    --set-value="false" \
--set-key="Type"        --set-value="Application" \
--set-key="Categories"  --set-value="Application;Development;" \
${APP_LAUNCHER_PATH}

#
# Put a copy of the '.desktop' (launcher) file in the Pharo 'icons' directory.
#
cp "${SYSTEM_LAUNCHER_DIR}"/"$( basename ${APP_LAUNCHER_PATH} )" \
        "${ICON_DIR_PATH}"/

(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not copy the '.desktop' file to '${ICON_DIR_PATH}' !"

#
# If we're on a Raspberry Pi, then we need to replace the VM files with ARM:
#
if [[ ${IS_RASPBIAN_OS} ]]
then
	[[ -e "${APP_DIR_PATH}"/bin ]] || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "The install package did not unzip to create '${APP_DIR_PATH}/bin' !"

	unzip -o "${ARM_PKG_PATH}" -d "${APP_DIR_PATH}"/bin

	(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not unzip the '${PHAROARM_PKG}' pkg in '${VIRTUALS_DIR_PATH}' !"

	move "${VIRTUALS_DIR_PATH}"/"${PHAROARM_PKG}" \
		"${VIRTUALS_DIR_PATH}"/pharo-linux-ARMv6.zip
fi

#
# Need the following for Linux systems to use the threaded heartbeat VM:
#
QualifySudo "to install the threaded heartbeat configuration for Pharo."
sudo mkdir -p "${THREADED_HB_DIR}"

cat | sudo tee "${SQUEAK_HB_CONF_FILEPATH}" << END
*       hard    rtprio  2
*       soft    rtprio  2
END
#
# Duplicate for NewSpeak use:
#
sudo cp "${SQUEAK_HB_CONF_FILEPATH}" "${NEWSPEAK_HB_CONF_FILEPATH}"

#
# Notify the user if this was a new downloaded package
# (so that it can be added to the installer thumb drive):
#
if [[ ${NEW_PKG_DOWNLOADED} ]]; then
    echo "A new Pharo package, '${APP_PKG_PATH}' was downloaded. "
fi

if [[ ${NEW_ARM_DOWNLOADED} ]]; then
    echo "A new Pharo ARM package, '${ARM_PKG_PATH}' was downloaded. "
fi

InstallComplete

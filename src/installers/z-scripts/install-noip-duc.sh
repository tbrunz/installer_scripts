#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the NoIP.com Dynamic Update Client
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

# Set up the file and directory names for download/compile:
#
NOIP_URL=http://www.noip.com/client/linux
NOIP_DUC_TARBALL=noip-duc-linux.tar.gz

LOCAL_SRC=/usr/local/src
LOCAL_ETC=/usr/local/etc
CONF_FILE=no-ip2.conf


# We're going to make a Linux service.. Set up these files/directories:
#
MAKE_FILE=Makefile
SCRIPT_NAME=noip2
TARGET_SCRIPT=/etc/init.d/${SCRIPT_NAME}

SOURCE_DIR="../noip"
SOURCE_GLOB="ubuntu*${SCRIPT_NAME}*"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
SERVICE_SCRIPT=${FILE_LIST}

USAGE="
Users of the NoIP.com need to have at least one host in each location that can
inform the service of dynamic IP changes.  The NoIP dynamic update client (DUC)
continually checks for IP address changes in the background and automatically
updates the DNS at NoIP whenever it changes.

This script downloads the latest version (as a source tarball) from NoIP.com,
then compiles & installs it and sets it to run at boot-up.

https://www.noip.com/support/
http://www.noip.com/download?page=linux
"

SET_NAME="NoIP DUC"
PACKAGE_SET=""

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

# Is our Linux service script in the installer repo?
#
[[ -r "${SERVICE_SCRIPT}" ]] || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot locate the Linux service script, '${SERVICE_SCRIPT}' !"

# Download the latest version to the source directory:
#
pushd "${LOCAL_SRC}" &>/dev/null
(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot change directory to '${LOCAL_SRC}' !"

QualifySudo
sudo wget "${NOIP_URL}/${NOIP_DUC_TARBALL}"

# Unpack the tarball:
#
sudo tar zxf "${NOIP_DUC_TARBALL}"
sudo chown -R root.root ._noip* noip*

# Find out which directory we created:
#
# la /usr/local/src
# -rwxr-xr-x  1  501 staff    205 Nov 25  2008 ._noip-2.1.9-1*
# drwxr-xr-x  3  501 staff   4096 Nov 25  2008 noip-2.1.9-1/
# -rw-r--r--  1 root root  134188 Dec 20  2017 noip-duc-linux.tar.gz
#
DIR=$( tar ztvf "${NOIP_DUC_TARBALL}" | \
    awk '/\/Makefile/ { print $6 }' | cut -d '/' -f 1 )

# Validate it... Then 'cd' into it:
#
[[ -d "${LOCAL_SRC}/${DIR}" ]] || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot locate the expected source directory, '${LOCAL_SRC}/${DIR}' !"

cd "${DIR}"

# Compile & install the app:
#
##sudo make -f "${MAKE_FILE}" "${SCRIPT_NAME}"
sudo make install

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Compilation of the Dynamic Update Client app failed !"

# Copy the service script, set it up, and make it a service:
#
popd &>/dev/null
(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot change directory to return from '${DIR}' !"

copy "${SERVICE_SCRIPT}" "${TARGET_SCRIPT}"
sudo chmod 755 "${TARGET_SCRIPT}"

# Remove the annoying MS ^M characters that screw up scripts:
#
sudo fromdos -o "${TARGET_SCRIPT}"

# Install the script as a system service:
#
sudo update-rc.d "${SCRIPT_NAME}" defaults 90 10

# Now set up the configuration file:
#
sudo chown nobody:nogroup "${LOCAL_ETC}/${CONF_FILE}"
sudo chmod 600 "${LOCAL_ETC}/${CONF_FILE}"

# And finally, launch the service to start the app:
#
sudo service "${SCRIPT_NAME}" start

InstallComplete

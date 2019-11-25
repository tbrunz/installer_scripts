#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Modelio open source modeling environment (Java)
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

SUGGEST_VERSION=3.5

SET_NAME="Modelio"
PACKAGE_SET="alacarte  "
PKG_VERSION="${SUGGEST_VERSION}"

APP_NAME="modelio"
ICON_NAME="icon.xpm"
ICON_NAME_FIX="icon"

SOURCE_DIR="../modelio"
INSTALL_DIR="/opt/modelio"

USAGE="
Modelio is a modeling environment, supporting a wide range of models and 
diagrams, and providing model assistance and consistency checking features. 

Among the models it supports is UML2, a general-purpose modeling language 
from the OMG, used in the field of object-oriented software engineering. 

Modelio is an open source environment whose core is licensed under 
version 3 of the GPL from GNU. 

http://www.modelio.org/
"

POST_INSTALL="
To make a menu launcher: 

    Search for the application 'alacarte' (in 'Main Menu') 
    Click on 'Programming' 
    Click 'New Item' and set the following:
    
        Name = Modelio 
        Command = ${INSTALL_DIR}/${SET_NAME}-<version>/${APP_NAME}
        Comment = Modelio modeling environment 
    
    Load the icon using '${INSTALL_DIR}/${SET_NAME}-<version>/${ICON_NAME_FIX}' 
 
Note that you will need to log out and log back in for the Dash to find the app. 
"

[[ "${1}" == "-i" || "${2}" == "-i" ]] && INFO_ONLY=true

#
# Verify that Java 8 has been installed already:
#
RESULT=$( java -version 2>&1 | grep 'build 1.8' )

if (( $? > 0 )); then

    MSG="${SET_NAME} is dependent on Java 8, which has not been installed. "

    if [[ -z "${2}" || "${INFO_ONLY}" == true ]]; then

        USAGE=$( printf "%s \n \n%s \n \n" "${USAGE}" "${MSG}" )
#        set --
    else
        ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" "${MSG}"
    fi
fi

[[ -z "${2}" ]] && PerformAppInstallation "$@"
[[ "${INFO_ONLY}" == true ]] && PerformAppInstallation "-i"

#
# The user must tell us which Modelio version they want to install,
# And must also include the 'update' switch...
#
PKG_VERSION=${1}
shift

printf "%s" "${PKG_VERSION}" | egrep '^[[:digit:]]+[.][[:digit:]]+$' >/dev/null

if [[ $? -ne 0 || -z "${1}" || "${1}" == "-i" ]]; then
    PKG_VERSION="${SUGGEST_VERSION}"
    PerformAppInstallation
fi

if [[ -z "${1}" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

#
# Ensure that the needed files are present in our repo before installing:
#
ResolveGlobFilename "fullname" \
        "${SOURCE_DIR}" 1 "${APP_NAME}*v${PKG_VERSION}*gz"

PerformAppInstallation "-r" "$@"
    
#
# Create the installation directory (owned by root) & 
# untar the files to the installation directory:
#
QualifySudo
makdir "${INSTALL_DIR}"
sudo rm -rf "${INSTALL_DIR}"/*
    
tar_zip gz "${FILE_LIST}" -C "${INSTALL_DIR}"

#
# Find the top-level directory of what we just untarred..
#
ResolveGlobFilename "fullname" "${INSTALL_DIR}" 2 "${APP_NAME}"

# 
# Spaces in the folder names cause all manner of malfunction... Change to '-':
#
INSTALL_PATH_BAD=$( dirname "${FILE_LIST}" )

INSTALL_FOLDER_BAD=$( basename "${INSTALL_PATH_BAD}" )

INSTALL_FOLDER_GOOD=$( trim $( subspace "-" "${INSTALL_FOLDER_BAD}" ) )

INSTALL_PATH=${INSTALL_DIR}/${INSTALL_FOLDER_GOOD}

sudo mv "${INSTALL_PATH_BAD}" ${INSTALL_PATH}

#
# Fixup the file ownerships:
#
sudo chown -R root:root "${INSTALL_DIR}"

#
# Fix the icon file to workaround an 'alacarte' bug in detecting icon files:
#
ResolveGlobFilename "fullname" "${INSTALL_PATH}" 1 "${ICON_NAME}"

copy ${INSTALL_PATH}/"${ICON_NAME}" ${INSTALL_PATH}/${ICON_NAME_FIX}

InstallComplete

# 
# Now that we know the version number, fixup the POST_INSTALL message:
#
POST_INSTALL=$( echo -n "${POST_INSTALL}" | \
    sed -e "s|Command = .*$|Command = ${INSTALL_PATH}/${APP_NAME}|" )

POST_INSTALL=$( echo -n "${POST_INSTALL}" | \
    sed -e "s|icon using .*$|icon using '${INSTALL_PATH}/${ICON_NAME_FIX}'|" )

echo "${POST_INSTALL}"


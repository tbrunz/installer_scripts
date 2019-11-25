#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Modelio open source modeling environment (.deb package)
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

SET_NAME="Modelio"
PACKAGE_SET="libwebkitgtk-1.0-0  "

APP_NAME="modelio"

SOURCE_DIR="../modelio"
SOURCE_GLOB="${APP_NAME}*.deb"

### CheckGlobFilename "fullname" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

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
    On first launching Modelio, be patient, as it takes a while to load
    and display its splash screen...
"

#
# Verify that Java 8 or later has been installed already:
#
RESULT=$( java -version 2>&1 | egrep 'build (1[.]8|9[.]|10[.])' )

if (( $? > 0 )); then

    MSG="${SET_NAME} is dependent on Java 8+, which has not been installed. "

    if [[ -z "${1}" || "${1}" == "-i" ]]; then

        USAGE=$( printf "%s \n \n%s \n \n" "${USAGE}" "${MSG}" )
        set --
    else
        ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" "${MSG}"
    fi
fi

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
DEB_PACKAGE=${FILE_LIST}

PerformAppInstallation "-r" "$@"

# Install will fail for lack of packages...  Fix it.
#
sudo apt-get install -f -y

InstallComplete

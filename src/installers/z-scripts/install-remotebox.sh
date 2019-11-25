#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the RemoteBox client package
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

SET_NAME="RemoteBox"
SUGGEST_VERSION=2.6

VERSION_GREP="s/([^[:digit:]]+)([[:digit:]]+[.][[:digit:]]+[.]*[[:digit:]]*)"
VERSION_GREP=${VERSION_GREP}"(.*)/\2/p"

INSTALL_LOCATION=/opt/remotebox
INSTALL_DIR=RemoteBox-
EXEC_LOCATION=/usr/local/bin
EXECUTABLE=remotebox

USAGE="
RemoteBox is a VirtualBox client. In essence, you can remotely administer (i.e.,
over the network) an installation of VirtualBox on a server, including its
guests, and interact with them as if they were running locally.  VirtualBox is
installed on the server machine and RemoteBox runs on the client machine.
RemoteBox provides a complete GTK graphical interface with a look and feel very
similar to that of VirtualBox's native GUI.

VirtualBox is intended to be used as a desktop virtualization solution.  That
is, you install it on a machine and use VirtualBox locally.  This means that the
guests on the local machine will consume resources, taking them away from other
tasks.  Additionally, the guests will not be available to other machines or will
be unavailable if the local machine is shut down.

RemoteBox changes this by allowing you to run the guests on another machine
(i.e., the server) but still interact with them as if they were installed
locally.  This frees up resources on your local machine, allows you to interact
with the same guests from multiple machines (e.g., a desktop and a laptop), and
the guests can continue to run even when the client machine is shut down.

The guests can also take advantage of the additonal CPU, memory, and storage
that servers tend to have.  As VirtualBox and RemoteBox are both cross-platform,
it allows you to use different operating systems for the client and server.  For
example, you may prefer to use VirtualBox on a Linux server, but wish to
interact with the guests from a Mac OS X client machine.

The RemoteBox client is known to run on Linux, Solaris, Mac OS X, and various
modern flavors of BSD.  VirtualBox offically runs on Linux, Solaris, Mac OS X,
and Windows as well as 'unofficially' on FreeBSD.  The client and server
machines do not need to be running the same operating system.
"

POST_INSTALL="
    To use RemoteBox, you must configure the server (which runs VirtualBox).
    The details about how this is done depends on the type of operating
    system the server runs.

    For Linux-based servers, run the 'install-vbox-webservice.sh' script
    (on the server machine), and specify the user who owns the hosted VMs.

    For Windows-based servers, copy the 'VBox-WebService.bat' batch file to
    the Windows host and run it as the user who owns the hosted VMs.

    Once the server service is running, run 'remotebox' (from the command
    line) and log into the server to start a VirtualBox Manager session.
"

[[ "${1}" == "-i" ]] && PerformAppInstallation "$@"

#
# The user must tell us which Virtualbox version they want to install for,
# And must also include an 'update' switch (-n or -u)...
#
PKG_VERSION=${1}
shift

printf %s "${PKG_VERSION}" | egrep '^[[:digit:]]+[.][[:digit:]]+$' >/dev/null

if (( $? != 0 )); then
    PKG_VERSION=${SUGGEST_VERSION}
    PerformAppInstallation
fi

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

# Start by installing the dependencies:
#
PACKAGE_SET="libgtk2-perl  freerdp-x11  libsoap-lite-perl  rdesktop  "

PerformAppInstallation "-r" "$@"

# Now find the install package (from a local tarball):
#
SOURCE_DIR=../remotebox
SOURCE_GLOB="*${PKG_VERSION}*tgz"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
OPT_PACKAGE=${FILE_LIST}

# Install the tarball:
#
QualifySudo
makdir "${INSTALL_LOCATION}"

# Untar the installation tarball & set its owner & permissions:
#
tar_zip "gz" "${OPT_PACKAGE}" -C "${INSTALL_LOCATION}"
sudo chown -R root.root "${INSTALL_LOCATION}"
sudo chmod -R o+rX "${INSTALL_LOCATION}"

# Make paths to the executable & verify installation:
#
ResolveGlobFilename "fullpath" "${INSTALL_LOCATION}" 2 "${EXECUTABLE}*"

# Determine the version we've installed, then find its install directory:
#
APP_VERSION=$( printf "%s" "${OPT_PACKAGE}" | sed -rne "${VERSION_GREP}" )

for FILE_PATH in "${FILE_LIST[@]}"; do

    RESULT=$( printf "%s" "${FILE_PATH}" | grep ${APP_VERSION} )
    [[ -n "${RESULT}" ]] && break
done

EXECUTABLE_PATH=${FILE_PATH}
EXECUTABLE_DIR=$( dirname ${EXECUTABLE_PATH} )

if [[ ! -x "${EXECUTABLE_PATH}" ]]; then

    ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
                "Cannot locate the RemoteBox executable !"
fi

# Create the script to launch RemoteBox:
#
maketmp

cat > ${TMP_PATH} << EOF
#! /bin/sh
#
cd "${EXECUTABLE_DIR}"
./${EXECUTABLE} 2>/dev/null &
EOF

# Move the script into place and delete the temp file:
#
copy ${TMP_PATH} "${EXEC_LOCATION}/${EXECUTABLE}"
SetDirPerms "${EXEC_LOCATION}/${EXECUTABLE}"

sudo rm -rf ${TMP_PATH}

InstallComplete

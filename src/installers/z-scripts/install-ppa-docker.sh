#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Docker CE (Community Edition)
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
Docker is systems-level software that performs operating-system-level
virtualization, also known as 'containerization'.  It was first released
in 2013 and is developed by Docker, Inc.

Docker is used to run software packages called 'containers'. In a typical
use case, one container runs a web server and web application, while a second
container runs a database server that is used by the web application.

Containers are isolated from each other and bundle their own tools, libraries,
and configuration files; they can communicate with each other through
well-defined IPC channels.

All containers are run by a single operating system kernel and are thus more
lightweight than virtual machines.  Containers are created from 'images' that
specify their contents.  These images are often created by combining and
modifying standard images downloaded from online repositories.

https://docs.docker.com/
"

SET_NAME="Docker CE"
PACKAGE_SET="docker-ce  ppa-purge  "

# Docker requires 64-bit for Linux...
#
GetOSversion
[[ ${ARCH} == "x86_64" ]] || ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
  "Docker is only supported on Linux for 64-bit. "

# Install from the Docker repo site, not the Ubuntu repositories.
#
SIGNING_KEY=https://download.docker.com/linux/ubuntu/gpg

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL="deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
REPO_GREP="docker.*${DISTRO}"

PerformAppInstallation "-r" "$@"

# Test to see if it installed correctly; it should launch in the background.
#
sudo systemctl status docker | grep 'active (running)'

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
  "${SET_NAME} failed to start after installation ! "

InstallComplete

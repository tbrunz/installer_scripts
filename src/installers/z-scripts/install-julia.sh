#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the Julia development system
# ----------------------------------------------------------------------------
#

SUGGEST_VERSION=1.5.3

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

SET_NAME="Julia (Language)"
PACKAGE_SET="alacarte  curl  cmake  "

SOURCE_DIR=../julia
LAUNCHER_DIR_PATH=~/.local/share/applications

#
# Create the usage prompt text:
#
USAGE="
Installs the Julia language development environment using the appropriate
'platform' package.  Currently, Julia supports (for Linux), Intel 32- and
64-bit and ${JULIA_ARM_NAME} processors.

Julia is a high-level general-purpose dynamic programming language that was
originally designed to address the needs of high-performance numerical
analysis and computational science, without the typical need of separate
compilation to be fast.  Julia is also usable for client & server web use,
low-level systems programming, or as a specification language.

Distinctive aspects of Julia's design include a type system with parametric
polymorphism, types in a fully dynamic programming language, and multiple
dispatch as its core programming paradigm.  It allows concurrent, parallel
and distributed computing, and direct calling of C and Fortran libraries
without glue code.

Julia is garbage-collected, uses eager evaluation, and includes efficient
libraries for floating-point calculations, linear algebra, random number
generation, and regular expression matching.  Many libraries are available,
and some of them (e.g. for fast Fourier transforms) were previously bundled
with Julia.

To install Julia from cached packages, rather than downloading from the
internet, include a '-c' switch after the command.

https://julialang.org/
https://docs.julialang.org/
https://julialang.org/downloads/
"

POST_INSTALL="
You may wish to install Juno, an IDE for Julia, based on the Atom editor.
Other alternatives are Jupyter (notebook-style) and JuliaPro.

https://www.quora.com/What-are-some-IDEs-for-the-Julia-language
https://www.linkedin.com/pulse/datascience-julia-cleuton-sampaio-de-melo-junior/

Juno is an Integrated Development Environment (IDE) for the Julia language.
It provides powerful tools to help you develop code.  Juno is built on Atom,
a text editor provided by Github.  Juno consists of both Julia and Atom
packages in order to add Julia-specific enhancements, such as syntax
highlighting, a plot pane, integration with Julia's debugger (Gallium), a
console for running code, and much more.

https://junolab.org/
https://docs.junolab.org/latest/man/installation.html

JuliaPro is the fast, free way to install julia on your desktop or laptop and
begin using it immediately.  It's a 'batteries included' IDE that bundles the
Julia compiler, Gallium debuger, profiler, Juno integrated development
environment, 100+ curated packages for data visualisation, plotting,
optimization, machine learning, databases, and much more.
(Download requires registration).

https://juliacomputing.com/products/juliapro.html
"

#
# Invoked with no parameters or the '-i' switch?
#
if [[ -z "${1}" || "${1}" == "-p" || "${1}" == "-i" ]]; then
    PKG_VERSION=${SUGGEST_VERSION}
    PerformAppInstallation "$@"
    exit $?
fi

#
# The user must tell us which version they want to install,
# And must also include an 'update' switch (-n or -u)...
#
PKG_VERSION=${1}
shift

unset USE_CACHED_PKG
if [[ "${1}" == "-c" ]]
then
  USE_CACHED_PKG=true
  shift
fi

printf "%s" "${PKG_VERSION}" | \
    egrep '^[[:digit:]]+[.][[:digit:]]+[.][[:digit:]]+$' &>/dev/null

if (( $? != 0 )); then
    PKG_VERSION=${SUGGEST_VERSION}
    PerformAppInstallation
fi

if [[ -z "${1}" || ${1} == "-p" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

#
# The Julia project defines these for their packages & files...
#
JULIA_VERSION="${PKG_VERSION}"
JULIA_URL_VERSION="${PKG_VERSION%.?}"

JULIA_REPO_URL="https://julialang-s3.julialang.org/bin"
JULIA_LINUX_REPO_URL="${JULIA_REPO_URL}/linux"

JULIA_ARM_VERS="armv7l"
JULIA_ARM_NAME="ARM v7L (32-bit)"

JULIA_LINUX32_URL="${JULIA_LINUX_REPO_URL}/x86/${JULIA_URL_VERSION}"
JULIA_LINUX64_URL="${JULIA_LINUX_REPO_URL}/x64/${JULIA_URL_VERSION}"
JULIA_ARM32_URL="${JULIA_LINUX_REPO_URL}/${JULIA_ARM_VERS}/${JULIA_URL_VERSION}"

JULIA_LINUX32_PKG="julia-${JULIA_VERSION}-linux-i686.tar.gz"
JULIA_LINUX64_PKG="julia-${JULIA_VERSION}-linux-x86_64.tar.gz"
JULIA_ARM_PKG="julia-${JULIA_VERSION}-linux-armv7l.tar.gz"

#
# Locations that the Julia package puts things
# (relative to the install directory)
#
APP_BIN_DIR="bin/"
APP_FILE_NAME="julia"

ICON_DIR_NAME="share/icons/hicolor/scalable/apps/icons"
ICON_FILE_NAME="julia.svg"

#
# Where in our system do we put things? (Directories will be created.)
#
APP_BASE_DIR_PATH="/opt/julia"
APP_VERSION_DIR="julia-${JULIA_VERSION}"

PATH_SEARCH_DIR="/usr/local/bin"
APP_SEARCH_PATH=${PATH_SEARCH_DIR}/${APP_FILE_NAME}

#
# Resolve the appropriate package for our architecture,
# and set the package name accordingly.
#
if [[ ${IS_RASPBIAN_OS} ]]
then
    PKG_REPO_URL=${JULIA_ARM32_URL}
    INSTALL_PKG_FILE=${JULIA_ARM_PKG}
elif
    [[ "${ARCH}" == "x86_64" ]]
then
    PKG_REPO_URL=${JULIA_LINUX64_URL}
    INSTALL_PKG_FILE=${JULIA_LINUX64_PKG}
else
    PKG_REPO_URL=${JULIA_LINUX32_URL}
    INSTALL_PKG_FILE=${JULIA_LINUX32_PKG}
fi

#
# Based on the above, make the paths to the installation components.
# Some of these are needed for creating the '.desktop' file.
#
PKG_REPO_URL=${PKG_REPO_URL}/${INSTALL_PKG_FILE}
CACHED_PKG_PATH=${SOURCE_DIR}/${INSTALL_PKG_FILE}

APP_DIR_PATH=${APP_BASE_DIR_PATH}/${APP_VERSION_DIR}
APP_FILE_PATH=${APP_DIR_PATH}/${APP_BIN_DIR}${APP_FILE_NAME}

APP_ALIASED_PATH=${APP_BASE_DIR_PATH}/${APP_FILE_NAME}
ALIASED_FILE_PATH=${APP_ALIASED_PATH}/${APP_BIN_DIR}${APP_FILE_NAME}

ICON_DIR_PATH=${APP_DIR_PATH}/${ICON_DIR_NAME}
ICON_FILE_PATH=${ICON_DIR_PATH}/${ICON_FILE_NAME}

#
# Check to see if the application directory already exists.
# If it does, notify the user and allow them to back up or delete first.
# Since the user might want to bail here, do this before anything else.
#
unset BAK_EXT

if [[ -e "${APP_DIR_PATH}" ]]
then
    echo
    echo "'${APP_DIR_PATH}' already exists on this system. "
    Get_YesNo_Defaulted "n" "Do you wish to replace it (by overwriting it)?"

    if (( $? == 0 ))
    then
        QualifySudo
        sudo rm -rf "${APP_DIR_PATH}"

        (( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
                "Could not delete '${APP_DIR_PATH}' !"
    else
        Get_YesNo_Defaulted "y" "Do you wish to back it up (by renaming it)?"

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
        move "${APP_DIR_PATH}" "${APP_DIR_PATH}"_${BAK_EXT}
    fi
fi

#
# Need to be sure that the destination directory does not exist...
# But we need the base directory to exist, so create what's missing.
#
QualifySudo
sudo rm -rf "${APP_DIR_PATH}"
makdir "${APP_BASE_DIR_PATH}"

#
# We can be invoked with a switch to use the locally-cached packages:
#
unset NEW_PKG_DOWNLOADED

if [[ ${USE_CACHED_PKG} ]]
then
    shift
    echo "Using cached packages... "

    copy "${CACHED_PKG_PATH}" "${APP_BASE_DIR_PATH}"/
    sudo chmod 644 "${APP_BASE_DIR_PATH}"/"${INSTALL_PKG_FILE}"

#    (( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
#        "Could not copy cached package '${SOURCE_DIR}/${INSTALL_PKG_FILE}' !"

    sleep 2
else
    #
    # Download the installation package from the repo site.
    # Note that if 'curl' is not installed, we can use 'wget' instead...
    #
    which curl >/dev/null

    if (( $? == 0 ))
    then
        sudo curl "${PKG_REPO_URL}" \
            -o "${APP_BASE_DIR_PATH}"/"${INSTALL_PKG_FILE}"
    else
        sudo wget "${PKG_REPO_URL}" \
            -O "${APP_BASE_DIR_PATH}"/"${INSTALL_PKG_FILE}"
    fi

    (( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
            "Could not download the '${INSTALL_PKG_FILE}' package !"

    # Check to see if we downloaded a new package.
    #
    diff -cs "${CACHED_PKG_PATH}" "${APP_BASE_DIR_PATH}" &>/dev/null
    (( $? == 0 )) || NEW_PKG_DOWNLOADED=true
fi

#
# Untar the downloaded package into the directory where we placed it:
#
sudo chown root.root "${APP_BASE_DIR_PATH}"/"${INSTALL_PKG_FILE}"

sudo tar -C "${APP_BASE_DIR_PATH}" \
    -zxf "${APP_BASE_DIR_PATH}"/"${INSTALL_PKG_FILE}"

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
"Could not untar the '${INSTALL_PKG_FILE}' package in '${APP_BASE_DIR_PATH}' !"

#
# Verify that the application directory that was created by untarring
# the package really exists as expected.  (This could have changed...)
#
[[ -e "${APP_FILE_PATH}" ]] || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "The install package did not untar to create '${APP_DIR_PATH}' !"

#
# Set the ownership of the entire Julia fileset to 'root'.
# Create a non-version-specific link to the version-specific directory.
# Then create a link to the Julia app in a $PATH folder so it can be found.
#
sudo chown -R root.root "${APP_BASE_DIR_PATH}"

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Could not change ownership of files in '${APP_BASE_DIR_PATH}' ! "

# This is a bona fide bug in Ubuntu...  "ln -sf" does NOT remove an
# existing destination; the man page clearly states that '-f' should.
#
sudo rm -f "${APP_ALIASED_PATH}"
sudo ln -sf "${APP_DIR_PATH}" "${APP_ALIASED_PATH}"

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Could not link to '${APP_DIR_PATH}' in '${APP_BASE_DIR_PATH}' ! "

makdir "${PATH_SEARCH_DIR}"
sudo rm -f "${APP_SEARCH_PATH}"
sudo ln -sf "${ALIASED_FILE_PATH}" "${APP_SEARCH_PATH}"

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Could not link to '${ALIASED_FILE_PATH}' in '${PATH_SEARCH_DIR}' ! "

: << '__NO_DESKTOP_ICON'
#
# Copy the .desktop launcher file into place and customize for this app:
#
SOURCE_GLOB="*.desktop"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
APP_LAUNCHER_PATH=${FILE_LIST}

sudo desktop-file-install --dir=${LAUNCHER_DIR_PATH} --mode=644 \
--set-name="julia Smalltalk" \
--set-generic-name="Programming" \
--set-comment="julia Smalltalk environment" \
--set-icon=${ICON_FILE_PATH} \
--set-key="Exec"        --set-value="${APP_FILE_PATH}" \
--set-key="Terminal"    --set-value="false" \
--set-key="Type"        --set-value="Application" \
--set-key="Categories"  --set-value="Development;" \
${APP_LAUNCHER_PATH}

#
# Put a copy of the '.desktop' (launcher) file in the julia 'icons' directory.
#
cp "${LAUNCHER_DIR_PATH}"/"$( basename ${APP_LAUNCHER_PATH} )" \
        "${ICON_DIR_PATH}"/

(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not copy the '.desktop' file to '${ICON_DIR_PATH}' !"

__NO_DESKTOP_ICON

#
# Notify the user if this was a new downloaded package
# (so that it can be added to the installer thumb drive):
#
if [[ ${NEW_PKG_DOWNLOADED} ]]; then
    echo "A new installer package was downloaded to '${APP_BASE_DIR_PATH}'. "
fi

InstallComplete

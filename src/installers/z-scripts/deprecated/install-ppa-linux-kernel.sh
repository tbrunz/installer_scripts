#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install a later (non-repo) Linux kernel
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

# The details of the particular kernel that will be backported;
# These need to match the values in the PPA website we download from;
#
KERNEL_PPA_BASE_URL=http://kernel.ubuntu.com/~kernel-ppa/mainline

MINOR_MIN=9
MINOR_MAX=13

# The user must tell us which kernel version they want to install, and
# must also include an appropriate switch...
#
printf %s "${1}" | egrep '^[[:digit:]]+[.][[:digit:]]+$' >/dev/null
RESULT=$?

# If the user garbles the version number, doesn't provide it, or doesn't
# provide a switch, then display the 'usage' prompt (including '-p').
#
if [[ "${1}" == "-i" ]]; then
    PKG_VERSION=3.${MINOR_MAX}

elif [[ -z "${1}" || ${RESULT} != 0 ]]; then
    set --
    PKG_VERSION=3.${MINOR_MAX}
else
    PKG_VERSION=${1}
    shift
fi

# Parse the version number into its parts:
#
MAJOR_VERSION=${PKG_VERSION%%.*}
MINOR_VERSION=${PKG_VERSION##*.}
MIDDLE_VERSION=${PKG_VERSION%.${MINOR_VERSION}}

# Did the user enter something like '3.a.b.c'?
#
if [[ ${MIDDLE_VERSION} == "${MAJOR_VERSION}" ]]; then

    MIDDLE_VERSION=
else
    MIDDLE_VERSION=${MIDDLE_VERSION#${MAJOR_VERSION}.}
fi

# Examine the results to see if it's in the correct form, etc.
#
[[ -n "${MIDDLE_VERSION}" || ${MAJOR_VERSION} -lt 1 ]] && \
    ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
    "Kernel version must be in the form of 3.x "

(( MAJOR_VERSION != 3 )) && ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
    "This script only works with version 3 kernels !"

(( MINOR_VERSION < MINOR_MIN || MINOR_VERSION > MINOR_MAX ))  \
    && ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
    "This script only works with version 3.${MINOR_MIN} to 3.${MINOR_MAX} kernels !"

# Retrieve the data for the selected kernel:
#
for (( i=MINOR_MIN ; i<=MINOR_MAX ; i++ )); do

    read -r KERNEL_NMBR KERNEL_VERS KERNEL_DATE KERNEL_DISTRO

    (( i == MINOR_VERSION )) && break

done << KERNEL_DATA
3.9.11  030911 201307202035 saucy
3.10.25 031025 201312201135 saucy
3.11.10 031110 201312110635 saucy
3.12.6  031206 201312201218 trusty
KERNEL_DATA

# Base URL = Kernel website directory containing the files for this kernel:
#
# For numbers of the form 'X.Y.0', the web URL will use only 'X.Y-distro' - fix!
#
KERNEL_NUMBER=${KERNEL_NMBR##*.*.}

if (( KERNEL_NUMBER == 0 )); then

    KERNEL_NUMBER=${KERNEL_NMBR%.${KERNEL_NUMBER}}
else
    KERNEL_NUMBER=${KERNEL_NMBR}
fi

# Now we can make a 'good' version numbered URL:
#
KERNEL_PPA_URL=${KERNEL_PPA_BASE_URL}/v${KERNEL_NUMBER}-${KERNEL_DISTRO}

KERNEL_NUM_VERS=${KERNEL_NUMBER}-${KERNEL_VERS}
KERNEL_SUFFIX=${KERNEL_NUM_VERS}.${KERNEL_DATE}

# Base filenames for the Header & Image files:
#
FILENAME_HEADERS_BASE=linux-headers-${KERNEL_NUM_VERS}-generic_${KERNEL_SUFFIX}
FILENAME_IMAGE_BASE=linux-image-${KERNEL_NUM_VERS}-generic_${KERNEL_SUFFIX}

# URLs to the files:
#
URL_HEADERS_amd64=${KERNEL_PPA_URL}/${FILENAME_HEADERS_BASE}_amd64.deb
URL_IMAGE_amd64=${KERNEL_PPA_URL}/${FILENAME_IMAGE_BASE}_amd64.deb

URL_HEADERS_i386=${KERNEL_PPA_URL}/${FILENAME_HEADERS_BASE}_i386.deb
URL_IMAGE_i386=${KERNEL_PPA_URL}/${FILENAME_IMAGE_BASE}_i386.deb

URL_HEADERS_ALL=linux-headers-${KERNEL_NUM_VERS}_${KERNEL_SUFFIX}
URL_HEADERS_ALL=${KERNEL_PPA_URL}/${URL_HEADERS_ALL}_all.deb


SET_NAME="Linux kernel"
SOURCE_DIR="../linux-kernel"

# Check the cache directory to see if we have any cached kernel packages:
#
# Start by making a glob to match files that apply to this architecture:
#
GetOSversion
if [[ ${ARCH} == "x86_64" ]]; then

    SOURCE_GLOB="linux-image*amd*"
else
    SOURCE_GLOB="linux-image*i386*"
fi
FindGlobFilename "basename" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

# Find all the files that match the architecture's glob, then extract
# the version number embedded in the file name:
#
VERS_LIST=""
for KERNEL_FILE in "${FILE_LIST[@]}"; do

    THIS_FILE=${KERNEL_FILE}
    VERS_LIST="${VERS_LIST} $( printf %s "${THIS_FILE}" \
    | egrep -o '[[:digit:]]+[.][[:digit:]]+[.][[:digit:]]+' )"
done

# Put together the 'usage' prompt, including a list of cached versions:
#
USAGE="
NOTE: This script requires downloads and tweaks to run properly!

This script will install a new Linux kernel, either by downloading it from
the Ubuntu kernel website, or from a cached set of files.

Default PPA version:
${KERNEL_NMBR}
"
if [[ -n "${VERS_LIST}" ]]; then
    #
    # If the list of version numbers we matched earlier is not empty,
    # turn it into a set of lines, then sort the lines & eliminate any
    # duplicate numbers, then display the lines as our cached versions:
    #
USAGE=${USAGE}"
Cached versions: $( printf %s "${VERS_LIST}" | tr " " "\n" | sort | uniq )
"
fi
USAGE=${USAGE}"
For kernel versions other than listed above, surf to the the following
website and then either download the packages to '${SOURCE_DIR}',
or modify the parameters at the top of this script with the corresponding
directory names & re-run (with '-u').

${KERNEL_PPA_BASE_URL}/
"

POST_INSTALL="
Note that you will need to update GRUB and reboot for the new kernel to take
effect.  (You may wish to install & use 'grub-customizer' for this purpose.)
"

# If the user garbles the version number, doesn't provide it, or doesn't
# provide a switch, then display the 'usage' prompt (including '-p').
#
if [[ -z "${1}" || "${1}" == "-i" ]]; then
    REPO_NAME="abc"
    PKG_VERSION=${MAJOR_VERSION}.${MINOR_VERSION}
    PerformAppInstallation "$@"
fi

# If the switch is '-p' or '-u', then we need to do a download:
#
case ${1} in
"-n")
    # Nothing to do here... yet.
    ;;
"-p" | "-u")
    #
    # Make the cache directory, as needed:
    #
    if [[ ! -d "${SOURCE_DIR}" ]]; then

        mkdir -p "${SOURCE_DIR}"
        (( $? > 0 )) && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
                "Cannot create the directory '${SOURCE_DIR}' !"
    fi

    # Download the files into the cache; 'wget' will report its own errors:
    #
    echo
    if [[ ${PKG_VERSION} == "${KERNEL_NMBR}" ]]; then
        echo "Attempting to download kernel ${KERNEL_NMBR} from the PPA: "
    else
        echo "This script is configured to download kernel ${KERNEL_NMBR}... "

        Get_YesNo_Defaulted "y" "Do you wish to continue downloading?"
        (( $? > 0 )) && exit
    fi
    echo

    wget -P "${SOURCE_DIR}" -c "${URL_HEADERS_ALL}"
    wget -P "${SOURCE_DIR}" -c "${URL_HEADERS_amd64}"
    wget -P "${SOURCE_DIR}" -c "${URL_IMAGE_amd64}"
    wget -P "${SOURCE_DIR}" -c "${URL_HEADERS_i386}"
    wget -P "${SOURCE_DIR}" -c "${URL_IMAGE_i386}"

    echo "Cached kernel files: "
    echo
    ls -lF "${SOURCE_DIR}"

    # At this point, we can quit if we were invoked with '-p':
    #
    if [[ ${1} == "-p" ]]; then exit; fi
    ;;
*)
    REPO_NAME="abc"
    PKG_VERSION=${MAJOR_VERSION}.${MINOR_VERSION}
    PerformAppInstallation
    ;;
esac

# Now we do another glob match, this time matching the requested version:
#
if [[ ${ARCH} == "x86_64" ]]; then

    SOURCE_GLOB="linux*${PKG_VERSION}*amd* linux*${PKG_VERSION}*all*"
else
    SOURCE_GLOB="linux*${PKG_VERSION}*i386* linux*${PKG_VERSION}*all*"
fi

FindGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

# We must match an arch image, arch headers, and 'all' headers files;
# Respond to not finding the desired version in the cache:
#
case ${#FILE_LIST[@]} in
3)
    ;;
1 | 2)
    ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
        "Could not locate all of the required files in '${SOURCE_DIR}' ! "
    ;;
0)
ERR_MSG="No cached packages for kernel ${PKG_VERSION} !
If you wish to install kernel ${PKG_VERSION}, you will need to download its
packages first.  (You may modify this script's internal parameters
to help automate this process; see the 'usage' prompt.) "
    echo
    ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" "${ERR_MSG}"
    ;;
*)
    ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Found too many matching files in '${SOURCE_DIR}' ! "
    ;;
esac

DEB_PACKAGE=${FILE_LIST}
#unset FILE_LIST
#FILE_LIST=( '*' )

PerformAppInstallation "-n"

#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Set up a chroot for repairing/updating a broken host
# ----------------------------------------------------------------------------
#

#
# Get the name of this script (for 'usage')
#
SOURCE="${BASH_SOURCE[0]}"
while [[ -h "${SOURCE}" ]] ; do SOURCE="$(readlink "${SOURCE}")" ; done
THIS_SCRIPT=$( basename ${SOURCE} .sh )
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

#
# Respond to a version query (-v)
#
if [[ "${1}" == "-v" || "${1}" == "--version" ]]; then

    echo "${THIS_SCRIPT}, v${VERSION} "
    exit 2
fi

#
# Display the 'usage' prompt (-h)
#
unset HELP
if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then HELP=true; fi
if [[ "${1}" != "-f" && "${1}" != "--fix"  ]]; then HELP=true; fi

if [[ ${HELP} == true ]]; then
    echo
    echo -n "usage: sudo ${THIS_SCRIPT} [ -f | -v | -h ] <device> "
    echo
    echo "This script does two things: "
    echo "  1.) Mounts a given block device on '/media/root' "
    echo "  2.) Performs 'mount --bind' operations to prep for a boot repair "
    echo
    echo "Options: "
    echo "    -f  --fix     = Perform the fixup operations "
    echo 

    exit 1
fi

shift

#
# Any other switch is an error...
#
if [[ $(echo ${1} | cut -c 1) == "-" ]]; then

    echo "${THIS_SCRIPT}: Switch error, '${1}' "
    exit 4
fi

#
# Verify that the user has launched us using 'sudo'.
#
ls /root > /dev/null 2>&1

if [[ $? != 0 ]]; then

    echo "${THIS_SCRIPT}: Must run this script as 'root'. "
    exit 8
fi

cd /media
mkdir root
mount ${1} root
(( $? != 0 )) && exit 1

cd root
mount --bind /proc proc
mount --bind /run run
mount --bind /sys sys
mount --bind /dev dev
mount --bind /dev/pts dev/pts

mount -l
pwd


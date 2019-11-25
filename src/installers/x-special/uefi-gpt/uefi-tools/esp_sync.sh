#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Sync the boot directory to the ESP & the ESP to its backup partitions
# ----------------------------------------------------------------------------
# 

MOUNT_DIR=/mnt
ESP_MOUNT_DIR=/boot/efi
ESP_EFI_DIR=EFI

ERR_WARNING=0
ERR_USAGE=1
ERR_NOSUDO=2
ERR_CMDFAIL=4
ERR_UNSPEC=8
ERR_FILEIO=16
ERR_MISSING=32
ERR_BADSWITCH=64


############################################################################
#
# Get the name of this script (for 'usage')
#
# $1 = Name of the calling script
# $2 = "unwind": Okay to unwind the link redirects
#
GetScriptName() {

local SCRIPT="${1}"

CORE_SCRIPT="${BASH_SOURCE[0]}"

if [[ ${2} == [uU]nwind ]]; then

    while [[ -h "${SCRIPT}" ]]; do 
        SCRIPT="$( readlink -- "${SCRIPT}" )";
    done
fi

APP_SCRIPT=$( basename "${SCRIPT}" .sh )

SCRIPT_DIR=$( cd "$( dirname "${0}" )" && pwd )
}

GetScriptName "${0}"

USAGE="
usage: sudo ${APP_SCRIPT} [ -s | -c | -v | -h ] 

This script mounts the backup EFI System Partitions and synchronizes 
them with the master ESP (which must be mounted). 

Options: 
    -s  --sync  = Sync '/boot' & the EFI System Partition 
    -l  --list  = List all ESP partitions & mounts 
    -c  --clean = Remove mounted ESP partitions in '/mnt'

Systems that are built on UEFI platforms require that at least one disk 
contain an 'EFI System Partition', or ESP.  The ESP contains files for 
booting the system, which may include boot managers, shim loaders (to 
combat problems caused by Secure Boot), GRUB for EFI, Windows loaders, 
and Linux kernels (that support 'stub loading').  

The ESP may also contain other apps such as EFI shells, memory testers, 
diagnostic tools, etc. that can be run pre-boot outside of any OS.  The 
ESP supports booting multiple operating systems, and is OS-agnostic.  
As such, the file system format of the ESP must be either FAT32, FAT16, 
or FAT12.  

Consequently, it is not practical to keep the '/boot' directory in the 
ESP to take advantage of stub-loading, particularly for Debian-based 
Linux, since the VFAT file system does not support actions required 
during kernel updates.  

This creates a problem for stub-loading, since the boot files must be 
either in ESP or accessible from it (using an EFI file system driver), 
yet there are currently no EFI drivers for accessing either RAID or LVM 
partitions, forcing the use of a 'boot' partition in ext4 format.

One solution is supported by this script: Store a copy of '/boot' in the 
ESP directory, which then needs to be updated whenever the boot files are 
updated.  In addition to sync'ing the '/boot' directory, this script also  
synchronizes the ESP with backup copies of the ESP kept on other drives. 
(In this way, any drive that mounts as '/dev/sda' can boot the system, 
and the boot files + the ESP files can exist as redundant copies.)
"

############################################################################
#
# Throw an error
#
# $1 = Exit code (set to '0' for 'no exit')
# $2 = Name of the script throwing the error
# $3 = Name of the function/routine throwing the error (optional)
# $4 = Message string
#
ThrowError() {

if (( $# > 3 )); then
    printf "%s: %s: error: %s \n" "${2}" "${3}" "${4}" >&2
else
    printf "%s: error: %s \n" "${2}" "${3}" >&2
fi

# Exit the script if the error code is not ERR_WARNING:
#
(( ${1} > ${ERR_WARNING} )) && exit
}


############################################################################
#
# Simple test to see if 'sudo' has already been obtained
#
QualifySudo() {

sudo ls /root >/dev/null 2>&1

if (( $? > 0 )); then
    ThrowError "${ERR_NOSUDO}" "${APP_SCRIPT}" \
            "Cannot run this script without 'sudo' privileges."
fi
}


############################################################################
#
# Display a prompt asking a Yes/No question, repeat until a valid input
#
# Allows for a blank input to be defaulted.  Automatically appends "(y/n)"
# to the prompt, capitalized according to the value of DEF_INPUT
#
# $1 = Default input, (y|n|<don't care>)
# $2 = Prompt
# 
# Returns 0 if Yes, 1 if No
#
GetYesNo_Defaulted() {

local PROMPT

case ${1} in
y | Y)
    PROMPT=${2}" [Y/n] "
    ;;
n | N)
    PROMPT=${2}" [y/N] "
    ;;
*)
    PROMPT=${2}" "
    ;;
esac

unset REPLY
while [[ ${REPLY} != "y" && ${REPLY} != "n" ]]; do

    read -e -r -p "${PROMPT}"
    [[ -z "${REPLY}" ]] && REPLY=${1}

    REPLY=${REPLY:0:1} && REPLY=${REPLY,,}
done

[[ ${REPLY} == "y" ]] && return
}


############################################################################
#
# List all the directories & mounts in '/mnt'
#
ListMountedPartitions() {

local MOUNT_LIST
local FOUND_DIR
local FOUND_MOUNT

MOUNT_DIR_CONTENTS=$( sudo ls -1 ${MOUNT_DIR}/ )

if [[ -z "${MOUNT_DIR_CONTENTS}" ]]; then 

    echo "'${MOUNT_DIR}' is empty..."
    return 1
fi

echo
echo "Contents of '${MOUNT_DIR}': "
sudo ls -l ${MOUNT_DIR}/

MOUNT_LIST=()
for FOUND_DIR in ${MOUNT_DIR_CONTENTS}; do
    
    FOUND_MOUNT=$( mount | grep "${MOUNT_DIR}/${FOUND_DIR}" )
    
    if [[ -n "${FOUND_MOUNT}" ]]; then
        MOUNT_LIST+=( "${FOUND_MOUNT}" )
    fi
done

(( ${#MOUNT_LIST[@]} == 0 )) && return

echo
echo "Devices mounted in '${MOUNT_DIR}': "
for FOUND_MOUNT in "${MOUNT_LIST[@]}" ; do

    echo "${FOUND_MOUNT}"
done
}


############################################################################
#
# Unmount all the partitions in /mnt & remove the directories there
#
# $1 = '-q' means "Quiet; Clean up '/mnt' without echoing output"
#
CleanUpMountedPartitions() {
    
local FOUND_PATH

if [[ -z "${1}" ]]; then

    ListMountedPartitions
    (( $? > 0 )) && return
    
    echo
    GetYesNo_Defaulted "n" "Umount and remove all?"
    (( $? > 0 )) && return
fi

MOUNT_DIR_CONTENTS=$( sudo ls -1 ${MOUNT_DIR}/ )

[[ -z "${MOUNT_DIR_CONTENTS}" ]] && return

for FOUND_DIR in ${MOUNT_DIR_CONTENTS} ; do

    FOUND_PATH=${MOUNT_DIR}/${FOUND_DIR}
    
    RESULT=$( mount | grep "${FOUND_PATH}" )

    if [[ -n "${RESULT}" ]]; then
        sudo umount ${FOUND_PATH}
        (( $? > 0 )) && echo "Cannot unmount '${FOUND_PATH}' ! "
    fi
    
    sudo rmdir ${FOUND_PATH}
    
    if (( $? > 0 )); then
        echo "Cannot remove '${FOUND_PATH}' ! "
    else
        [[ -z "${1}" ]] && echo "Removed '${FOUND_PATH}'... "
    fi
done
}

############################################################################
#
# Get lists of all the ESP partitions
#
CreateESPdriveLists() {

ESP_MOUNT=$( mount | grep -i "on ${ESP_MOUNT_DIR}" )

ESP_MASTER=$( mount | grep /dev/sd | grep ${ESP_MOUNT_DIR} | cut -d " " -f 1 )

DRIVE_LIST=$( sudo blkid | grep /dev/sd | cut -c 8 | sort | uniq )
}


############################################################################
#
# Create a device list for all ESP partitions
#
CreateESPdeviceList() {
    
local DEVICE
local DRIVE
local DEV_DRIVE
local PART

PART_LIST=()
MASTER_PART=""

for DRIVE in ${DRIVE_LIST}; do

    DEVICE="sd${DRIVE}"
    DEV_DRIVE=/dev/${DEVICE}

    PART=$( sudo gdisk -l ${DEV_DRIVE} | grep "\bEF00\b" | awk '{ print $1 }' )
    
    if [[ -n "${PART}" ]]; then
        
        PART="${DEVICE}${PART}"

        [[ "/dev/${PART}" == "${ESP_MASTER}" ]] && MASTER_PART=${PART}
        
        PART_LIST+=( ${PART} )
    fi
done
}


############################################################################
############################################################################
#
# Respond to a version query (-v)
#
if [[ "${1}" == "-v" || "${1}" == "--version" ]]; then

    echo "${APP_SCRIPT}, v${VERSION} "
    exit ${ERR_USAGE}
fi

#
# List all mounted & unmounted EFI System Partitions (-l)
#
if [[ "${1}" == "-l" || "${1}" == "--list" ]]; then

    CreateESPdriveLists
    CreateESPdeviceList
    
    echo
    echo -n "Devices found with EFI System Partitions: "
    
    if (( ${#PART_LIST[@]} == 0 )); then
        echo "None ! "
    else
        echo
        for PART in ${PART_LIST[@]}; do
            echo "/dev/${PART}"
        done
    fi
    
    echo
    if [[ -z "${ESP_MASTER}" ]]; then
        echo "No mounted EFI System Partition ! "
    else
        echo "Mounted EFI System Partition = '${ESP_MASTER}' "
    fi
    
    ListMountedPartitions
    exit $?
fi

#
# Clean up dangling mounted partitions (-c)
#
if [[ "${1}" == "-c" || "${1}" == "--clean" ]]; then

    CleanUpMountedPartitions
    exit $?
fi

#
# Display the 'usage' prompt (-h)
#
unset HELP
if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then HELP=true; fi
if [[ "${1}" != "-s" && "${1}" != "--sync" ]]; then HELP=true; fi

if [[ ${HELP} == true ]]; then

    echo "${USAGE}"
    exit ${ERR_USAGE}
fi

#
# Any other argument is an error...
#
shift
SWITCH=$( printf %s "${1}" | cut -c 1 )
[[ -n "${SWITCH}" ]] && ThrowError "${ERR_BADSWITCH}" "${APP_SCRIPT}" \
        "Unexpected argument, '${1}' "

#
# Verify that the user has launched us using 'sudo'.
#
QualifySudo

#
# Verify that the ESP is currently mounted; Create a reference to it;
# Create a list of all the hard drives:
#
CreateESPdriveLists

[[ -z "${ESP_MOUNT}" ]] && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not find a mounted ESP on this system ! "

[[ -z "${ESP_MASTER}" ]] && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not determine the master ESP on this system ! "

[[ -z "${DRIVE_LIST}" ]] && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not find any drives in this system ! "

#
# Create a list of all the ESP device partitions & sanity check:
#
CreateESPdeviceList

#
# Must have a Master ESP to sync from:
#
[[ -z "${MASTER_PART}" ]] && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not find a mounted ESP on this system ! "

#
# Mount all the ESP partitions (in /mnt):
#
for ESP_PART in "${PART_LIST[@]}"; do

    MNT_DRIVE=${MOUNT_DIR}/${ESP_PART}
           
    sudo mkdir ${MNT_DRIVE}
    (( $? > 0 )) && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
            "Cannot create '${MNT_DRIVE}' ! "
        
    sudo mount "/dev/${ESP_PART}" ${MNT_DRIVE}
    (( $? > 0 )) && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
            "Cannot mount '${ESP_PART}' ! "
done

#
# The Master ESP must have an 'EFI' directory:
#
RESULT=$( sudo ls ${MOUNT_DIR}/${MASTER_PART}/${ESP_EFI_DIR} )

[[ -z "${RESULT}" ]] && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot find an 'EFI' directory on this system's Master ESP ! " 

#
# Backup the '/boot' directory to the Master ESP's OS backup directory:
#
ESP_OS_DIR=$( mount | grep 'on / ' | awk '{ print $1 }' | \
        rev | cut -d '-' -f 1 | rev )

[[ -z "${ESP_OS_DIR}" ]] && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot determine the root partition block device for this system ! "
  
#
# This directory must already exist -- too dangerous to make it if this 
# is the first time backing up the '/boot' directory on this system:
#      
RESULT=$( sudo ls ${MOUNT_DIR}/${MASTER_PART}/${ESP_OS_DIR} )

[[ -z "${RESULT}" ]] && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot find an '${ESP_OS_DIR}' OS directory on the Master ESP ! " 

#
# Okay, now we're go for doing the boot directory sync:
#
echo "Synchronizing the '/boot' directory to the ESP... "
sleep 2

sudo rsync -rltDuvx --delete --modify-window=1 --exclude=${ESP_MOUNT_DIR} \
        /boot/ ${MOUNT_DIR}/${MASTER_PART}/${ESP_OS_DIR}/

#
# Must also have at least one backup ESP to sync to:
#
if (( ${#PART_LIST[@]} < 2 )); then

    echo "No backup EFI System Partitions exist -- nothing else to do ! "
    exit
fi
        
#
# Perform a sanity check for the user to verify:
#
sleep 2
echo
echo "Sanity test: syncing '/dev/${MASTER_PART}/' to '/dev/${PART_LIST[1]}/': "
echo
sleep 2

sudo rsync -n -rltDuvx --delete --modify-window=1 \
        "${MOUNT_DIR}/${MASTER_PART}/" \
        "${MOUNT_DIR}/${PART_LIST[1]}/" | grep -v '/$'

echo
GetYesNo_Defaulted "y" "Has the above passed the sanity test?"

if (( $? > 0 )); then

    echo "Sync not performed; the ESPs remain mounted in '${MOUNT_DIR}'... "
    exit ${ERR_CMDFAIL}
fi

#
# Perform the synchronization:
#
for ESP_PART in "${PART_LIST[@]}"; do

    [[ "${MASTER_PART}" == "${ESP_PART}" ]] && continue
    
    echo
    echo "Synchronizing '/dev/${MASTER_PART}/' to '/dev/${ESP_PART}/'... "
    echo
    sudo rsync -rltDuvx --delete --modify-window=1 \
            "${MOUNT_DIR}/${MASTER_PART}/" \
            "${MOUNT_DIR}/${ESP_PART}/" | grep -v '/$'
done

#
# Clean up by removing the mounted partitions & mount points:
#
CleanUpMountedPartitions -q
echo
echo "Done ! "

############################################################################
############################################################################


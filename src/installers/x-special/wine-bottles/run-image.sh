# #! /usr/bin/env bash
#
# Mount, unmount, or launch a script in an image file
# 
# This script file interoperates with a disk partition image, which can 
# be mounted, unmounted, or mounted with a 'launch' script executed.
#
SCRIPT_VERSION=1.0

###############################################################################
#
# Image file environment variables
#
# The script name is also the image file name, since the script is 
# embedded in the first 1MiB of the disk image file.
#
SCRIPT_NAME=$( basename "${0}" )

MOUNT_OFFSET=1048576

#
# First argument must be the image file to mount/run:
#
IMAGE_FILE=${1}
shift 

#
# Assume there's an additional argument and that it's a switch:
#
SWITCH=${1}

#
# If first arg is a switch, show the usage prompt:
# 
if [[ "${IMAGE_FILE:0:1}" == "-" ]]; then
    
    echo >&2 "${SCRIPT_NAME} version ${SCRIPT_VERSION} "
    echo >&2 "usage: ${SCRIPT_NAME} <image file> [ -m | -u | <command> ] "
    exit 2
fi 


###############################################################################
#
# Print an error message and abort with a non-zero return code
#
ThrowError() {
    echo >&2 "${SCRIPT_NAME}: ${1} ! "
    exit 1
}


###############################################################################
#
# Check to see if a (set of) 'glob' file names exist, and capture the names
#
# $1 = [literally] "basename" if only the basename is to be returned
# $2 = Source directory
# $3 = Depth of search
# $4 = Source glob(s)
#
# Returns the file list in ${FILE_LIST[@]}, $?=0 if at least one exists; 
# If only the first match is desired, use ${FILE_LIST}; 
#
FindGlobFilename() {

local BASE_ONLY
local FILE_GLOB
local FILE_NAME
local RESULT

BASE_ONLY=${1}
shift

FILE_DIR=${1}
shift

DEPTH=${1}
shift

FILE_LIST=()

(( DEPTH > 0 )) || ThrowError \
        "Bad value for 'depth', '${DEPTH}' in '${FUNCNAME}()' !"

#
# Loop once per glob in the provided list
#
RESULT=1
for FILE_GLOB in "$@"; do

    # Resolve the glob into an array of matching filenames:
    #
    while IFS= read -rd '' FILE_NAME; do

        if [[ ${BASE_ONLY,,} == "basename" ]]; then
        
            FILE_LIST+=( "$( basename ${FILE_NAME} )" )
            if [[ -f "${FILE_DIR}/${FILE_LIST}" ]]; then RESULT=0; fi
        else
            FILE_LIST+=( "${FILE_NAME}" )
            if [[ -f "${FILE_NAME}" ]]; then RESULT=0; fi
        fi

    done < <( find "${FILE_DIR}" -maxdepth ${DEPTH} -type f \
            -iname "${FILE_GLOB}" -print0 2>/dev/null )
done

return ${RESULT}
}


###############################################################################
#
# Check the second argument to determine if it's a mount/unmount switch
#
Check_Mount_Switch() {
    #
    # Set a global variable to communicate the mounting action. 
    # It's possible that no mount/unmount switch is specified,  
    # leading to three states: unset, 'mount', or 'umount'.
    #    
    local SWITCH_ARG

    if [[ -n "${1}" ]]; then
        # 
        # Reduce the switch argument to lower case & get the first two chars.
        #
        SWITCH_ARG=${SWITCH,,}
        
        case ${SWITCH_ARG:0:2} in
        
        '-m' )
            MOUNT_ACTION="mount"
            ;;
        '-u' )
            MOUNT_ACTION="unmount"
            ;;
        * )
            unset MOUNT_ACTION
        esac
    fi
}


###############################################################################
#
# Determine the mount point, if it exists, of the image file 
#
# Return 
#   0 = Bound, mounted, and resolved as MOUNT_PATH & VOLUME_LABEL
#   1 = Bound to a loop device, but not mounted
#   2 = Not bound to a loop device (and obviously not mounted)
#   3 = Error
#
Find_Mount_Point() {
    # 
    # If our script/image file shows up in the loop devices list, then 
    # extract the loop device path from the matching output of 'losetup'.
    # 
    #   'losetup -a' output (multi-line): 
    # 
    # /dev/loopX: []: (<file path>), offset <offset in bytes>
    #
    LOOP_DEV=$( /sbin/losetup -a | grep "${IMAGE_FILE}" | egrep -o '^[^:]+' )
    
    # Unfortunately, the above does not include mount information. 
    #
    # If no loop device is bound to our script/image file, return 'fail':
    #
    [[ -n "${LOOP_DEV}" ]] || return 2
    
    # The loop device exists, so use 'df' to see if it's mounted. 
    # 
    #   'df' output (multi-line):
    #
    # /dev/loopX  <size>  <used>  <avail>  <nn>%  <mount point>
    #
    VOLUME_LABEL=
    MOUNT_PATH=$( df | grep "${LOOP_DEV}" | awk '{ print $6 }' )
    
    # If the mount path fails to resolve, return an error code; 
    # If this occurs, both MOUNT_PATH and VOLUME_LABEL will be blank. 
    #    
    [[ -n "${MOUNT_PATH}" ]] || return 1
    
    # Everything after the (lone) '%' char is the mount path; 
    # The base name of this path is the volume label:
    #
    VOLUME_LABEL=$( basename "${MOUNT_PATH}" )
    
    [[ -n "${VOLUME_LABEL}" ]] || return 3
}


###############################################################################
#
# Determine if the image file is mounted, and mount it if it's not
#
# $1 = If '-q', and the image file is mounted, then return quietly; 
#      else output an 'already mounted' message & exit the script. 
#
Mount_Image() {
    # 
    # Attempt to resolve a mount point:
    #
    Find_Mount_Point
    
    # Then handle the possible results:
    #
    case $? in
    
    1 ) # Bound to a loop device, but not mounted. 
        # Use 'udisksctl' to mount, as it does not require 'sudo' 
        # elevation, and it will auto-create a mount directory:  
        #
        RESULT=$( udisksctl mount -b "${LOOP_DEV}" )

        # If the mount fails, we can't continue:
        #    
        (( $? == 0 )) || exit 1
        
        # But if successful, we still need the mount point:
        #
        Find_Mount_Point

        # If we still can't resolve a mount point, we can't continue:
        # 
        (( $? == 0 )) || ThrowError \
                "${IMAGE_FILE} is bound to '${LOOP_DEV}', but won't mount"
        ;;
        
    2 ) # Not bound to a loop device; Attempt to loop-mount the image file.
        # Use 'udisksctl' so that we don't have to have 'sudo' privileges.
        #
        RESULT=$( udisksctl loop-setup -o ${MOUNT_OFFSET} -f "${IMAGE_FILE}" )
        
        # If loop-mounting fails, then we cannot continue:
        #    
        (( $? == 0 )) || ThrowError \
                "Cannot bind '${IMAGE_FILE}' to a loop device for mounting"
        
        # If it succeeds, it should be bound & mounted; get the loop device:
        #
        LOOP_DEV=$( printf "%s" "${RESULT}" | grep -o '/dev/loop.' )
        
        [[ -n "${LOOP_DEV}" ]] || ThrowError \
                "Cannot determine the loop device bound to '${IMAGE_FILE}'"
        
        # Now that we have a valid loop device, get the mount point:
        #
        sleep 2
        Find_Mount_Point
        
        if (( $? != 0 )); then
            #
            # If it didn't mount, then try one more time...
            #
            RESULT=$( udisksctl mount -b "${LOOP_DEV}" )
            
            (( $? == 0 )) || ThrowError \
                    "Bound '${IMAGE_FILE}', but cannot mount '${LOOP_DEV}'"
            
            # Now try again to get the mount point:
            #
            sleep 2
            Find_Mount_Point
        fi
        
        # If we can't resolve the mount point, we can't continue:
        #    
        (( $? == 0 )) || ThrowError "Cannot mount '${IMAGE_FILE}'"
        ;;
        
    3 ) # Unknown system call error occurred...
        #
        ThrowError "Cannot determine a mount point for '${IMAGE_FILE}'"
        ;;
    esac   
    
    # At this point, we have a resolved mount point for the image file; 
    # If the 'quiet' switch was given, then quietly return:
    # 
    [[ "${1}" == "-q" ]] && return
    
    # Otherwise, echo an 'already mounted' message & exit successfully:
    #
    echo >&2 "${IMAGE_FILE} has been mounted as '${MOUNT_PATH}'. "
    exit
}


###############################################################################
#
# Determine if the image file is mounted, and unmount it if it is
#
Unmount_Image() {
    #
    # Check to see if the script/image file is already mounted:
    #
    Find_Mount_Point
    
    # Then handle the possible results:
    #
    case $? in
        
    0 ) # We're bound to a loop device and mounted.
        # Use 'udisksctl' to tear down, as it does not require 'sudo'.
        #
        RESULT=$( udisksctl unmount -b "${LOOP_DEV}" )
        
        (( $? == 0 )) || ThrowError "Cannot unmount '${LOOP_DEV}'"
        
        sleep 2
        Find_Mount_Point
        
        (( $? == 2 )) && exit
        ;&
    
    1 ) # We're bound to a loop device, but not mounted. 
        # Use 'udisksctl' to tear down, as it does not require 'sudo'.
        #
        RESULT=$( udisksctl loop-delete -b "${LOOP_DEV}" )
        exit $?
        ;;
        
    2 ) # Echo an 'already unmounted' message & exit successfully:
        #
        ThrowError "${IMAGE_FILE} is not mounted"
        ;;
        
    * ) # Unknown system call error occurred...
        #
        ThrowError "Cannot determine a mount point for '${IMAGE_FILE}'"
        ;;
    
    esac
}


###############################################################################
# 
# The first arg must be a image file; the file must at least exist:
#
[[ -r "${IMAGE_FILE}" ]] || ThrowError \
        "Cannot find bottle image file '${IMAGE_FILE}'"
        
#
# Check for an argument instructing us to mount/umount the image file:
#
Check_Mount_Switch "${1}"

#
# Are we to mount the IMG file?  If explicitly commanded to, 
# then do only that (echoing results to the console), and exit:
#
[[ "${MOUNT_ACTION}" == "mount" ]] && Mount_Image

#
# Are we to unmount the IMG file?  If so, umount & exit:
#
[[ "${MOUNT_ACTION}" == "unmount" ]] && Unmount_Image

#
# Check to see if the IMG file is mounted; mount it if not (quietly):
#
Mount_Image -q

# If the 'quiet' version of the above returns, it succeeded...
# Wait a second for the OS to complete the mounting process:
# 
sleep 3

#
# To keep things immune to file name dependencies/changes, look for the 
# first file in the mounted image that ends in '.sh' and go with that:
#
FindGlobFilename "fullpath" "${MOUNT_PATH}" 1 "*.sh"

# 
# If we've detected a launch script in the mounted image, run it; 
# Otherwise, tell the user we can't go any further:
#
if [[ $? -eq 0 && -x "${FILE_LIST}" ]]; then 
    
    exec "${FILE_LIST}" "$@"
else
    ThrowError "${SCRIPT_NAME}: Cannot find a script in ${MOUNT_PATH}"
fi

exit $?

###############################################################################



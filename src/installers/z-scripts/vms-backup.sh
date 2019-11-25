#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Backup a set of virtual machines to an external drive using 'tar'
# ----------------------------------------------------------------------------
#

USER_HOME=myself
USER_WORK=mywork

SOURCE_FOLDER=avmh
TARGET_FOLDER=Virtual

EXT_DRIVE_LABEL=SS840PRO_256GB

SOURCE_HOME=/home/${USER_HOME}
SOURCE_WORK=/home/${USER_WORK}

TARGET_HOME=/media/${USER_HOME}/${EXT_DRIVE_LABEL}
TARGET_WORK=/media/${USER_WORK}/${EXT_DRIVE_LABEL}

VM_LIST_ROOT=backup-list
VM_LIST_EXT=txt

BACKUP_EXT=tgz

#
# Find out where we are...
#
if [[ -d ${SOURCE_HOME} ]]; then

    SOURCE_LOCATION=${SOURCE_HOME}

elif [[ -d ${TARGET_WORK} ]]; then

    SOURCE_LOCATION=${SOURCE_WORK}

else
    echo "Cannot find a source directory ! "
    exit 1
fi

#
# Find out where we're going...
#
if [[ -d ${TARGET_HOME} ]]; then

    TARGET_LOCATION=${TARGET_HOME}

elif [[ -d ${TARGET_WORK} ]]; then

    TARGET_LOCATION=${TARGET_WORK}

else
    echo "Cannot find a target directory ! "
    exit 2
fi

#
# Is the target's directory there?
#
TARGET_FOLDER=${TARGET_LOCATION}/${TARGET_FOLDER}

if [[ ! -d "${TARGET_FOLDER}" ]]; then

    echo "Cannot find the target directory '${TARGET_FOLDER}' ! "
    exit 3
fi

cd "${TARGET_LOCATION}"

#
# We need a list of what to backup;
# There should be a set of list files in the backup directory...
#
BACKUP_LIST_FILES=()

while IFS= read -rd '' VM_FILE; do

    BACKUP_LIST_FILES+=( $( basename "${VM_FILE}" ) )

    done < <( find . -maxdepth 1 -type f \
    -iname "${VM_LIST_ROOT}*.${VM_LIST_EXT}" -print0 2>/dev/null )

#
# Now have the user pick one...
#
echo
echo "Please select one of the following backup list files: "

select VM_LIST in "${BACKUP_LIST_FILES[@]}"; do

    [[ -n "${VM_LIST}" ]] && break

    echo "Just pick one of the listed files, okay? "
done

#
# Now decide what to do with the response; a <Ctrl-D> means "cancel"...
#
if [[ -z "${VM_LIST}" ]]; then

    echo "Nothing backed up ! "
    exit 0
fi

#
# Check the items in the list -- are they all there?
#
BACKUP_LIST_DIRS=()
ERROR=false

while read -r VM_DIR; do

    if [[ -d "${VM_DIR}" ]]; then

        BACKUP_LIST_DIRS+=( "${VM_DIR}" )
    else
        echo "Can't find source directory '${VM_DIR}' ! "
        ERROR=true
    fi

done < <( cat ${TARGET_LOCATION}/${VM_LIST} )

#
# If even one is missing, quit and let the user fix the list file...
#
[[ $ERROR == true ]] && exit 4

#
# Now we're ready to begin the backup process...
#
cd "${TARGET_FOLDER}"

for VM_DIR in "${BACKUP_LIST_DIRS[@]}"; do

    VM_NAME=$( basename ${VM_DIR} )

    if [[ -f "${VM_NAME}.${BACKUP_EXT}" ]]; then

        ACTION="Replacing existing file"
        rm -f ${VM_NAME}.${BACKUP_EXT}
    else
        ACTION="Backing up '${VM_DIR}' as"
    fi

    echo "${ACTION} '${VM_NAME}.${BACKUP_EXT}' "
    tar zcf ${VM_NAME}.${BACKUP_EXT} ${VM_DIR}

done

###############################################################################

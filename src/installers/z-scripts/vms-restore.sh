#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Restore a set of virtual machines from an external drive using 'tar'
# ----------------------------------------------------------------------------
#

USER_HOME=myself
USER_WORK=mywork

SOURCE_HOME=/home/${USER_HOME}/avmh
SOURCE_WORK=/home/${USER_WORK}/avmh

TARGET_HOME=/media/${USER_HOME}/VIRTUAL
TARGET_WORK=/media/${USER_WORK}/VIRTUAL

TARGET_FOLDER=virtual

VM_LIST_ROOT=restore-list
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
    echo "Can't find the source directory ! "
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
    echo "Can't find the target directory ! "
    exit 2
fi

cd "${TARGET_LOCATION}"

#
# Is the external drive there?
#
TARGET_FOLDER=$TARGET_LOCATION/$TARGET_FOLDER

if [[ ! -d "${TARGET_FOLDER}" ]]; then

    echo "Can't find the backup directory, '${TARGET_FOLDER}' ! "
    exit 3
fi

#
# We need a list of what to restore;
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
echo "Please select one of the following restore list files: "

select VM_LIST in "${BACKUP_LIST_FILES[@]}"; do

    [[ -n "${VM_LIST}" ]] && break

    echo "Just pick one of the listed files, okay? "
done

#
# Now decide what to do with the response; a <Ctrl-D> means "cancel"...
#
if [[ -z "${VM_LIST}" ]]; then

    echo "Nothing restored ! "
    exit 0
fi

#
# Check the items in the list -- are they all there?
#
BACKUP_LIST_DIRS=()
ERROR=false

cd "${TARGET_FOLDER}"

while read -r VM_DIR; do

    VM_FILE=${VM_DIR}.${BACKUP_EXT}

    if [[ -f "${VM_FILE}" ]]; then

        BACKUP_LIST_DIRS+=( "${VM_FILE}" )
    else
        echo "Can't find backup file '${VM_FILE}' ! "
        ERROR=true
    fi

done < <( cat ${TARGET_LOCATION}/${VM_LIST} )

#
# If even one is missing, quit and let the user fix the list file...
#
[[ $ERROR == true ]] && exit 4

#
# Now we're ready to begin the restore process...
#
cd ${SOURCE_LOCATION}

for VM_FILE in "${BACKUP_LIST_DIRS[@]}"; do

    echo "Restoring '${TARGET_FOLDER}/${VM_FILE}' to '$( pwd )' ... "

    tar zxf "${TARGET_FOLDER}/${VM_FILE}"
done

###############################################################################

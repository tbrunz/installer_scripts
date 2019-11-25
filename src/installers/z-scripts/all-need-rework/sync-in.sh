#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Sync directories inbound
# ----------------------------------------------------------------------------
#

LOCAL_DIR=/home/myself/repo
SCRIPTS_DIR=z-scripts

MEDIA_DIR_1=/media
MEDIA_DIR_2=/media/$(whoami)

SHARED_WIN_DIR=sf_Windows/Repository/MULTIBOOT_64/installers
SHARED_LIN_DIR=sf_myself/ainst

SHARED_DIR=linux
THUMB_DIR=MULTIBOOT/installers/linux

T7500_IP=192.168.2.110
T7500_DIR=myself@${T7500_IP}:Documents/MULTIBOOT_64/installers

RSYNC_EXT="sudo rsync -auvx"
RSYNC_FAT="sudo rsync -rltDuvx --modify-window=1"

LOCAL_SCRIPTS=${LOCAL_DIR}/${SCRIPTS_DIR}/

#
# Qualify the use of 'sudo'
#
sudo ls /root >/dev/null 2>&1

if (( $? > 0 )); then
    ThrowError "${ERR_NOSUDO}" "${APP_SCRIPT}" \
            "Cannot run this script without 'sudo' privileges."
fi

#
# Create possible paths to the payoff:
#
PATH1=${MEDIA_DIR_1}/${SHARED_WIN_DIR}/${SHARED_DIR}
PATH2=${MEDIA_DIR_1}/${SHARED_LIN_DIR}/${SHARED_DIR}
PATH3=${MEDIA_DIR_2}/${SHARED_WIN_DIR}/${SHARED_DIR}
PATH4=${MEDIA_DIR_2}/${SHARED_LIN_DIR}/${SHARED_DIR}

#
# Try to copy from the host's shared directory:
#
for SHARED_PATH in ${PATH1} ${PATH2} ${PATH3} ${PATH4} ; do

    SOURCE_DIR=${SHARED_PATH}/${SCRIPTS_DIR}/

    if [[ -d "${SOURCE_DIR}" ]]; then
        read -rp "Start syncing from the Shared Folder into the VM? [Y/n] "
        if [[ $( printf %s ${REPLY^^}Y | cut -c 1 ) != N ]]; then
            echo 
            echo "********************** Run without '--delete' ********************** "
            ${RSYNC_EXT} ${SOURCE_DIR} ${LOCAL_SCRIPTS}
            echo 
            echo "****************** Dry-run with '--delete' added: ****************** "
            ${RSYNC_EXT} -n --delete ${SOURCE_DIR} ${LOCAL_SCRIPTS}
            echo    
            read -rp "Re-run with '--delete' added? [y/N] "
            if [[ $( printf %s ${REPLY^^}N | cut -c 1 ) != N ]]; then
                ${RSYNC_EXT} --delete ${SOURCE_DIR} ${LOCAL_SCRIPTS}
            fi
        fi
        break
    fi
done

#
# Only suggest net copy from the T7500 if we're *not* on the T7500...
#
SOURCE_DIR=${T7500_DIR}/${SCRIPTS_DIR}/

THIS_HOST=$( uname -n )
ping -q -c 1 -W 1 ${T7500_IP} 1>/dev/null 2>&1
if [[ ( $? == 0 && $THIS_HOST != "cricket" ) || $THIS_HOST != "t7500" ]]; then

    read -rp "Start syncing from the T7500 PC to the VM? [y/N] "
    if [[ $( printf %s ${REPLY^^}N | cut -c 1 ) != N ]]; then
        echo 
        echo "********************** Run without '--delete' ********************** "
        ${RSYNC_EXT} ${SOURCE_DIR} ${LOCAL_SCRIPTS}
        echo 
        echo "****************** Dry-run with '--delete' added: ****************** "
        ${RSYNC_EXT} -n --delete ${SOURCE_DIR} ${LOCAL_SCRIPTS}
        echo    
        read -rp "Re-run with '--delete' added? [y/N] "
        if [[ $( printf %s ${REPLY^^}N | cut -c 1 ) != N ]]; then
            ${RSYNC_EXT} --delete ${SOURCE_DIR} ${LOCAL_SCRIPTS}
        fi
    fi
fi

#
# Only suggest syncing to the USB drive if it's there...  (Try all forms)
#
PATH1=${MEDIA_DIR_1}/${THUMB_DIR}/${SCRIPTS_DIR}/
PATH2=${MEDIA_DIR_2}/${THUMB_DIR}/${SCRIPTS_DIR}/

for USB_PATH in ${PATH1} ${PATH2} ; do

    if [[ -d "${USB_PATH}" ]]; then 

        read -rp "Start syncing from the the USB drive to the VM? (Y/n) "
        if [[ $( printf %s ${REPLY^^}Y | cut -c 1 ) != N ]]; then
            echo 
            echo "********************** Run without '--delete' ********************** "
            ${RSYNC_FAT} ${USB_PATH} ${LOCAL_SCRIPTS}
            echo 
            echo "****************** Dry-run with '--delete' added: ****************** "
            ${RSYNC_FAT} -n --delete ${USB_PATH} ${LOCAL_SCRIPTS}
            echo    
            read -rp "Re-run with '--delete' added? (y/N) "
            if [[ $( printf %s ${REPLY^^}N | cut -c 1 ) != N ]]; then
                ${RSYNC_FAT} --delete ${USB_PATH} ${LOCAL_SCRIPTS}
            fi
        fi
        exit
    fi
done


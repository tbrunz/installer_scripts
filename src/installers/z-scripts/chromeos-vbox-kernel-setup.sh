#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Change kernel headers in ChromeOS / Install kernel headers in a 'chroot'
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
Installation of VirtualBox in a ChromeOS 'chroot' requires two operations be
performed before the actual installation of VirtualBox.  This is due to the
fact that the 'chroot' Linux distro does not have its own kernel installed,
but instead relies on the kernel of ChromeOS.

These operations consist of changing the kernel flags for the ChromeOS kernel,
rebooting to have the new kernel settings take effect, then setting up the
ChromeOS kernel headers in the 'chroot' Linux distro.

Once this is done, the VirtualBox installer will be able to build its custom
installable kernel module as part of installing VirtualBox in the 'chroot'.

This script downloads a pair of scripts to accomplish the above.  If ChromeOS
is detected as the running operating system, then the script will also request
to change the ChromeOS kernel flags.  If not, then the script will request
to set up the kernel headers in the target OS.

https://github.com/dnschneid/crouton/wiki/Build-kernel-headers-and-install-Virtualbox-(x86)
https://github.com/divx118/crouton-packages
"

#
# Location parameters
#
DIR_DOWNLOADS=~/Downloads
DIR_BACKUP=${DIR_DOWNLOADS}/Backup

DIR_SCRIPTS_CROUTON=${DIR_DOWNLOADS}/Crouton
DIR_ARCHIVE_CROUTON=${DIR_SCRIPTS_CROUTON}/archive

#
# Kernel flags & headers scripts location & names
#
DIVX118_REPO=https://raw.githubusercontent.com/divx118
DIVX118_CROUTON=${DIVX118_REPO}/crouton-packages/master

KERNEL_FLAGS_SCRIPT="change-kernel-flags"
KERNEL_HEADERS_SCRIPT="setup-headers.sh"


##################################################################
#
# Download ChromeOS kernel flags & headers scripts
#
Get_ChromeOS_Kernel_Script() {
    #
    # Download the script given by $1
    #
    local KERNEL_SCRIPT=${1}

    # We don't have to be running ChromeOS to download the script, but we do
    # have to have a 'Crouton' folder in our Downloads folder to receive it.
    #
    [[ -d "${DIR_DOWNLOADS}" ]] || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
            "${FUNCNAME}" "No 'Downloads' directory ! "

    # Since the 'Downloads' directory exists, try to make a 'Crouton'
    # directory in it, if it doesn't already exist:
    #
    mkdir -p "${DIR_SCRIPTS_CROUTON}" || ThrowError "${ERR_FILEIO}" \
            "${APP_SCRIPT}" "${FUNCNAME}" "No 'Crouton' directory ! "

    # Having found or created it, now 'cd' to the Crouton Scripts directory:
    #
    cd "${DIR_SCRIPTS_CROUTON}" || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
            "${FUNCNAME}" "Can't find '${DIR_SCRIPTS_CROUTON}' ! "

    # If the script already exists, ask the user if he wants to replace it.
    # If 'no', then return success -- the existing script is a win.
    #
    [[ -e "${KERNEL_SCRIPT}" ]] && Get_YesNo_Defaulted -y \
            "Script '${KERNEL_SCRIPT}' already exists.. Replace?" || return 0

    # This could possibly fail, but failure won't stop the download...
    #
    mkdir -p "${DIR_ARCHIVE_CROUTON}"

    # If the script already exists, and the archive directory exists, then
    # try to back up the existing script first.
    #
    [[ -e "${KERNEL_SCRIPT}" && -d "${DIR_ARCHIVE_CROUTON}" ]] && \
            mv "${KERNEL_SCRIPT}" "${DIR_ARCHIVE_CROUTON}"/ || \
                    ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" "${FUNCNAME}" \
                    "Can't backup '${KERNEL_SCRIPT}' ! "

    # Now download the requested script and complain if this fails:
    #
    wget ${DIVX118_CROUTON}/${KERNEL_SCRIPT} || ThrowError "${ERR_CMDFAIL}" \
        "${APP_SCRIPT}" "${FUNCNAME}" "Can't download '${KERNEL_SCRIPT}' ! "

    chmod 774 ${KERNEL_SCRIPT} || ThrowError "${ERR_FILEIO}" \
            "${APP_SCRIPT}" "${FUNCNAME}" "Can't chmod '${KERNEL_SCRIPT}' ! "

    echo "Downloaded '${KERNEL_SCRIPT}'... "
    sleep 2
}

#
# Download scripts needed to install VirtualBox:
#
Get_Vbox_Kernel_Scripts() {
    local KERNEL_SCRIPT
    local SCRIPT_ARY=(
        "${KERNEL_FLAGS_SCRIPT}"
        "${KERNEL_HEADERS_SCRIPT}"
    )

    # Step through the array and download each script, as necessary/allowed:
    #
    for KERNEL_SCRIPT in "${SCRIPT_ARY[@]}"
    do
        Get_ChromeOS_Kernel_Script "${KERNEL_SCRIPT}" || \
                ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" "${FUNCNAME}" \
                "Can't download '${KERNEL_SCRIPT}' ! "
    done
}

##################################################################
#
# Run a ChromeOS/VirtualBox prep script
#
Run_Vbox_Prep_Script() {
    local VBOX_PREP_SCRIPT=${1}

    Get_Vbox_Kernel_Scripts
    RESULT=$?
    (( RESULT == 0 )) || return ${RESULT}

    cd "${DIR_SCRIPTS_CROUTON}" 2>/dev/null
    (( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" "${FUNCNAME}" \
            "Can't find '${DIR_SCRIPTS_CROUTON}' ! "

    [[ -e "${VBOX_PREP_SCRIPT}" ]] || ThrowError "${ERR_MISSING}" \
            "${APP_SCRIPT}" "${FUNCNAME}" "Can't find '${VBOX_PREP_SCRIPT}' ! "

    QualifySudo
    sudo sh "${VBOX_PREP_SCRIPT}"
    (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" "${FUNCNAME}" \
                "Error running '${VBOX_PREP_SCRIPT}' ! "
}

#
# If the platform is ChromeOS, download the scripts and change the kernel flags
#
Change_ChromeOS_Kernel_Flags() {
    Exit_if_OS_is_not_ChromeOS ${FUNCNAME}

    Run_Vbox_Prep_Script "${KERNEL_FLAGS_SCRIPT}"
    RESULT=$?
    (( RESULT == 0 )) || return ${RESULT}

    echo ""
    echo "Now enter the 'chroot' and run this script again to set up the "
    echo "ChromeOS kernel headers for VirtualBox installation in the 'chroot'. "
    echo "Afterwards, VirtualBox should install normally. "
}

#
# If the platform is a 'chroot', download the scripts & setup the kernel headers
#
Setup_ChromeOS_Kernel_Headers() {
    Exit_if_OS_is_ChromeOS ${FUNCNAME}

    Run_Vbox_Prep_Script "${KERNEL_HEADERS_SCRIPT}"
    RESULT=$?
    (( RESULT == 0 )) || return ${RESULT}

    echo ""
    echo "Now run the VirtualBox install script, which should succeed. "
}

##################################################################
##################################################################
#
# Do the install -- depending on which platform this is run on:
#
Exit_if_OS_is_not_ChromeOS "${APP_SCRIPT}"

if [[ ${IS_CHROME_OS} ]]; then

    Change_ChromeOS_Kernel_Flags
else
    Setup_ChromeOS_Kernel_Headers
fi


##################################################################
##################################################################
#
# ChromeOS: Output of running "change-kernel-flags" script
#
: << "END_CHANGE_KERNEL_FLAGS"

/tmp/change-kernel-flags.adu.4
Saving Kernel B config to /tmp/change-kernel-flags.adu.4
(Kernels have not been resigned.)

Kernel flags added or changed are:
"lsm.module_locking=0 disablevmx=off"

Full cmdline is:
console= loglevel=7 init=/sbin/init cros_secure oops=panic panic=-1 root=/dev/dm-0 rootwait ro dm_verity.error_behavior=3 dm_verity.max_bios=-1 dm_verity.dev_wait=1 dm="1 vroot none ro 1,0 2506752 verity payload=PARTUUID=%U/PARTNROFF=1 hashtree=PARTUUID=%U/PARTNROFF=1 hashstart=2506752 alg=sha1 root_hexdigest=ab498bb8ca011ab439ea02000f6e0fdfb888f14d salt=54d05e36d80cb11eff6eb5626872a072b6b1e0f0f009c824386c0b33595e72e7" noinitrd vt.global_cursor_default=0 kern_guid=%U add_efi_memmap boot=local noresume noswap i915.modeset=1 tpm_tis.force=1 tpm_tis.interrupts=0 nmi_watchdog=panic,lapic i915.enable_psr=1   lsm.module_locking=0 disablevmx=off

Do you want to apply those changes (y/N)?y
 Kernel B: Replaced config from /tmp/change-kernel-flags.adu.4
Backup of Kernel B is stored in: /mnt/stateful_partition/backups/kernel_B_20160610_214217.bin
Kernel B: Re-signed with developer keys successfully.
Successfully re-signed 1 of 1 kernel(s)  on device /dev/sda.
dev_boot_usb           = 1                              # Enable developer mode boot from USB/SD (writable)
dev_boot_legacy        = 1                              # Enable developer mode boot Legacy OSes (writable)
dev_boot_signed_only   = 0                              # Enable developer mode boot only from official kernels (writable)

Reboot to make the changes take effect.

END_CHANGE_KERNEL_FLAGS


##################################################################
#
# ChromeOS: Method to mount the ChromeOS root partition as read/write
#
: << "END_MOUNT_ROOT_RW"

__mount_root_rw() {
    sudo /usr/share/vboot/bin/make_dev_ssd.sh --remove_rootfs_verification
}

mount_root_rw() {

echo "The Chromium OS rootfs is mounted read-only. In developer mode you "
echo "can disable the rootfs verification, enabling it to be modified. "
echo ""
echo "NOTE: If you mount the root filesystem in writeable mode, even if "
echo "you make no changes, it will no longer be verifiable and you'll have "
echo "to use a recovery image to restore your system when you switch back "
echo "to normal mode.  "
echo ""
echo "NOTE: Auto updates may also fail until a full payload is downloaded. "
echo ""
echo "To make your rootfs writable, run this (alias) from a shell: "
echo ""
echo "    __mount_root_rw "
echo ""
echo "Then reboot. Your rootfs will then be mounted read/write. "
echo ""
}

END_MOUNT_ROOT_RW

##################################################################

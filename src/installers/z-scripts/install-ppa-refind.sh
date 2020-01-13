#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'rEFInd' using Rod Smith's PPA repository.
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

GetOSversion

USAGE="
This package installs the rEFInd UEFI boot manager.

rEFInd is a fork of the rEFIt boot manager.  Like rEFIt, rEFInd can auto-
detect your installed EFI boot loaders, and it presents a nice GUI menu of
boot options.

rEFInd goes beyond rEFIt in that rEFInd better handles systems with many
boot loaders, gives better control over the boot loader search process, and
provides the ability for users to define their own boot loader entries.

Features:
    * Support for EFI 1.x and UEFI 2.x computers.
    * Support for Mac and PC platforms.
    * Graphical and text-mode boot selector.
    * Auto-detection of available EFI boot loaders.
    * Directly launch Linux 3.3.0+ kernels with EFI stub loader support.
    * Maintenance-free Linux kernel updates: Boot-time auto-detection means
      that no configuration file changes are needed after a kernel update.
    * Set/edit boot-time options from a list.
    * Launch EFI programs such as an EFI shell (available from third parties).
    * Launch OS X and Windows recovery tools.
    * Reboot into the firmware setup utility (on some UEFIs).
    * Try before installation via booting a CD-R or USB flash drive image.
    * Secure Boot support (requires separate shim or PreLoader program).
    * Includes EFI drivers for ext2/3/4fs, ReiserFS, Btrfs, HFS+, and ISO-9660.

Refer to the post-install notes regarding important requirements & procedures.

http://www.rodsbooks.com/refind/
"

POST_INSTALL="
Note the following requirements & procedures for enabling rEFInd to boot Linux:

    * NOTE! If you are installing your Linux distro using LVM, and plan to boot 
      with rEFInd using a stub loader, you *MUST* create a separate non-LVM boot 
      partition to be mounted as '/boot'.  Although GRUB is now able to read LVM 
      partitions to find Linux root file systems, rEFInd is currently unable to 
      do so.  rEFInd can read most of the popular Linux & non-Linux file system 
      formats, but only in static partitions.  No LVM logical volumes will be 
      searched by rEFInd on bootup.
          
    * Given the above, if RAID is to be used for the installation, then the boot 
      partition must be built using RAID-1 with --metadata=0.90 so that rEFInd 
      can read a single mirror as though it were a non-RAID partition.  (This is 
      also the appropriate RAID configuration for allowing the system to boot if 
      one of its boot partition RAID-1 mirrors were to fail.)
    
    * The Ubuntu installer application, Ubiquity, can install Ubuntu with either 
      a GRUB boot loader or a UEFI boot loader, depending on whether or not the 
      installer itself was booted using UEFI.  However, Ubiquity cannot install 
      rEFInd (or detect it) as part of its installation process; it installs a 
      'shim loader' to be compatible with Secure Boot (assumed to be enabled). 
      
    * Consequently, rEFInd must be installed manually.  The best time to do this 
      is after the OS has been installed, but prior to the first 'boot into your 
      new operation system' event.  This implies that you should install Ubuntu 
      by booting into 'Try Ubuntu' mode rather than selecting 'Install Ubuntu'.  
      In this way, you have the Ubuntu GUI to use in defining/inspecting disk 
      partitions, installing Ubuntu, downloading/installing rEFInd, & verifying 
      the entire configuration before your first reboot.
    
    * After the OS has been installed and rEFInd has been installed (using this 
      script), you may need to reconfigure your system's NVRAM to point to the 
      rEFInd bootloader.  (Until then, both Windows' and Ubuntu's bootloaders 
      will compete for booting the system exclusively.)  Details on how to edit 
      your NVRAM depends on your system's UEFI BIOS; refer to your system's 
      documentation for these procedures.
    
    * When the rEFInd boot manager is launched by the UEFI BIOS, it will look 
      for loadable OSes and their boot loaders; this includes 'stub loaders' for
      loading Linux distros.  (This is the easiest way to specify Linux OSes for
      loading in UEFI.)  These stub loaders are text files that must be copied 
      into each Linux distro's '/boot' directory, then customized to locate the 
      distro's root partition.  Note that neither the rEFInd installer nor this 
      script will automatically install these stub loaders.  You must do this as 
      a manual post-install step.
    
    * A template stub loader, 'installers/linux/refind/refind_linux.conf', can 
      be copied to '/boot' & edited for this purpose.  This template allows for 
      Linux root partitions to be installed in either static partitions or in 
      LVM logical volumes.  Uncomment the appropriate pair of lines and edit 
      the '%<partition-spec>%' variables to match your system's installation 
      location.  The first quoted string in each line provides a name that will
      be used by rEFInd to display a boot option; if selected, the remainder of 
      the line will be passed to the kernel as the 'cmdline' string (which can 
      be displayed post-boot using 'cat /proc/cmdline').
"

SET_NAME="rEFInd"
PACKAGE_SET="refind  "

# Are we a Trusty (or earlier) installation?
#
if (( MAJOR < 21 )); then

    PACKAGE_SET="${PACKAGE_SET}  ppa-purge  "

    REPO_NAME="${SET_NAME} (PPA)"
    REPO_URL="ppa:rodsmith/refind"
    REPO_GREP="rodsmith.*refind.*${DISTRO}"
fi

PerformAppInstallation "$@"

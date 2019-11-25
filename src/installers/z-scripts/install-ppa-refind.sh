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

http://www.rodsbooks.com/refind/
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

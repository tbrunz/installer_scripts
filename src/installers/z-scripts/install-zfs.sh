#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the ZFS file system support packages
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
ZFS is a combination of a volume manager (like LVM) and a filesystem (like
ext4, xfs, or btrfs).

ZFS is used primarily in cases where data integrity is important.  It's
designed not just to store data but to continually check on that data to
make sure it hasn't been corrupted.  The oversimplified version is that
the filesystem generates a checksum for each block of data.  That checksum
is then saved in the pointer for that block, and the pointer itself is
also checksummed.

This process continues all the way up the filesystem tree to the root node,
and when any data on the disk is accessed, its checksum is calculated again
and compared against the stored checksum to make sure that the data hasn't
been corrupted or changed.  If you have mirrored storage, the filesystem
can seamlessly and invisibly overwrite the corrupted data with correct data.

This and other resiliency features make ZFS a popular filesystem for file
storage, and it's the default filesystem for storage-oriented operating
systems like FreeNAS.  These are a few of the killer features:

* Snapshots
* Copy-on-write cloning
* Continuous integrity checking against data corruption
* Automatic repair
* Efficient data compression

These features make ZFS the perfect filesystem for containers.

Ubuntu 16.04 LTS makes it easy to deploy a ZFS file-system utilizing 'ZFS
On Linux' (ZOL), an OpenZFS-based implementation.  All of the necessary ZOL
components are in place from the DKMS module support to the user-space
utilities that are part of the main packaging archive, but not installed
by default.

ZOL in 16.04 is very similar to the ZFS On Linux experience that's been
available for years either through the use of PPAs or building the ZOL
components from source, but now it's formally supported by Canonical/Ubuntu.

ZFS support was added to Ubuntu Wily 15.10 as a technology preview and comes
fully supported in Ubuntu Xenial 16.04.  Note that ZFS is only supported on
64-bit architectures.

https://wiki.ubuntu.com/Kernel/Reference/ZFS
http://blog.dustinkirkland.com/2016/02/zfs-is-fs-for-containers-in-ubuntu-1604.html
http://www.phoronix.com/scan.php?page=article&item=ubuntu-xenial-zfs&num=1
"

SET_NAME="ZFS filesystem support"
PACKAGE_SET="zfsutils-linux  zfs-initramfs  zfs-dkms  zfsnap  simplesnap  "

# ZFS requires 64-bit installations;
# Support is via FUSE prior to 16.04, native for 16.04+
#
GetOSversion
[[ ${ARCH} != "x86_64" ]] && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "ZFS is only supported on 64-bit architectures ! "

if (( MAJOR < 16 && MINOR < 10 )); then

    PACKAGE_SET="zfs-fuse  "
fi

PerformAppInstallation "$@"

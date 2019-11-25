
zfs-auto-snapshot
=========================================

An alternative implementation of the zfs-auto-snapshot service for Linux
that is compatible with zfs-linux and zfs-fuse.

Automatically create, rotate, and destroy periodic ZFS snapshots. This is
the utility that creates the @zfs-auto-snap_frequent, @zfs-auto-snap_hourly,
@zfs-auto-snap_daily, @zfs-auto-snap_weekly, and @zfs-auto-snap_monthly
snapshots if it is installed.

This program is a posixly correct bourne shell script.  It depends only on
the zfs utilities and cron, and can run in the dash shell.

Installation:
-------------

wget https://github.com/zfsonlinux/zfs-auto-snapshot/archive/master.zip
unzip master.zip
cd zfs-auto-snapshot-master
make install

-----

Websites:

https://github.com/zfsonlinux/zfs-auto-snapshot

https://pthree.org/2012/12/13/zfs-administration-part-viii-zpool-best-practices-and-caveats/

http://www.solarisinternals.com/wiki/index.php/ZFS_Best_Practices_Guide

-----


#! /usr/bin/env bash

# xorg-edgers-live-test v238
# by Tormod Volden 2008
# A script to be run in an Ubuntu live CD session
# Installs xorg test packages from xorg-edgers PPA

set -e

# Find out which display manager we're using
RESULT=$( ps -ef | grep '^root' | grep '/var/run/gdm' )
if (( $? == 0 )); then DISP_MGR=gdm
else
    RESULT=$( ps -ef | grep '^root' | grep '/var/run/lightdm' )
    if (( $? == 0 )); then DISP_MGR=lightdm
    else echo "Can't determine the display manager! "; exit 1
    fi
fi

# Save downloaded packages for next time
if [ "$1" = "savedebs" ]; then
  CDDEV=`grep /cdrom /proc/mounts|cut -d" " -f1`
  mount -o remount,rw $CDDEV /cdrom
  echo "Saving downloaded packages"
  rsync --size-only -a /var/cache/apt/archives/*.deb `dirname $0`/archives/ 
  mount -o remount,ro $CDDEV /cdrom
  exit 0
fi

# If you disable this check you'll break the warranty :)
if [ "`ls /home`" != "ubuntu" ] || [ ! -d /cdrom/casper ]; then
	echo "This doesn't seem like a live session! Aborting..."
	exit 1
fi

# We can not run this script inside X because we will restart it
TTY=`tty`
if [ "${TTY%?}" != "/dev/tty" ]; then
	echo "You should run this on a virtual console, since it will restart X"
	exit 1
fi

# Copy over saved package cache to save downloading
echo "Looking for saved packages..."
rsync --size-only -a `dirname $0`/archives/ /var/cache/apt/archives/ || echo "... will download everything"

# Minimal Software Sources to speed up apt-get update
SS=/etc/apt/sources.list
[ -e $SS.bak ] || cp -a $SS $SS.bak
RELEASE=$(lsb_release --short --codename)
echo "deb http://archive.ubuntu.com/ubuntu/ $RELEASE main" > $SS
echo "deb http://archive.ubuntu.com/ubuntu/ $RELEASE universe" >> $SS
echo "deb http://ppa.launchpad.net/xorg-edgers/ubuntu $RELEASE main" >> $SS
echo "#deb-src http://ppa.launchpad.net/xorg-edgers/ubuntu $RELEASE main" >> $SS
echo "#deb http://ppa.launchpad.net/tormodvolden/ubuntu $RELEASE main" >> $SS
apt-get update

# Upgrade mesa first, then xserver-xorg-core with drivers
apt-get install --assume-yes --force-yes libdrm2 libgl1-mesa-dri libgl1-mesa-glx libglu1-mesa mesa-utils
apt-get install --assume-yes --force-yes xserver-xorg-core xserver-xorg-video-vesa xserver-xorg-input-evdev x11-common xserver-xorg-video-ati xserver-xorg-video-intel

# Add your preferred driver here
#apt-get install --assume-yes --force-yes xserver-xorg-video-radeonhd

# Upgrade anything else available
apt-get upgrade --assume-yes --force-yes || UPGRADEMESS=1

# Get the source and build the drm kernel modules
if [ $BUILD_DRM ]; then
    apt-get install --assume-yes --force-yes drm-modules-source module-assistant
    module-assistant -t auto-install drm-modules
fi

# Shutdown Xorg
service ${DISP_MGR} stop || true
sleep 2
# just in case ${DISP_MGR} stop does not work
killall ${DISP_MGR} || true
sleep 2

if [ $BUILD_DRM ]; then
    MOD=$( lsmod | awk '/^drm/{print $4}' )
    modprobe -r $MOD
    modprobe -r drm
fi

# A broken kernel module *might* mess with your hard drive
echo "Disabling all swap for safety reasons"
swapoff -a

# Let operator clean up if needed
if [ $UPGRADEMESS ]; then
	echo Package upgrade failed. You might need to fix it.
	echo Press Enter to restart X, or crtl-c to exit.
	read nothing
fi

echo "Will now restart X"
sleep 3
service ${DISP_MGR} start


#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install CrossOver from '.deb' (will operate as a demo unless registered)
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
Recommendation: Unless you know you need to install the 'bin' version of this
package, use the 'deb' version instead.

CrossOver is a Microsoft Windows compatibility layer (not an emulator or a
virtual machine) available for Linux distributions & for Mac OS X.  This
compatibility layer (API) enables many Microsoft Windows-based applications
to run in Linux or Mac OS X operating systems.

CrossOver, developed by CodeWeavers (http://www.codeweavers.com/), is based
on Wine (http://www.winehq.org/), an open-source Windows compatibility layer.

CodeWeavers modifies the Wine source code, applies compatibility patches,
adds configuration tools that are more user-friendly, and provides technical
support.  CodeWeavers employs several Wine software developers, and
contributes source code to Wine.  (Such contributions are obligatory under
Wine's software license, the LGPL.)

This package installs CrossOver Linux as 'root', making it available to all
users on the system.

Note that CrossOver will install from a cached '.deb' file; there may be a
newer version available on the CodeWeavers web site.

Also note that the installation is a 30-day trial, and must be unlocked to
be used beyond that (via a paid subscription from CodeWeavers).

http://www.codeweavers.com/products/crossover-linux/download/
"

POST_INSTALL="
You may wish to check the CodeWeavers website in order to get the latest
version of CrossOver Linux.  http://www.codeweavers.com/

"

SET_NAME="Crossover (deb)"

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

PACKAGE_SET="python-dbus  python-gtk2  python-qt4
    icoutils  apt-transport-https  ocl-icd-libopencl1  multiarch-support  "

SOURCE_DIR="../crossover"

QualifySudo
if [[ ${ARCH} =~ "64" ]]; then

    sudo dpkg --add-architecture i386

    PACKAGE_SET="${PACKAGE_SET}
    libavfilter6:i386  libavformat57:i386  libtesseract4:i386  
    libfontconfig1:i386  libgphoto2-6:i386  libgphoto2-port12:i386
    libgsm1:i386  libmpg123-0:i386  libopenal1:i386  libosmesa6:i386
    libsane:i386  libtiff5:i386  libv4l-0:i386  libxcomposite1:i386
    libxinerama1:i386  libxml2:i386  libxslt1.1:i386  libpulse0:i386
    libasound2:i386  libnss-mdns:i386  gstreamer1.0-libav:i386
    libvulkan1:i386  gstreamer1.0-plugins-good:i386  libsrtp0:i386  
    gstreamer1.0-plugins-bad:i386  gstreamer1.0-plugins-ugly:i386
    libmplex2-2.1-0:i386  libmjpegutils-2.1-0:i386  libmpeg2encpp-2.1-0:i386  "

    if (( MAJOR == 19 && MINOR == 10 )); then
        SOURCE_GLOB="multiarch-support*64*deb"
        
        ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
        DEB_PACKAGE=${FILE_LIST}

        PerformAppInstallation "-r" "$@"
    fi
fi

if (( MAJOR < 18 )); then
    
    PACKAGE_SET="${PACKAGE_SET}
    libavfilter-ffmpeg5:i386  libavformat-ffmpeg56:i386  
    libchromaprint0:i386  libopencv-contrib2.4v5:i386  
    libopencv-highgui2.4v5:i386  libopencv-legacy2.4v5:i386  
    libopencv-objdetect2.4v5:i386  libsidplay1v5:i386  "
else
    REPO_NAME="sdl2-backport"
    REPO_URL="ppa:cybermax-dexter/sdl2-backport"
    REPO_GREP="cybermax-dexter.*ubuntu.*${DISTRO}"
fi

#SIGNING_KEY=https://dl.winehq.org/wine-builds/Release.key
#SIGNING_KEY=../wine/winehq.key

SOURCE_GLOB="*deb"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
DEB_PACKAGE=${FILE_LIST}

PerformAppInstallation "-r" "$@"

# Crossover may fail for lack of gobs of i386 packages...  Fix it:
#
sudo apt-get install -f

InstallComplete

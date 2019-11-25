#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Xorg Edgers PPA to access latest video drivers
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
The 'X Updates' PPA provides updated versions of X.org drivers, libraries, etc.
for Ubuntu.

This PPA is for stable upstream releases of X.org components.  If you're looking
for something even more bleeding-edge, see the 'xorg-edgers' PPA installation
script instead.

If you are upgrading from one release to another with this PPA activated, you
must first downgrade everything installed from this PPA beforehand, using the
purge option:

    $ bash ./${APP_SCRIPT}.sh -p --purge

https://launchpad.net/~ubuntu-f-swat/+archive/x-updates
"

POST_INSTALL="
Next step:  Install one of the available drivers from the 'Additional Drivers'
tab of the 'Software & Updates' system settings dialog box.  (Access either from
the 'Settings...' menu, or by searching for 'Software & Updates'.)

If you are upgrading from one release to another with this PPA activated, you
must first downgrade everything installed from this PPA beforehand, using the
'ppa-purge' package:

    $ sudo ppa-purge ubuntu-f-swat/x-updates

NOTE: If you are on an Intel 965 or newer GPU, you will need to install a 3.6 or
newer kernel ('linux-generic-lts-raring' if you are on 12.04) since mesa 9.2 now
requires a 3.6 kernel.

NOTE: SNA is now on by default in Intel drivers.  If you have problems (such as
screen corruption, parts of the screen not updating, or crash reports regarding
'intel_drv.so' in the 'Xorg.0.log' backtrace), add this to (or update) your
'/etc/X11/xorg.conf' to revert back to using UXA:

    Section \"Device\"
            Identifier \"intel\"
            Driver \"intel\"
            Option \"AccelMethod\" \"uxa\"
    EndSection

To revert this PPA package installation back to the official packages, re-run
the script with '-p --purge' added.  (This currently has issues in Oneiric
because 'ppa-purge' in Oneiric does not work with multiarch.)  Using 'ppa-purge'
on packages from this PPA do purge correctly on Precise and later distros.
"

SET_NAME="X Updates video drivers"
PACKAGE_SET="ppa-purge  "

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL="ppa:ubuntu-f-swat/x-updates"
REPO_GREP="ubuntu.*swat.*x-updates.*${DISTRO}"

case ${1} in
"-n" | "-u")
    ;;
"-p" | "-i")
    PerformAppInstallation "$@"
    exit
    ;;
*)
    PerformAppInstallation
    ;;
esac

PerformAppInstallation "-r" "-u"

sudo apt-get -y dist-upgrade

InstallComplete

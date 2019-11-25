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
The Xorg Edgers (AKA the 'Xorg Crack Pushers Team') repackages the latest video
drivers from upstream sources for Ubuntu and makes them available via their PPA.

These are 'bleeding edge' video drivers intended for testing of new upstream
versions, and may contain bugs that will crash your system.  \"Expect to screw
up your X if you try this out.\"

For older/more stable updates (which may not support the latest distro), see the
Ubuntu X Updates PPA installation script instead.

*** WARNING: Do not use this PPA with the Precise 'X' backport stacks.  I.e., if
you install 12.04.2 (or later) directly.  You can switch back to a compatible
stack by installing 'xserver-forg-lts-precise' first.

See https://wiki.ubuntu.com/XorgOnTheEdge for a script (xorg-edgers-live-test)
that installs and runs the test packages in a live CD/media session, for quick &
easy temporary testing.

Currently supported Ubuntu releases are 12.04 (Precise), 12.10 (Quantal), and
13.04 (Raring).

To revert this PPA package installation back to the official packages, run:

    $ bash ./${APP_SCRIPT}.sh -p --purge

https://launchpad.net/~xorg-edgers/+archive/ppa
"

POST_INSTALL="
Next step:  Install one of the available drivers from the 'Additional Drivers'
tab of the 'Software & Updates' system settings dialog box.  (Access either from
the 'Settings...' menu, or by searching for 'Software & Updates'.)

*** WARNING: Do not use this PPA with the Precise 'X' backport stacks.  I.e., if
you install 12.04.2 (or later) directly.  You can switch back to a compatible
stack by installing 'xserver-forg-lts-precise' first.

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

SET_NAME="Xorg Edgers video drivers"
PACKAGE_SET="ppa-purge  "

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL="ppa:xorg-edgers/ppa"
REPO_GREP="xorg.*edgers.*ppa.*${DISTRO}"

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

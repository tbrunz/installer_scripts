#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'Y PPA Manager' for managing PPAs
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
'Y PPA Manager' is a tool from WebUpd8.org that lets you manage Launchpad PPAs:
Add, remove, purge PPAs, search for packages in Launchpad PPAs, as well as other
useful features:

    * List the packages available in a PPA added on your system;
    * Download packages from PPAs without adding them;
    * Backup / restore PPAs, along with all the PPAs' keys;
    * Update single repositories using a command line tool, 'update-ppa';
    * Remove duplicate PPAs;
    * Unity quicklists / optional AppIndicator;
    * Options that should help re-enable working PPAs when upgrading to a newer
      Ubuntu / Linux Mint version;
    * More...

Now, when you add a PPA using 'Y PPA Manager', it will be immediately updated
without updating all the other software sources, by using an included CLI tool,
'update-ppa'.  Usage example: 'sudo update-ppa ppa:webupd8team/java'.

You can automatically enable working PPAs from previous Ubuntu releases after
upgrading to a new Ubuntu version.  Normally, all PPAs are disabled during an
upgrade.  The 'Re-enable working PPAs' feature checks to see if old PPAs have
been updated to work with your current Ubuntu version, and if they do work, it
re-enables them.

Alternatively, if you do a clean Ubuntu install, you can make a backup of the
PPAs you used in your previous Ubuntu installation using 'Y PPA Manager', then
restore the backup using 'Y PPA Manager' on the new Ubuntu and have it update
the release name in those PPAs that work with the newer Ubuntu.  (If a restored
PPA has packages for Ubuntu 12.04, it will be updated to use 'precise' in the
'.list' file instead of the name of the previous version).  To do this in
'Y PPA Manager', select 'Advanced > Update release name in working PPAs'.

Before performing any of the above tasks, make sure to make a backup using
'Y PPA Manager' (or back up manually).
"

SET_NAME="PPA Manager"
PACKAGE_SET="y-ppa-manager  ppa-purge  "

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL="ppa:webupd8team/y-ppa-manager"
REPO_GREP="webupd8team.*y-ppa-manager.*${DISTRO}"

PerformAppInstallation "$@"

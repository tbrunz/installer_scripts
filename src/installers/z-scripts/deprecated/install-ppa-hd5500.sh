#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the Intel HD5500 video driver from a PPA repository.
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
SET_NAME="Intel HD 5500 driver"

USAGE="
This package installs the latest driver for the Intel HD 5500 series chipset.

The Google Pixel (2015) laptop uses this chipset, which may have rendering
issues with the default driver, particularly regarding the mouse pointer,
when Ubuntu is built in a ChromeOS 'chroot' (using, e.g., 'crouton').

https://github.com/dnschneid/crouton/issues/1519
"

POST_INSTALL="
Note that in order for the new driver to take effect, you will need to
restart your 'chroot' after installation.
"

PACKAGE_SET="software-properties-common  python-software-properties
ppa-purge  "

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL="https://download.01.org/gfx/ubuntu/${MAJOR}.${MINOR}/main"
REPO_GREP=".*01.org/gfx.*${DISTRO}"

# Add the PPA's GPG keys so that 'apt-get' won't complain:
#
QualifySudo

for KEYNUM in ilg ilg-2 ilg-3 ilg-4
    do
    sudo wget --no-check-certificate \
    https://download.01.org/gfx/RPM-GPG-KEY-${KEYNUM} -O - | sudo apt-key add -
done

PerformAppInstallation "-r" "$@"

bash do-update-all.sh

InstallComplete

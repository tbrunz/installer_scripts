#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Fixup an '/etc/hosts-*' file
# ----------------------------------------------------------------------------
#

### Enhancement: Modify to allow installation of HOSTS
### in a Windows partition w/ '-w' switch

### Enhancement: Modify to perform 'hosts-home', etc. installation

HOSTS_WIN=HOSTS

REPLACE=true
unset ERRORS

#
# Get the name of this script (for 'usage')
#
SOURCE=${BASH_SOURCE}
while [ -h "${SOURCE}" ] ; do SOURCE="$(readlink "${SOURCE}")" ; done

THIS_SCRIPT=$( basename "${SOURCE}" .sh )
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

#
# Check to see if we operate in 'test mode'
#
unset TEST_MODE

if [[ "${1}" == "-t" || "${1}" == "--test" ]]; then

    TEST_MODE=test
    shift
fi

#
# Display the 'usage' prompt (-h)
#
if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then

    echo
    echo "usage: ${THIS_SCRIPT} [ -t ] [ -r ] [ <system> ] "
    echo
    echo "This script re-generates the '/etc/hosts*' files from a (modified) "
    echo "'/etc/hosts-<system>' file. "
    echo
    echo "Options: "
    echo "    -t  --test    = Run in test mode; show what is being applied "
    echo "    -r  --report  = Report the internal date in the 'hosts.zip' file "
    echo
    echo "If <system> is not specified, it defaults to 'home'. "
    echo
    echo "Note that this script can be run repeatedly with no side-effects. "
    echo

    exit 1
fi

#
# Report the version of the 'hosts.zip' file (-r)
#
if [[ "${1}" == "-r" || "${1}" == "--report" ]]; then

    unset REPLACE
    shift
fi

if [[ -n "${TEST_MODE}" ]]; then

    echo -n "Test mode: "

    if [[ -n "${REPLACE}" ]]; then

        echo -n "Enabled "
    else
        echo -n "Disabled "
    fi

    echo "replacement of existing hosts files... "
fi

#
# Respond to a version query (-v)
#
if [[ "${1}" == "-v" || "${1}" == "--version" ]]; then

    echo "${THIS_SCRIPT}.sh, v${VERSION} "
    exit 2
fi

#
# Any other switch is an error...
#
if [[ $(echo "${1}" | cut -c 1) == "-" ]]; then

    echo "${THIS_SCRIPT}: Unknown switch '${1}' "
    exit 4
fi

#
# Verify that 'fromdos' has been installed, or install it if need be:
#
if [[ -n "${REPLACE}" && ! $( which fromdos ) ]]; then

    sudo apt-get install -y tofrodos

    if [[ ! $( which fromdos ) ]]; then

        echo "${THIS_SCRIPT}: unable to install 'tofrodos' ! "
        ERRORS=true
    fi

elif [[ -n "${TEST_MODE}" ]]; then

    echo "Test mode: Found '$( which fromdos )'... "
fi

#
# The argument must be the suffix applied to the 'hosts' file
# that specifies the local hosts on this machine's LAN.
#
if [[ -n "${REPLACE}" ]]; then

    if [[ -z "${1}" ]]; then

        SYSTEM=base
    else
        SYSTEM=${1}
    fi

    HOSTS_BASE=hosts-${SYSTEM}
    HOSTS_BLOCKING=hosts-blocking

    #
    # Verify that '/etc/hosts-<system>' file exists...
    #
    if [[ ! -f "/etc/${HOSTS_BASE}" ]]; then

        ls -lF /etc/hosts /etc/hosts-*
        echo
        echo "${THIS_SCRIPT}: Can't find '/etc/${HOSTS_BASE}'! "
        echo
        ERRORS=true

    elif [[ -n "${TEST_MODE}" ]]; then

        echo "Test mode: Found '/etc/${HOSTS_BASE}'... "
    fi
fi

#
# If we encountered any errors, bail out now...
#
[[ ${ERRORS} ]] && exit 8

#
# Verify that '/etc/hosts-<date>' file exists...
#
HOSTS_DATED=$( ls -1 /etc/hosts-2* 2>/dev/null )

if [[ -n "${HOSTS_DATED}" ]]; then

    HOSTS_DATED=$( basename "${HOSTS_DATED}" )

    if [[ ! -r "/etc/${HOSTS_DATED}" ]]; then

        ls -lF /etc/hosts /etc/hosts-*
        echo
        echo "${THIS_SCRIPT}: Can't read '/etc/hosts-2*' ! "
        echo
        ERRORS=true

    elif [[ -n "${TEST_MODE}" ]]; then

        echo "Test mode: Found '/etc/${HOSTS_DATED}'... "
    fi
else
    ls -lF /etc/hosts /etc/hosts-*
    echo
    echo "${THIS_SCRIPT}: Can't find '/etc/hosts-2*' ! "
    echo
    ERRORS=true
fi

#
# If we encountered any errors, bail out now...
#
[[ ${ERRORS} ]] && exit 8

#
# Simple test to see if 'sudo' has already been obtained
#
sudo ls /root > /dev/null 2>&1

if (( $? != 0 )); then

    echo -n "${THIS_SCRIPT}: Cannot run this script "
    echo    "without 'sudo' privileges. "
    exit 16
fi

#
# Install us into the '/etc' directory (for future mods), if necessary
#
if [[ $( pwd ) != "/etc" && $( dirname "${SOURCE}" ) != "/etc" ]]; then

    sudo cp -f "${SOURCE}" /etc/
fi

#
# Remove the old HOSTS blocking file (okay if it's not there):
#
cd /etc
sudo rm -f "${HOSTS_BLOCKING}"
sudo rm -f /tmp/hosts

#
# Filter out any 'localhost' line items in the hosts-dated file:
#
sed -i -r -e '/^127.*localhost/d' "${HOSTS_DATED}"
sed -i -r -e '/^::.*localhost/d'  "${HOSTS_DATED}"

#
# Create the new 'hosts' file by concatenating the local hosts file
# to the blocking file:
#
cat "${HOSTS_BASE}" "${HOSTS_DATED}" > /tmp/hosts
sudo mv /tmp/hosts ./

#
# Copy the resulting new 'hosts' file to replace the blocking file
# (now customized):
#
sudo chown root.root hosts*
sudo chmod 644 hosts*

sudo chmod 755 hosts*.sh
sudo cp -fp hosts "${HOSTS_BLOCKING}"

#
# Show the results to the user:
#
ls -lF /etc/hosts /etc/hosts-*

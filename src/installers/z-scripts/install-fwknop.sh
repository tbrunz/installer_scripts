#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Firewall Knock Operator (client and/or server)
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

echo "
    This script should work for 14.04, but has not been vetted, revised,
    or tested for 15.04 and later; these distros use 'systemd' -- and this
    script expects and references 'upstart' services instead.
    "
exit 1

##############################################################################
#
FWKNOP_URL="http://www.cipherdyne.org/"
BLOG_URL=${FWKNOP_URL}"blog/2012/09/"
SPA_URL=${BLOG_URL}"single-packet-authorization-the-fwknop-approach.html"

TUTORIAL_URL=${FWKNOP_URL}"fwknop/docs/fwknop-tutorial.html"

SET_NAME="fwknop"
APP_NAME="fwknop"
SERVICE="fwknop"

CONFIG_OPTIONS="--prefix=/usr --sysconfdir=/etc"

FWKNOP_CONFIG_DIR=/etc/fwknop
FWKNOP_CONFIG_FILE=fwknopd.conf
FWKNOP_ACCESS_FILE=access.conf
FWKNOP_RESOURCE_FILE=.fwknoprc

INSTALL_SSH=true
SSH_CONFIG_DIR=/etc/ssh
SSH_CONFIG_FILE=sshd_config
SSH_PORT=62202

##############################################################################
#
USAGE="
FWKNOP implements enhanced security for accessing a host over a network.  The
name is an acronym for 'FireWall KNock OPerator'.  FWKNOP implements a network
port authorization scheme called Single Packet Authorization (SPA) that uses a
default-drop packet filter & 'libpcap'.

SPA is essentially next-generation 'port knocking'.  The concept is simple and
elegant: The system closes a set of ports that need protection, keeping open
one stealthed 'listen-only' port to accept SPA 'knock' packets.  Upon receiving
and decrypting a knock packet (which includes authentication credentials in the
form of a password or PKI key), the 'fwknop' server opens the firewall for one
or more port/protocol combinations for exclusive access from the requester's IP.
After a pre-set amount of time, the firewall is closed again.  (Any open network
sessions remain unaffected.)

FWKNOP supports 'iptables' on Linux/Unix, 'ipfw' on FreeBSD & Mac OS X, and 'PF'
on OpenBSD.  The design decisions that guide the development of 'fwknop' can be
found in the blog post 'Single Packet Authorization: The fwknop Approach':
${SPA_URL}

Note: This package installs the latest version of the client-side and/or the
server-side software; the server component is needed on machines that will be
providing remote access.  Any machine that only needs to gain access to a server
only needs to install the client component of this package.  Both packages may
be installed on the same machine simultaneously, providing both functions.

Note that this package compiles and installs the latest version obtained from
the cipherdyne website, currently v2.6; this may present issues when connecting
to or from an earlier version (for example, the repo version for 'Saucy', 13.10,
is v2.0.4.)  Refer to the tutorial on strategies for handling legacy versions
for cases where upgrading cannot be performed.

${TUTORIAL_URL}
"

##############################################################################
#
SERVER_MESSAGE="
FWKNOP should be configured for operation, and the service started.
You may wish to edit the following files to further edit/add configurations:

    ${FWKNOP_CONFIG_DIR}/${FWKNOP_CONFIG_FILE}
    ${FWKNOP_CONFIG_DIR}/${FWKNOP_ACCESS_FILE}

If you change either of these files, you will need to run

    sudo service ${SERVICE} restart

to have the changes take effect (or you can reboot the machine).


GUFW (Graphical Ubuntu Firewall configuration tool) has been installed, which
provides an easy way to add & change firewall rules.  Run 'gufw', enable the
firewall and set all inputs and outputs allowed, then add this rule:

    simple deny in tcp ${SSH_PORT}

which will block any incoming attempts to connect to your SSH server.  (You may
wish to add other rules to provide internet access to your machine; do that at
this point as well.  Access to these ports can also be controlled using FWKNOP.)


Finally, edit your router's NAT table to forward a (high) port to 62201 and
forward a second corresponding port to ${SSH_PORT} on your machine.  FWKNOP
clients will send their SPA packets to the 62201-mapped port, and connect with
SSH to the ${SSH_PORT}-mapped port using a corresponding command such as

    ssh -p <${SSH_PORT}-mapped port number> user@host
"

##############################################################################
#
SSH_MESSAGE="

If you install SSH (server), you will want to edit '/etc/ssh/sshd_config'
to add 'Port ${SSH_PORT}' (at the top), after which you will need to run

    sudo service ssh restart

to have the changes take effect (or you can reboot the machine).
"

##############################################################################
#
CLIENT_MESSAGE="
FWKNOP client has been installed.

Each user may wish to edit the following file:

    /home/[user]/${FWKNOP_RESOURCE_FILE}

in their account to configure default SPA parameters, and, optionally, to
configure stanzas for SPAs involving particular hosts or situations.

This file can be created automatically by entering 'fwknop' in a terminal.
(Refer to the fwknop man page for details about this file format.)

Also note that this script configures the server so that the '-R' switch will
be required as a client option in order for the SPA packet to be accepted.
"

##############################################################################
#
POST_INSTALL=${SERVER_MESSAGE}${SSH_MESSAGE}${CLIENT_MESSAGE}

##############################################################################
##############################################################################
#
# Attempt to match a string to a line in a file (ignoring space characters)
#
# $1 = String to find
# $2 = String to insert
# $3 = File to search
#
Add_Line_to_File() {

local MATCH
local FOUND

local STRING_WORDS=()
local FILE_LINES=()

# Make a temp file to transcribe into:
#
maketmp -f

# Break up the trigger string into 'words' to search for:
#
read -r -a STRING_WORDS < <( printf %s "${1}" )

# Read in the file as an array of lines:
#
readarray FILE_LINES < "${3}"

# Copy each line, and when the trigger is found, insert the new string:
#
FOUND=1
for FILE_LINE in "${FILE_LINES[@]}"; do

    # Write the line to the temp file -- whether it matches or not:
    #
    printf "%s" "${FILE_LINE}" >> ${TMP_PATH}

    # If we've already matched the trigger string before, don't try again:
    #
    (( FOUND == 0 )) && continue

    # If we've yet to find the trigger, check this line for it;
    # As before, deconstruct the file line into its words:
    #
    LINE_WORDS=()
    read -r -a LINE_WORDS < <( printf %s "${FILE_LINE}" )

    # Match word for word until a discrepancy -- or "end of string":
    #
    MATCH=1
    for (( IDX=0; 1 == 1; IDX++ )); do

        # If either string has run out of words, we're done:
        #
        [[ -z "${LINE_WORDS[$IDX]}" || -z "${STRING_WORDS[$IDX]}" ]] && break

        # Otherwise, if we're here, we're at least partially matched;
        # Assume from this point on that we're going to match:
        #
        MATCH=0
        [[ ${LINE_WORDS[$IDX]} == "${STRING_WORDS[$IDX]}" ]] && continue

        # This is a direct conflict, so re-flag "no match" and quit checking:
        #
        MATCH=1
        break
    done

    # If we failed to match the trigger, then go to the next line:
    #
    (( MATCH != 0 )) && continue

    # We did match the trigger, so insert the new string and flag it done:
    #
    FOUND=0
    printf "%s\n" "${2}" >> ${TMP_PATH}
done

# Now move the transcribed version back to replace the original & delete temp:
#
copy ${TMP_PATH} "${3}"

sudo rm -f ${TMP_PATH}
}


##############################################################################
##############################################################################
#
# Just display the usage prompt?
#
[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

##############################################################################
#
# Verify that the install package tarball is present:
#
SOURCE_DIR="../${APP_NAME}"
SOURCE_GLOB="${APP_NAME}*.gz"

# On detecting the tarball, set FWKNOP_PKG_PATH to be the path to this file:
#
if [[ -n "${1}" ]]; then
    ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
    FWKNOP_PKG_PATH=${FILE_LIST}

    if [[ ! -e "${FWKNOP_PKG_PATH}" ]]; then
        ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
                "Could not find the '${APP_NAME}' package ! "
    fi
fi

##############################################################################
#
# Ask whether to install fwknop client, server, or both;
# Create MAKE_OPTIONS based on the user's choice.
#
OPTION_1="Both client and server"
OPTION_2="Client only"
OPTION_3="Server only"
OPTION_4="Cancel"

INSTALL_OPTIONS=(
    "${OPTION_1}"
    "${OPTION_2}"
    "${OPTION_3}"
    "${OPTION_4}"
)

# Create a query to ask the user for a choice:
#
echo
echo "Which elements of 'fwknop' would you like to install? "

select INSTALL_CHOICE in "${INSTALL_OPTIONS[@]}"; do

    [[ -n "${INSTALL_CHOICE}" ]] && break

    echo "Er, you gotta choose one that's listed, please... "
done

# Parse the choice and create options for 'configure':
#
case ${INSTALL_CHOICE} in
"${OPTION_1}")
    MAKE_OPTIONS=""
    ;;
"${OPTION_2}")
    MAKE_OPTIONS="--disable-server"
    ;;
"${OPTION_3}")
    MAKE_OPTIONS="--disable-client"
    ;;
*)
    exit
    ;;
esac

# Does the user wish to install the SSH server at the same time?
#
sudo ls "${SSH_CONFIG_DIR}/${SSH_CONFIG_FILE}" >/dev/null 2>&1

if (( $? > 0 )); then

    Get_YesNo_Defaulted "y" "Would you like to also install the SSH server?"

    (( $? > 0 )) && INSTALL_SSH=""
fi

##############################################################################
#
# We're 'go' for building & installing!
#
# First, install the dependency packages:
#
SET_NAME="FWKNOP Server"
PACKAGE_SET="build-essential  linux-headers-$( uname -r )
             libpcap-dev  texinfo  gufw  "

[[ -n "${INSTALL_SSH}" ]] && PACKAGE_SET="ssh  ${PACKAGE_SET}"

PerformAppInstallation "-r" "$@"

# Create a temporary directory we can use to do the build:
#
QualifySudo
maketmp -d
BUILD_PATH="${TMP_PATH}"
BUILD_DIR="${APP_NAME}*"

# Copy the builder tarball to the temp directory:
#
echo
copy ${FWKNOP_PKG_PATH} ${BUILD_PATH}

# Uncompress & expand the tarball package:
#
chgdir "${BUILD_PATH}"
tar_zip "gz" ${SOURCE_GLOB}

sudo chown -R "$( whoami )":"$( whoami )" *
chgdir ${BUILD_DIR}

##############################################################################
#
# If 'fwknopd.conf' & 'access.conf' exist, then rename them before we build
# and install the service.  (Note we cannot use 'test -f', etc. to verify
# they exist, since we cannot 'see' this file as our unprivileged self...)
#
sudo ls "${FWKNOP_CONFIG_DIR}/${FWKNOP_CONFIG_FILE}" >/dev/null 2>&1

(( $? == 0 )) && sudo mv "${FWKNOP_CONFIG_DIR}/${FWKNOP_CONFIG_FILE}" \
                         "${FWKNOP_CONFIG_DIR}/${FWKNOP_CONFIG_FILE}.bak"

sudo ls "${FWKNOP_CONFIG_DIR}/${FWKNOP_ACCESS_FILE}" >/dev/null 2>&1

(( $? == 0 )) && sudo mv "${FWKNOP_CONFIG_DIR}/${FWKNOP_ACCESS_FILE}" \
                         "${FWKNOP_CONFIG_DIR}/${FWKNOP_ACCESS_FILE}.bak"

##############################################################################
#
# Run the sequence of 'make' apps to build & install:
#
sudo service ${SERVICE} stop >/dev/null 2>&1

sudo sh ./configure ${CONFIG_OPTIONS} "${MAKE_OPTIONS}"
(( $? > 0 )) && \
        ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not configure '${APP_NAME}' for building ! "

sudo make
(( $? > 0 )) && \
        ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not build the '${APP_NAME}' application ! "

sudo make install
(( $? > 0 )) && \
        ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not install the '${APP_NAME}' application ! "

# We're done here if the user only wanted to install the client app...
#
if [[ ${INSTALL_CHOICE} == "${OPTION_2}" ]]; then

    cd /
    sudo rm -rf "${BUILD_PATH}"

    InstallComplete

    echo "${CLIENT_MESSAGE}"
    exit
fi

##############################################################################
#
# We installed the server; Copy the 'upstart' file and create an 'upstart-job':
#
copy extras/upstart/${APP_NAME}.conf /etc/init/${SERVICE}.conf

sudo ln -sf /lib/init/upstart-job /etc/init.d/${SERVICE}
(( $? > 0 )) && \
        ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not install the '${SERVICE}' service ! "

sudo update-rc.d -f ${SERVICE} remove >/dev/null 2>&1
sudo update-rc.d ${SERVICE} start 30 2 3 4 5 . stop 70 0 1 6 .
(( $? > 0 )) && \
        ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not create the '${SERVICE}' service ! "

sudo initctl reload-configuration
(( $? > 0 )) && \
        ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Failure attempting to reload the service configuration ! "

##############################################################################
#
# We must edit 'fwknopd.conf' & 'access.conf' before launching; Otherwise,
# the service will appear to start, but won't actually be running.
# (This is a bug in 'fwknopd' v2.5.)
#

# Start with 'fwknopd.conf' -- does it exist?  (Note we cannot use 'test -f',
# etc. to verify, since we cannot 'see' this file as our unprivileged self...)
#
sudo ls "${FWKNOP_CONFIG_DIR}/${FWKNOP_CONFIG_FILE}" >/dev/null 2>&1

(( $? > 0 )) && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot find '${FWKNOP_CONFIG_DIR}/${FWKNOP_CONFIG_FILE}' ! "

# Now the configuration...  We normally only need to set the sniffed interface:
#
echo
echo "Here are this machine's network interfaces: "
echo
ip addr

echo
Get_YesNo_Defaulted "y" "Use 'eth0' as the network interface to sniff?"

if (( $? > 0 )); then
    #
    # We're not to use 'eth0'...  What should we use?  Start a loop and
    # repeat asking until we get an interface we both can live with:
    #
    for (( YES_NO=1; YES_NO > 0; )); do

        read -e -r -p "Please enter the network interface to sniff: " PCAP_INTF

        # Reject a blank line; i.e., don't change YES_NO, then loop:
        #
        [[ -z "${PCAP_INTF}" ]] && continue

        # Examine what the user entered: Is it of the proper form? (ethX/wlanX)
        #
        printf %s "${PCAP_INTF}" | egrep -q '^(e|w).*[[:digit:]]+$'
        YES_NO=$?

        # If it fits the pattern, then it's probably good; accept it & continue.
        #
        (( YES_NO == 0 )) && break

        # Otherwise, get confirmation, and if it was a type, then loop:
        #
        Get_YesNo_Defaulted "n" \
"Er, '${PCAP_INTF}' doesn't look like it's a network interface... Keep anyway?"
        YES_NO=$?
    done

    # At this point we assume we have a valid interface to sniff -- Set it:
    #
    #PCAP_INTF                   eth0;
    #
    sudo sed -i -e "s|#PCAP_INTF|PCAP_INTF|" \
                -e "s|eth0;|${PCAP_INTF};|"  \
                        "${FWKNOP_CONFIG_DIR}/${FWKNOP_CONFIG_FILE}"
fi

##############################################################################
#
# Now configure 'access.conf' -- does it exist?
#
sudo ls "${FWKNOP_CONFIG_DIR}/${FWKNOP_ACCESS_FILE}" >/dev/null 2>&1

(( $? > 0 )) && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot find '${FWKNOP_CONFIG_DIR}/${FWKNOP_ACCESS_FILE}' ! "

# Add a line to force the use of '-R' by the client (for security):
#
sudo sed -r -i -e '\|^SOURCE[[:space:]]+ANY|{a \
REQUIRE_SOURCE_ADDRESS    Y
        }' "${FWKNOP_CONFIG_DIR}/${FWKNOP_ACCESS_FILE}"

# Ask for the password to make KEY_BASE64, then encode it BASE64:
#
read -e -r -p "Please enter the ${APP_NAME} passphrase: " CRYPTO_KEY

CRYPTO_KEY=$( printf %s "${CRYPTO_KEY}" | base64 )

# Edit the access file, but only change the first occurrence of the KEY
# placeholder; the second one must be left as-is for the HMAC key replacement:
#
sudo sed -i -e "0,\|__CHANGEME__|{s|__CHANGEME__|${CRYPTO_KEY}|}" \
                    "${FWKNOP_CONFIG_DIR}/${FWKNOP_ACCESS_FILE}"

# Ask for the password to make HMAC_KEY_BASE64, then encode it BASE64:
#
while (( 1 == 1 )); do

    read -e -r -p "Please enter the HMAC passphrase (not the same): " HMAC_KEY

    HMAC_KEY=$( printf %s "${HMAC_KEY}" | base64 )

    [[ ${HMAC_KEY} != ${CRYPTO_KEY} ]] && break

    ThrowError "${ERR_WARNING}" "${APP_SCRIPT}" \
        "Cannot re-use the ${APP_NAME} passphrase for the HMAC passphrase ! "
done

# Now edit the access file again, and change the second occurrence (only):
#
sudo sed -i -e "0,\|__CHANGEME__|{s|__CHANGEME__|${HMAC_KEY}|}" \
                    "${FWKNOP_CONFIG_DIR}/${FWKNOP_ACCESS_FILE}"

##############################################################################
#
# Start the new service, and verify that it's running:
#
sudo service ${SERVICE} start
(( $? > 0 )) && \
        ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not start the '${SERVICE}' service ! "

sleep 5

STATUS=$( sudo service ${SERVICE} status )
(( $? > 0 )) && \
        ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not get the status of the '${SERVICE}' service ! "

printf %s "${STATUS}" | egrep 'running.*[[:digit:]]+$' >/dev/null 2>&1
(( $? > 0 )) && \
        ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not confirm that '${SERVICE}' is running as a service ! "

##############################################################################
#
# If SSH is installed, edit '/etc/ssh/sshd_config' to add the stealthed port:
#
if [[ -n "${INSTALL_SSH}" ]]; then

    # The SSH config file exists... Does it already have Port SSH_PORT?
    #
    egrep -q "^Port[[:space:]]+${SSH_PORT}[[:space:]]*[#]*" \
                                "${SSH_CONFIG_DIR}/${SSH_CONFIG_FILE}"
    if (( $? > 0 )); then

        Add_Line_to_File "Port" "Port ${SSH_PORT}" \
                                "${SSH_CONFIG_DIR}/${SSH_CONFIG_FILE}"

        # Restart the SSH service in order for our change to take effect:
        #
        sudo service ssh restart
    fi
fi

##############################################################################
#
# Now we're done; Remove the build directory, the tell the user:
#
cd /
sudo rm -rf "${BUILD_PATH}"

InstallComplete

echo "${SERVER_MESSAGE}"

if [[ -z "${INSTALL_SSH}" || ${INSTALL_CHOICE} == "${OPTION_1}" ]]; then

    InstallComplete "-p"
fi

[[ -z "${INSTALL_SSH}" ]] && echo "${SSH_MESSAGE}"

[[ ${INSTALL_CHOICE} == "${OPTION_1}" ]] && echo "${CLIENT_MESSAGE}"

exit

##############################################################################




##############################################################################
#

# Line 472: Fix the dependency on having "Port 22" in the 'sshd_config' file

# ?? add line 'sudo chmod 755 ${FWKNOP_CONFIG_DIR}' to provide user access

# Create a template FWKNOP_RESOURCE_FILE, '/etc/fwknop/fwknoprc' (chmod 644)
# Set up the default stanza for connecting to the server via NAT;
# Ask for the FW_ACCESS_TIMEOUT period & set this parameter;

# Also put a script in '/usr/bin' that will display/edit '~/.fwknoprc',
# and set the KEY values (new passphrase or imported BASE64) + FW_TIMEOUT

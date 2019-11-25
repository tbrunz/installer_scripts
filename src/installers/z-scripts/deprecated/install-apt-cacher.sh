#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'apt-cacher-ng' from the repository
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

############################################################################
#
MY_APT_SERVER=apt-cache-server
PROXY_PORT=3142

APT_CONF_DIR=/etc/apt/apt.conf.d
APT_PROXY_FILE=02proxy

SET_PROXY_SCRIPT_DIR=/etc/NetworkManager/dispatcher.d
SET_PROXY_SCRIPT=99setproxy

RESOLV_CONF_FILE=/run/resolvconf/resolv.conf

############################################################################
#
USAGE="
This package installs Apt-Cacher NG, a caching proxy for software packages that
are downloaded by Unix/Linux system distribution mechanisms from mirror servers
accessible via HTTP.

Apt-Cacher NG attempts to achieve the same goals as related proxies: It acts as
a proxy which is used by clients in the local network to share the data that has
been downloaded.  It monitors the state of packages and is capable of merging
downloads of the same packages from different locations (real or simulated).

Development goals include:

  * Lightweight implementation - Allow use on systems with low resources.
  * Internal (native) threading - Avoiding process forking wherever possible,
    avoiding kludges for pseudo-thread synchronization, avoiding relying on
    special file system features for internal operations where possible.
  * Real (effective) support of HTTP pipelining, using an internal client with
    native stream control.
  * Reliable but efficient content merging in the local package pool, avoiding
    delivery of wrong data.
  * Explicit tracking of dynamically changed and unchanged files.
  * Supports use in non-Debian environments.

Note that since Debian and Ubuntu have identically named (but different) '.deb'
packages in their repositories, it is unwise to setup a single apt-cacher to be
a caching package server for both Debian and Ubuntu clients at the same time.
A workaround is to run two separate instances of 'apt-cacher' on two separate
ports with two separate caches.

http://www.unix-ag.uni-kl.de/~bloch/acng/
https://help.ubuntu.com/community/Apt-Cacher-Server
"

############################################################################
#
SELECTED_HOST="<your apt-cacher server>"

POST_INSTALL="
Test 'apt-cacher' by pointing your web browser to

    http://${SELECTED_HOST}:${PROXY_PORT}

You should get a page describing how to configure 'apt-cacher' if it's running.

NOTE: As the server will be caching all the downloaded packages, you may find it
      necessary to increase the size of the '/' (root) partition by several GB.
"

############################################################################
#
SET_NAME="APT Cacher"
PACKAGE_SET="apt-cacher-ng  "

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

# We'll need the directory in which to write the 'setproxy' script
# that will automatically control redirecting APT to the proxy server:
#
[[ -d "${SET_PROXY_SCRIPT_DIR}" ]] || sudo mkdir -p "${SET_PROXY_SCRIPT_DIR}"


############################################################################
############################################################################
#
# Return a host's collection of assigned IP numbers
#
# Input:   This hosts's networking configuration
# Globals: $MY_IP_NUMS[] and $MY_NETWRKS[]
#
# For each found ipv4, extract the IP number and the associated network.
#
Get_My_IPs_and_Nets() {

local IP_NUMBER
local NETWORK

MY_IP_NUMS=( )
MY_NETWRKS=( )

# Pipe the output of 'ip addr' into the 'while' loop's 'read' function:
#
while read -r _ IP_NUMBER _; do
    #
    # Parsing a line starting with 'inet' will grep to an IP number;
    # Otherwise, the resulting grep will be a null string:
    #
    IP_NUMBER=$( egrep -o ${IP_CIDR_GREP} < <( echo "${IP_NUMBER}" ) )

    [[ -z "${IP_NUMBER}" ]] && continue

    # 'ip addr' returns "inet WWW.XXX.YYY.ZZZ/NN", so we need to
    # separate the CIDR spec into IP number and the domain class size;
    # Then, using the domain size, compute a network string;
    #
    # (This really needs to be a function call that handles odd sizes!)
    #
    case ${IP_NUMBER#*/} in
    8)
        NETWORK=$( egrep -o ^${IP_CLASS_A_GREP} < <( echo "${IP_NUMBER}" ) )
        [[ ${NETWORK} == "127." ]] && continue
        [[ -n "${NETWORK}" ]] && MY_NETWRKS+=( ${NETWORK} )
        ;;
    16)
        NETWORK=$( egrep -o ^${IP_CLASS_B_GREP} < <( echo "${IP_NUMBER}" ) )
        [[ -n "${NETWORK}" ]] && MY_NETWRKS+=( ${NETWORK} )
        ;;
    24)
        NETWORK=$( egrep -o ^${IP_CLASS_C_GREP} < <( echo "${IP_NUMBER}" ) )
        [[ -n "${NETWORK}" ]] && MY_NETWRKS+=( ${NETWORK} )
        ;;
    *)

        ;;
    esac

    # Save the IP portion of the CIDR spec:
    #
    MY_IP_NUMS+=( ${IP_NUMBER%/*} )

done < <( ip addr )
}


############################################################################
#
# Return a host's collection of hostnames, and the names of its peers
#
# Inputs:  None
# Depends: $MY_IP_NUMS[], $MY_NETWRKS[], and ${HOSTS_TABLE}
# Globals: $MY_HOSTNAMES[] and $MY_PEERNAMES[]
#
# Search the 'hosts' file for all hostnames bound to these IPs/nets
#
Get_My_Hostnames_and_Peers() {

local IP_NUMBER
local HOST_LINE

local MY_IP
local MY_NET

local THIS_HOSTNAME
local THIS_NETWORK

MY_HOSTNAMES=( )
MY_PEERNAMES=( )

# Pipe the 'hosts' file into the 'while' loop's 'read' function:
#
Load_Hosts_File

while read -r IP_NUMBER HOST_LINE; do
    #
    # Attempt to match each line in 'hosts' with one of my IP numbers:
    #
    for MY_IP in "${MY_IP_NUMS[@]}"; do
        #
        # If the IP number matches, clip off any '#' + following text:
        #
        if [[ ${IP_NUMBER} == "${MY_IP}" ]]; then
            #
            # Then step through all the hostnames the rest might contain...
            #
            for THIS_HOSTNAME in ${HOST_LINE%%#*}; do

                MY_HOSTNAMES+=( ${THIS_HOSTNAME} )
            done
        fi
    done

    # Attempt to match each line in 'hosts' with one of my networks:
    #
    for MY_NET in "${MY_NETWRKS[@]}"; do
        #
        # If the network matches, clip off any '#' + following text:
        #
        THIS_NETWORK=$( egrep ^${MY_NET} < <( echo "${IP_NUMBER}" ) )

        if [[ -n "${THIS_NETWORK}" ]]; then
            #
            # Then step through all the hostnames the rest might contain...
            #
            for THIS_HOSTNAME in ${HOST_LINE%%#*}; do

                MY_PEERNAMES+=( "${IP_NUMBER} - ${THIS_HOSTNAME}" )
            done
        fi
    done

done < <( echo "${HOSTS_TABLE}" )
}


############################################################################
#
# Is this one of my hostname aliases?
#
# Inputs:  $1 = Candidate hostname
# Depends: $MY_HOSTNAMES[]
# Output:  Console messages
#
Is_This_My_Hostname() {

local MY_NAME

# Check the list of this system's hostnames against ${1}
#
for MY_NAME in "${MY_HOSTNAMES[@]}"; do

    [[ ${MY_NAME} == "${1}" ]] && return
done

return 1
}


############################################################################
#
# Request a host from the user - Can be a hostname or IP number
#
# Inputs: None
# Output: Console messages
# Globals: ${RESPONSE}
#
Request_Host_from_User() {

local SELECTION

# Add an option for the user to give us a hostname, then present a menu:
#
MY_PEERNAMES+=( "localhost" )
MY_PEERNAMES+=( "Other..." )
echo
echo "Please select one of the following for the proxy server: "

# This menu shows all of this hosts "<IP number> - <hostname>" choices:
#
select SELECTION in "${MY_PEERNAMES[@]}"; do

    [[ -n "${SELECTION}" ]] && break

    echo "Just pick one of the listed options, okay? "
done

# Now decide what to do with the response; 'other' will require more input;
# Treat a <Ctrl-D> as though 'other' were selected:
#
case ${SELECTION} in

"localhost")
    #
    # This machine is the APT proxy server:
    #
    RESPONSE=localhost
    ;;

"" | "Other...")
    #
    # Ask the user to tell us which host the APT proxy server is:
    #
    for (( YES_NO=1; YES_NO > 0; )); do

        read -rep "Please enter a hostname or IP number: " SELECTION

        # If a blank line is returned, go around the block & do it again:
        #
        [[ -z "${SELECTION}" ]] && continue

        # In case more than one word is provided, "let's do it again":
        #
        read -r RESPONSE _ < <( echo "${SELECTION}" )

        [[ ${RESPONSE} != "${SELECTION}" ]] && continue
        break
    done
    ;;

*)
    #
    # Otherwise, it's a pre-formed "<IP number> - <hostname>" choice:
    #
    read -r _ _ RESPONSE < <( echo "${SELECTION}" )
    ;;
esac
}


############################################################################
############################################################################
#
# We need to determine whether or not this system is the proxy host;
#
# If so, we install the package and set the script to reference 'localhost';
#
# If not, we skip the package install and set the host accordinging to
# either the 'hosts' table (if possible) or by asking the user...
#
QualifySudo

Get_My_IPs_and_Nets

Get_My_Hostnames_and_Peers

# This machine's network domain should be the "search" parameter listed
# in the 'resolv.conf' file; This should exist... but it might not:
#
MY_DOMAIN=$( grep search "${RESOLV_CONF_FILE}" | awk '{ print $2 }' )

# Make a prompt for the user to decide for/against using our default hostname:
#
Is_This_My_Hostname "${MY_APT_SERVER}"

if (( $? == 0 )); then
    SERVER_PROMPT="This host is '${MY_APT_SERVER}'; is this the proxy server?"
else
    SERVER_PROMPT="Do you wish to set the proxy server to '${MY_APT_SERVER}'?"
fi

# We need to ask if the default hostname is the correct one to use:
#
Get_YesNo_Defaulted "y" "${SERVER_PROMPT}"

if (( $? == 0 )); then
    #
    # The user has accepted our suggested hostname:
    #
    RESPONSE=${MY_APT_SERVER}
else
    # The user answered 'no', so we'll need to ask for a name or IP number:
    #
    Request_Host_from_User
fi

# Did we get a hostname or an IP number?  Create one from the other:
#
SELECTED_IP=$( egrep -o ${IP_ADDR_GREP} < <( echo "${RESPONSE}" ) )

if [[ -z "${SELECTED_IP}" ]]; then
    #
    # It's a name, not an IP; lookup the (one) IP number that corresponds...
    # If it doesn't resolve, then use the hostname as the IP; this may be
    # because the host isn't setup or not listed in 'hosts', or because
    # the host is not on this network, or it's a typo...
    #
    Local_Hostname_to_IP "${RESPONSE}"

    SELECTED_HOST=${RESPONSE}
    SELECTED_IP=${SELECTED_HOST}
    [[ -n "${IP_NUMBER}" ]] && SELECTED_IP=${IP_NUMBER}
else
    # We were given a valid IP number, so lookup a hostname that corresponds...
    # If it doesn't resolve, then use the IP as the hostname; this may be
    # because the IP is good yet not listed in 'hosts', or because the user
    # has given us an IP not on this network, or it's a typo...
    #
    Local_IP_to_Hostname "${SELECTED_IP}"

    SELECTED_HOST=${SELECTED_IP}
    [[ -n "${HOST_NAME}" ]] && SELECTED_HOST=${HOST_NAME}
fi

# Did we draw a blank?  Otherwise, assume what we have is a 'good' name/IP...
#
[[ -z "${SELECTED_HOST}" || -z "${SELECTED_IP}" ]] && \
        ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
            "Could not determine a name or IP for the proxy server !"

# Is this host to be the proxy server?  ( 0 == YES )
#
Is_This_My_Hostname "${SELECTED_HOST}"
IM_THE_SERVER=$?

# Now that we have a proxy server, do a ping test as a perk for the user...
# But don't waste time with a needless activity if THIS host is the server!
#
if (( IM_THE_SERVER != 0 )); then

    # We prefer an IP number for the ping test, rather than using a hostname;
    # It's possible a hostname would result in outsourcing its DNS resolution:
    #
    if [[ ${SELECTED_HOST} == "${SELECTED_IP}" ]]; then

        PING_TEXT="'${SELECTED_HOST}'"
    else
        PING_TEXT="'${SELECTED_HOST}' (${SELECTED_IP})"
    fi

    echo
    ping -q -c 1 -W 1 ${SELECTED_IP} 1>/dev/null 2>&1

    if (( $? == 0 )); then
        echo "I can ping ${PING_TEXT} on the network... "
    else
        echo "I can't ping ${PING_TEXT} on the network ! "
    fi

    read -r -s -n 1 -p "Press <Ctrl-C> to quit, any other key to continue... "
    echo
fi

# Tell the user what this host's network domain is, then ask if it's the 'home'
# domain; if not, ask what the home domain is, then set in the proxy script:
#
echo
if [[ -n "${MY_DOMAIN}" ]]; then

    echo "This machine is in the '${MY_DOMAIN}' network domain... "

    if (( IM_THE_SERVER != 0 )); then

        # "Forget" the domain name we just determined if the user denies it:
        #
        Get_YesNo_Defaulted "y" "Is this the 'home' domain?"
        (( $? > 0 )) && MY_DOMAIN=""
    else
        echo
        sleep 2
    fi
else
    echo "I can't determine the network domain for this machine... "
fi

# We're either using the domain name we discovered... Or we have nothing;
# If we have nothing (an empty string), then we must ask the user to tell us:
#
if [[ -z "${MY_DOMAIN}" ]]; then
    #
    # Ask the user to tell us what the home domain is:
    #
    echo
    for (( YES_NO=1; YES_NO > 0; )); do

        read -rep "What is the network domain for the APT server? " SELECTION

        # If a blank line is returned, go around the block & do it again:
        #
        [[ -z "${SELECTION}" ]] && continue

        # In case more than one word is provided, "let's do it again":
        #
        read -r MY_DOMAIN _ < <( echo "${SELECTION}" )

        [[ ${MY_DOMAIN} != "${SELECTION}" ]] && continue
        break
    done
fi

# Now we have enough information to create a script that will be executed
# each time the network interface comes 'up' (on bootup or network change);
#
# Create the script file as a 'temp' file, since we'll have to edit it:
#
maketmp -f

cat >"${TMP_PATH}" << 'EOF_SET_PROXY'
#! /usr/bin/env bash
#
# Set the APT proxy when on a 'home' network, and disable it when roaming
#
APT_SERVER=%APT_SERVER%
PROXY_PORT=%PROXY_PORT%

MY_DOMAIN=%MY_DOMAIN%
RESOLV_CONF_FILE=%RESOLV_CONF_FILE%

APT_CONF_DIR=%APT_CONF_DIR%
APT_PROXY_FILE=%APT_PROXY_FILE%

# Grab the 'search' domain found in the 'resolv.conf' file:
#
THIS_DOMAIN=$( grep search "${RESOLV_CONF_FILE}" | awk '{ print $2 }' )

# ...and compare it to our 'home' domain:
#
if [[ ${THIS_DOMAIN} == "${MY_DOMAIN}" ]]; then

    # We're at home... Create the APT proxy file:
    #
    printf %s \
        "Acquire::http { Proxy \"http://${APT_SERVER}:${PROXY_PORT}\"; };" \
        > ${APT_CONF_DIR}/${APT_PROXY_FILE}
else
    # We're "on the road"... Is there an APT proxy file?
    #
    if [[ -f "${APT_CONF_DIR}/${APT_PROXY_FILE}" ]]; then

        # Delete the APT proxy file:
        #
        rm -rf "${APT_CONF_DIR}/${APT_PROXY_FILE}"
    fi
fi
EOF_SET_PROXY

# If this host is the server, then change the hostname to 'localhost':
#
(( IM_THE_SERVER == 0 )) && SELECTED_HOST="localhost"

# Now edit the file to set its 'constant' parameter variables per this script:
#
sed -ri \
    -e "s|%APT_SERVER%|${SELECTED_HOST}|" \
    -e "s|%PROXY_PORT%|${PROXY_PORT}|" \
    -e "s|%MY_DOMAIN%|${MY_DOMAIN}|" \
    -e "s|%RESOLV_CONF_FILE%|${RESOLV_CONF_FILE}|" \
    -e "s|%APT_CONF_DIR%|${APT_CONF_DIR}|" \
    -e "s|%APT_PROXY_FILE%|${APT_PROXY_FILE}|" \
    "${TMP_PATH}"

# And finally copy the script into place, then discard the template in 'tmp':
#
copy "${TMP_PATH}" "${SET_PROXY_SCRIPT_DIR}/${SET_PROXY_SCRIPT}"
SetDirPerms         "${SET_PROXY_SCRIPT_DIR}/${SET_PROXY_SCRIPT}"
rm "${TMP_PATH}"

# If this host is the proxy server, then we need to install the software!
#
(( IM_THE_SERVER == 0 )) && PerformAppInstallation "-r" "$@"

# Call the above-edited script, as it's what sets the APT proxy file:
#
sudo bash "${SET_PROXY_SCRIPT_DIR}/${SET_PROXY_SCRIPT}"

InstallComplete

############################################################################
############################################################################

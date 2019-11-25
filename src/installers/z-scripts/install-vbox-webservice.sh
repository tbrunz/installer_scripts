#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Configure & start VirtualBox Webservices
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
VBOX_DEFAULTS_DIR=/etc/default
VBOX_DEFAULTS_FULLPATH=${VBOX_DEFAULTS_DIR}/virtualbox

VBOX_WEBSRVCS_HDR="VirtualBox WebServices"
VBOX_TIMEOUT=30
VBOX_LOGFILE_FULLPATH=/var/log/vboxwebservice.log

SERVICE_FILE_DIR=/etc/init.d
VBOX_WEB_SERVICE=vboxweb-service

# System group required for users to have vbox privileges:
#
VBOX_GROUP=vboxusers
VBOX_USER="the chosen account"

############################################################################
#
USAGE="
VirtualBox provides a web services API that allows remote clients to connect
to the VBox Manager application and control not only the guest VMs, but also
to control the configuration and operation of VirtualBox itself.

This script sets up the VBox Webservices (which presumes that VirtualBox has
already been installed), and then starts the service.  On subsequent reboots,
the service will be automatically started.

Access to VirtualBox via this API is achieved by logging in as the local user
designated to own the service.  As a consequence, only VMs owned by that user
can be controlled via Web Services.  To change the user, simply re-run this
script.

Once the service has been installed, the 'vboxweb-service' service script can
be used to turn access on and off.
"

POST_INSTALL="
    Note that only the virtual machines owned by '${VBOX_USER}' can
    be controlled remotely via the VirtualBox web service.
"

############################################################################
#
SET_NAME="VBox Webservices"
PACKAGE_SET=""

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"


############################################################################
############################################################################
#
# Return a host's collection of assigned IP numbers & network adapters
#
# For each found ipv4, extract the IP number and the associated adapter.
#
Get_My_IPs_and_NICs() {

local FIELD1
local FIELD2
local GREP_STRING
local THIS_ADAPTER

MY_IP_NUMS=( )

# Pipe the output of 'ip addr' into the 'while' loop's 'read' function:
#
while read -r FIELD1 FIELD2 _ ; do
    #
    # Parsing a line starting with "[digit]: [string]: " is the adapter ID:
    #
    GREP_STRING="[[:digit:]]+:[[:space:]]+en[[:alnum:]]+:"
    RESULT=$( printf "%s" "${FIELD1} ${FIELD2}" | egrep ${GREP_STRING} )

    if (( $? == 0 )); then
        #
        # Found an IP number; Clip off the ':' character at the end of the
        # adapter device name,then continue looping to get the IP number:
        #
        THIS_ADAPTER=${FIELD2%:}
        continue
    fi

    # Parsing a line starting with 'inet' will grep to an IP number:
    #
    RESULT=$( printf "%s" "${FIELD2}" | egrep -o ${IP_CIDR_GREP} )
    (( $? == 0 )) || continue

    # Reject the IP number if an adapter wasn't found:
    #
    [[ -n "${THIS_ADAPTER}" ]] || continue

    # Save just the IP portion of the CIDR spec;
    # Note that $IP_NUMBER is a global -- we use it to pass
    # the last valid IP number we found back to the caller;
    #
    IP_NUMBER=${FIELD2%/*}
    MY_IP_NUMS+=( "${THIS_ADAPTER} = ${IP_NUMBER}" )
    THIS_ADAPTER=""

done < <( ip addr )
}


############################################################################
#
# Request an IP from the user - Need to know which to use for the server
#
Request_IP_from_User() {

local SELECTION

# Present a menu made up of the IP numbers for this host:
#
echo
echo "Please select one of the following for the VBox Webservices IP number: "

# This menu shows all of this hosts "<NIC> - <IP number>" choices:
#
select SELECTION in "${MY_IP_NUMS[@]}"; do

    [[ -n "${SELECTION}" ]] && break

    echo "Just pick one of the listed options, okay? "
done

# Now decide what to do with the response; If <Ctrl-D>, ask for a number:
#
case ${SELECTION} in

"")
    #
    # Ask the user to tell us which IP to use for the server:
    #
    for (( YES_NO=1; YES_NO > 0; )); do

        read -rep "Please enter a hostname or IP number: " SELECTION

        # If a blank line is returned, go around the block & do it again:
        #
        [[ -z "${SELECTION}" ]] && continue

        # In case more than one word is provided, "let's do it again":
        #
        read -r RESPONSE _ < <( echo "${SELECTION}" )

        [[ "${RESPONSE}" != "${SELECTION}" ]] && continue
        break
    done
    ;;

*)
    #
    # Parse the pre-formed "<NIC> - <IP number>" choice to get the IP number:
    #
    read -r _ _ RESPONSE < <( echo "${SELECTION}" )
    ;;
esac
}


############################################################################
#
# Get the list of VirtualBox users on this host
#
Get_VBox_Users() {

local VBOX_USER_LIST

VBOX_USER_LIST=$( getent group ${VBOX_GROUP} | cut -d ":" -f 4 | tr "," " " )

[[ -z "${VBOX_USER_LIST}" ]] && ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
        "Cannot find any VirtualBox users! (Is VBox installed?) "

# Do NOT quote the variable reference in the following line!
VBOX_USERS=( ${VBOX_USER_LIST} )
}


############################################################################
############################################################################
#
# Get a list of the VirtualBox users on the system:
#
QualifySudo
Get_VBox_Users

# Get a list of this host's network adapters & IP numbers, then
# find out which of my IP numbers to use for the VBox Webservices IP:
#
Get_My_IPs_and_NICs

if (( ${#MY_IP_NUMS[@]} > 1 ));
then
    Request_IP_from_User
    VBOX_SERVER_HOST=${RESPONSE}
else
    VBOX_SERVER_HOST=${IP_NUMBER}
    echo
    echo "Using IP '${VBOX_SERVER_HOST}' for the VBox Webservice... "
fi

# Find out which user account is to 'own' the VBox Webservice:
#
if (( ${#VBOX_USERS[@]} > 1 )); then
    #
    # Present a menu made of the users on this host:
    #
    echo
    echo "Please select a user who will own the VBox Webservice: "

    select SELECTION in "${VBOX_USERS[@]}"; do

        [[ -n "${SELECTION}" ]] && break

        echo "Just pick someone, okay? "
    done

    # Now decide what to do with the response; If <Ctrl-D>, bail out:
    #
    case ${SELECTION} in
    "")
        ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
                "Cannot proceed without a VirtualBox user !"
        ;;
    *)
        VBOX_USER=${SELECTION}
        ;;
    esac
else
    VBOX_USER=${VBOX_USERS}
    echo "User '${VBOX_USER}' will own the VBox Webservice... "
fi

# Create the VirtualBox WebServices section of the VBox defaults file:
#
maketmp

cat > ${TMP_PATH} << __VBOX_DEFAULTS_EOF
# ${VBOX_WEBSRVCS_HDR}
VBOXWEB_USER="${VBOX_USER}"
VBOXWEB_TIMEOUT=${VBOX_TIMEOUT}
VBOXWEB_LOGFILE="${VBOX_LOGFILE_FULLPATH}"
VBOXWEB_HOST="${VBOX_SERVER_HOST}"
__VBOX_DEFAULTS_EOF

# If the VirtualBox defaults file doesn't exist, we'll need to create it:
#
if [[ ! -e "${VBOX_DEFAULTS_FULLPATH}" ]]; then

    # Create the directory (as needed) for the VirtualBox defaults file,
    # then create the VirtualBox defaults file from the TMP file contents:
    #
    makdir "${VBOX_DEFAULTS_DIR}"

    copy "${TMP_PATH}" "${VBOX_DEFAULTS_FULLPATH}"

    SetDirPerms "${VBOX_DEFAULTS_FULLPATH}" 644
else
    # It does exist... See if it has the WebServices section in it already:
    #
    SetDirPerms "${VBOX_DEFAULTS_FULLPATH}" 644

    RESULT=$( grep "${VBOX_WEBSRVCS_HDR}" "${VBOX_DEFAULTS_FULLPATH}" )

    if [[ -z "${RESULT}" ]]; then
        #
        # No, it's missing -- add the TMP file contents to the existing file:
        #
        echo | sudo tee -a "${TMP_PATH}"
        cat "${VBOX_DEFAULTS_FULLPATH}" | sudo tee -a "${TMP_PATH}"
        copy "${TMP_PATH}" "${VBOX_DEFAULTS_FULLPATH}"
    else
        # Yes, the file & section exists -- rewrite it:
        #
        Set_Config_File_Value "${VBOX_DEFAULTS_FULLPATH}" \
            "${VBOX_WEBSRVCS_HDR}" VBOXWEB_USER \"${VBOX_USER}\"

        Set_Config_File_Value "${VBOX_DEFAULTS_FULLPATH}" \
            "${VBOX_WEBSRVCS_HDR}" VBOXWEB_TIMEOUT ${VBOX_TIMEOUT}

        Set_Config_File_Value "${VBOX_DEFAULTS_FULLPATH}" \
            "${VBOX_WEBSRVCS_HDR}" VBOXWEB_LOGFILE \"${VBOX_LOGFILE_FULLPATH}\"

        Set_Config_File_Value "${VBOX_DEFAULTS_FULLPATH}" \
            "${VBOX_WEBSRVCS_HDR}" VBOXWEB_HOST \"${VBOX_SERVER_HOST}\"
    fi
fi

sudo rm -rf "${TMP_PATH}"

# Create the VirtualBox log file, and assign its owner:
#
sudo touch "${VBOX_LOGFILE_FULLPATH}"
SetDirPerms "${VBOX_LOGFILE_FULLPATH}" 644 "${VBOX_USER}":"${VBOX_GROUP}"

echo
echo "Starting the VirtualBox Web Services, please wait... "

# Stop the service, if it's running...
#
RESULT=$( sudo service "${VBOX_WEB_SERVICE}" stop )
sleep 2

# Now try to start the service...
#
RESULT=$( sudo service "${VBOX_WEB_SERVICE}" start )
sleep 2

# Check to make sure it actually started:
#
RESULT=$( sudo service "${VBOX_WEB_SERVICE}" status 2>&1 | grep not )

[[ -n "${RESULT}" ]] && ThrowError "${ERR_UNSPEC}" "${APP_SCRIPT}" \
        "Could not start the VBox Webservices service ! "

POST_INSTALL="
    Note that only the virtual machines owned by '${VBOX_USER}' can
    be controlled remotely via the VirtualBox web service.
"

InstallComplete

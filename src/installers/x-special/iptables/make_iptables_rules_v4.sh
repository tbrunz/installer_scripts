#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Programmatically generate an iptables v4 rules file
# ----------------------------------------------------------------------------
#

SYSTEM_NIC_ALIASES_DIR=/sys/class/net

SSH_CONFIG_FILE=/etc/ssh/sshd_config
IPTABLES_V4_RULES_FILE=/etc/iptables/rules.v4

LOOPBACK_NIC_ALIAS="lo"

IPV4_SHOW_ADDR_CMD="ip -4 addr show"
IPV4_SHOW_INET_ADDR_PREFIX="inet"


WAN_NIC_ALIAS=
WAN_SUBNET=
MY_WAN_ADDRESS=

LAN_NIC_ALIAS=
LAN_SUBNET=
MY_LAN_ADDRESS=

LAN_HOST_SSH_PORT=22
LAN_HOST_RDP_PORT=3389

SSH_PORT_RULES=
NAT_PREROUTE_RULES=


#
# Internal parameters
#
INTEGER_REGEXP='^[0-9]+$'

IP_CLASS_A_GREP="([[:digit:]]+[.]){1}"
IP_CLASS_B_GREP="([[:digit:]]+[.]){2}"
IP_CLASS_C_GREP="([[:digit:]]+[.]){3}"

IP_ADDR_GREP="${IP_CLASS_C_GREP}[[:digit:]]+"
IP_CIDR_GREP="${IP_ADDR_GREP}/[[:digit:]]+"


ERR_WARNING=0
ERR_USAGE=1
ERR_NOSUDO=2
ERR_CMDFAIL=4
ERR_UNSPEC=8
ERR_FILEIO=16
ERR_MISSING=32
ERR_BADSWITCH=64
ERR_CANCEL=128


############################################################################
#
# Throw an error
#
# $1 = Exit code (set to '0' for 'no exit')
# $2 = Name of the script throwing the error
# $3 = Name of the function/routine throwing the error (optional)
# $4 = Message string
#
Throw_Error() {

TYPE=""
(( ${1} == ERR_WARNING )) && TYPE="error: "

if (( $# > 3 )); then
    printf "%s: %s: %s%s \n" "${2}" "${3}" "${TYPE}" "${4}" >&2
else
    printf "%s: %s%s \n" "${2}" "${TYPE}" "${3}" >&2
fi

# Exit the script if the error code is not ERR_WARNING:
#
(( ${1} != ERR_WARNING )) && exit ${1}
}


###############################################################################
#
# Get the name of this script (for 'usage')
#
# $1 = Name of the calling script
# $2 = "unwind": Okay to unwind the link redirects
#
Get_Script_Names() {

SCRIPT_PATH="${1}"

CORE_SCRIPT="${BASH_SOURCE[0]}"

if [[ ${2} == [uU]nwind ]]; then

    while [[ -h "${SCRIPT_PATH}" ]]; do
        SCRIPT_PATH="$( readlink -- "${SCRIPT_PATH}" )";
    done
fi

APP_SCRIPT=$( basename "${SCRIPT_PATH}" .sh )

SCRIPT_DIR=$( cd "$( dirname "${0}" )" && pwd )
}


############################################################################
#
# Simple test to see if 'sudo' has already been obtained
#
# $1 = Optional string to indicate operation requiring 'sudo'
#
Qualify_Sudo() {

local DIAGNOSTIC="Cannot run this script without 'sudo' privileges."

[[ -n "${1}" ]] && DIAGNOSTIC="This script requires 'sudo' privileges "${1}

sudo ls /root &>/dev/null

(( $? == 0 )) || Throw_Error "${ERR_NOSUDO}" "${APP_SCRIPT}" "${DIAGNOSTIC}"
}


############################################################################
#
# Display a prompt asking a Yes/No question, repeat until a valid input
#
# Allows for a blank input to be defaulted.  Automatically appends "(y/n)"
# to the prompt, capitalized according to the value of DEF_INPUT
#
# $1 = Default input, (y|n|<don't care>)
# $2 = Prompt
#
# Returns 0 if Yes, 1 if No
#
GetYesNo_Defaulted() {

local PROMPT

case ${1} in
y | Y)
    PROMPT=${2}" [Y/n] "
    ;;
n | N)
    PROMPT=${2}" [y/N] "
    ;;
*)
    PROMPT=${2}" "
    ;;
esac

unset REPLY
while [[ ${REPLY} != "y" && ${REPLY} != "n" ]]; do

    read -e -r -p "${PROMPT}"
    [[ -z "${REPLY}" ]] && REPLY=${1}

    REPLY=${REPLY:0:1} && REPLY=${REPLY,,}
done

[[ ${REPLY} == "y" ]] && return
}


############################################################################
#
# Replace interior whitespace in a variable with another character
#
# $1 = ["<char>"]  default = "" (i.e., remove whitespace)
#
subspace () {

local NEWCHAR=""
local VARIABLE

if (( $# == 0 )); then
  printf ""
  return
fi

if (( $# > 1 )); then
  NEWCHAR=${1}
  shift
  VARIABLE=$( printf "%s" "$*" | tr '[:blank:]' "${NEWCHAR}" )
else
  VARIABLE=$( printf "%s" "$*" | tr -d '[:blank:]' )
fi

printf "%s" "${VARIABLE}"
}


############################################################################
#
# Trim whitespace from a variable: Leading, Trailing, Both, All
#
# $1 = ( -l | -t | -b | -a ) default = -b
#
trim () {

local ACTION="-b"
local VARIABLE

if (( $# == 0 )); then
    printf ""
    return
fi

if (( $# > 1 )); then
    ACTION=${1}
    shift
fi

VARIABLE=${1}

case ${ACTION} in
-l)
    VARIABLE="${VARIABLE#"${VARIABLE%%[![:space:]]*}"}"
    ;;
-t)
    VARIABLE="${VARIABLE%"${VARIABLE##*[![:space:]]}"}"
    ;;
-a)
    VARIABLE=$( subspace "${VARIABLE}" )
    ;&
-b)
    VARIABLE="${VARIABLE#"${VARIABLE%%[![:space:]]*}"}"
    VARIABLE="${VARIABLE%"${VARIABLE##*[![:space:]]}"}"
    ;;
*)
    Throw_Error "${ERR_BADSWITCH}" "${APP_SCRIPT}" "${FUNCNAME}" \
            "Unrecognized switch, '${ACTION}' ! "
    ;;
esac

printf "%s" "${VARIABLE}"
}


###############################################################################
#
# If $INI_LINE is an INI section header, extract the name string
# to $INI_SECTION and return success
#
Resolve_INI_Section_Name () {

INI_SECTION_GREP='^[[:space:]]*[[][[:space:]]*[^[:space:]]+.*[]]'

[[ ${INI_LINE} =~ ${INI_SECTION_GREP} ]] || return 1

INI_SECTION=${INI_LINE#*[}
INI_SECTION=${INI_SECTION%]*}

INI_SECTION=$( trim "${INI_SECTION}" )
}


###############################################################################
#
# If $INI_LINE is a key-value pair, extract each part
#
Resolve_INI_Key_Value_Pair () {

INI_KEY_VALUE_GREP='^[[:space:]]*[^[:space:]]+[[:space:]]*='

[[ ${INI_LINE} =~ ${INI_KEY_VALUE_GREP} ]] || return 1

INI_KEY=$( trim "${INI_LINE%=*}" )
INI_VALUE=$( trim "${INI_LINE#*=}" )
}


###############################################################################
#
# Check to see if $2 already exists in array $1
# If not, then add $2 to $1
#
Check_for_Duplicate_Name () {

echo
}


###############################################################################
#
# Add key "$1$2" = value $3 to INI_FILE_CONTENTS[@]
#
Set_INI_Section_Key_Value () {

echo
}


###############################################################################
#
# Read in an entire INI file to an associative array
#
# Writes INI_FILE_CONTENTS[@]
# Writes INI_FILE_SECTIONS[@]
#
# Needs INI_FILE_PATH
# Calls Resolve_INI_Section_Name
# Calls Resolve_INI_Key_Value_Pair
# Calls Check_for_Duplicate_Name
# Calls Set_INI_Section_Key_Value
#
Read_INI_File () {

local INI_BLANK_GREP='^[[:space:]]*$'
local INI_COMMENT_GREP='^[[:space:]]*;'

local INI_COUNT=0

INI_LINE=""
INI_SECTION=""
INI_KEY=""
INI_VALUE=""

INI_FILE_CONTENTS=()
INI_FILE_SECTIONS=()
INI_FILE_KEYS=()

while IFS='' read -r INI_LINE || [[ -n "${INI_LINE}" ]]; do

  (( INI_COUNT++ ))

  [[ "${INI_LINE}" =~ ${INI_BLANK_GREP} ]] && continue
  [[ "${INI_LINE}" =~ ${INI_COMMENT_GREP} ]] && continue

  RESULT=$( Resolve_INI_Section_Name )
  if (( $? == 0 )); then

    INI_SECTION=${RESULT}

    Check_for_Duplicate_Name "INI_FILE_SECTIONS" "${INI_SECTION}"

    (( $? == 0 )) || Throw_Error "${ERR_UNSPEC}" "${APP_SCRIPT}" "${FUNCNAME}" \
        "line ${INI_COUNT}: Duplicate section name, '${INI_SECTION}' !"

    INI_FILE_KEYS=()
    continue
  fi

  RESULT=$( Resolve_INI_Key_Value_Pair )

  (( $? == 0 )) || Throw_Error "${ERR_UNSPEC}" "${APP_SCRIPT}" "${FUNCNAME}" \
        "line ${INI_COUNT}: Corrupt key-value, '${INI_LINE}' !"

  Check_for_Duplicate_Name "INI_FILE_KEYS" "${INI_KEY}"

  (( $? == 0 )) || Throw_Error "${ERR_UNSPEC}" "${APP_SCRIPT}" "${FUNCNAME}" \
        "line ${INI_COUNT}: Duplicate key, '${INI_KEY}' !"

  Set_INI_Section_Key_Value "${INI_SECTION}" "${INI_KEY}" "${INI_VALUE}"

done < "${INI_FILE_PATH}"
}


###############################################################################
###############################################################################
#
# Generate the stanzas for the rules file
#
Create_Rules_Stanzas () {


###############################################################################
#
# Generate UDP rules set
#
SET_OF_UDP_RULES="#
# Acceptable UDP traffic
#
"


###############################################################################
#
# Generate TCP rules set
#
SET_OF_TCP_RULES="#
# Acceptable TCP traffic
#
"
for SSH_PORT_RULE in "${SSH_PORT_RULES[@]}"; do

  SET_OF_TCP_RULES="${SET_OF_TCP_RULES}${SSH_PORT_RULE}
"
done


###############################################################################
#
# Generate IMCP rules set
#
SET_OF_IMCP_RULES="#
# Acceptable ICMP traffic
#
-A ICMP -p icmp -i ${LAN_NIC_ALIAS} -j ACCEPT
-A ICMP -p icmp -i ${WAN_NIC_ALIAS} -j ACCEPT
"


###############################################################################
#
# Generate Boilerplate rules set
#
SET_OF_BOILERPLATE_RULES="#
# Boilerplate acceptance policy
#
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i lo -j ACCEPT
"


###############################################################################
#
# Generate Invalid rules set
#
SET_OF_INVALID_RULES="#
# Drop invalid packets
#
-A INPUT -m conntrack --ctstate INVALID -j DROP
"


###############################################################################
#
# Generate Protocol rules set
#
SET_OF_PROTOCOL_RULES="#
# Pass traffic to protocol-specific chains
#
# Only allow new connections (established & related should already be handled).
# For TCP, additionally only allow new SYN packets since that is the only valid
# method for establishing a new TCP connection.
#
-A INPUT -p udp -m conntrack --ctstate NEW -j UDP
-A INPUT -p tcp --syn -m conntrack --ctstate NEW -j TCP
-A INPUT -p icmp -m conntrack --ctstate NEW -j ICMP
"


###############################################################################
#
# Generate Rejection rules set
#
SET_OF_REJECTION_RULES="#
# Reject anything that's fallen through to this point
#
# Try to be protocol-specific with the rejection message
#
-A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -p tcp -j REJECT --reject-with tcp-reset
-A INPUT -j REJECT --reject-with icmp-proto-unreachable
"


###############################################################################
#
# Generate Forwarding rules set
#
SET_OF_FORWARDING_RULES="#
# Forward filtering rules:
#
# Forward SSH ports to our Linux boxes, and RDP ports to our Windows boxes.
#
# Firewall network details:
#
# * Public IP Address:  ${WAN_SUBNET}.${MY_WAN_ADDRESS}
# * Private IP Address: ${LAN_SUBNET}.${MY_LAN_ADDRESS}
#
# * Public Interface:  ${WAN_NIC_ALIAS}
# * Private Interface: ${LAN_NIC_ALIAS}
#
-A FORWARD -i ${WAN_NIC_ALIAS} -o ${LAN_NIC_ALIAS} -p tcp --syn --dport ${LAN_HOST_SSH_PORT} -m conntrack --ctstate NEW -j ACCEPT

-A FORWARD -i ${WAN_NIC_ALIAS} -o ${LAN_NIC_ALIAS} -p tcp --syn --dport ${LAN_HOST_RDP_PORT} -m conntrack --ctstate NEW -j ACCEPT

-A FORWARD -i ${WAN_NIC_ALIAS} -o ${LAN_NIC_ALIAS} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

-A FORWARD -i ${LAN_NIC_ALIAS} -o ${WAN_NIC_ALIAS} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

-A FORWARD -i ${LAN_NIC_ALIAS} -o ${WAN_NIC_ALIAS} -j ACCEPT
#-A FORWARD -j LOG

# End of Forward filtering rules
"


###############################################################################
#
# Generate NAT rules set
#
SET_OF_NAT_RULES="#
# NAT Forwarding rules:
#
# Translate SSH ports for our Linux boxes, and RDP ports for our Windows boxes.
#
"
for NAT_RULE in "${NAT_PREROUTE_RULES[@]}"; do

  SET_OF_NAT_RULES="${SET_OF_NAT_RULES}${NAT_RULE}
"
done

SET_OF_NAT_RULES="${SET_OF_NAT_RULES}
-A POSTROUTING -o ${LAN_NIC_ALIAS} -p tcp -d ${LAN_SUBNET}.0/24 -j SNAT --to-source ${LAN_SUBNET}.${MY_LAN_ADDRESS}

-A POSTROUTING -o ${WAN_NIC_ALIAS} -j MASQUERADE

# End of NAT Forwarding rules
"

(( ${#NAT_PREROUTE_RULES[@]} > 0 )) || SET_OF_NAT_RULES=""
}


###############################################################################
###############################################################################
#
# Create the iptables rules file
#
Create_Rules_File () {

echo
echo "Writing out the ${IPTABLES_V4_RULES_FILE}..."

cat | sudo tee >/dev/null "${IPTABLES_V4_RULES_FILE}" << __EOF__
#
# iptables for Bastion Host
#
# 2017-05-17 : Initial set of rules
# 2018-07-19 : Reformatted as a script
#
# Generated by '${APP_SCRIPT}' v${SCRIPT_VERSION} on $( date )
#

*filter
# Allow all outgoing, but drop incoming and forwarding packets by default
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# Custom per-protocol chains
:UDP - [0:0]
:TCP - [0:0]
:ICMP - [0:0]

${SET_OF_UDP_RULES}
${SET_OF_TCP_RULES}
${SET_OF_IMCP_RULES}
${SET_OF_BOILERPLATE_RULES}
${SET_OF_INVALID_RULES}
${SET_OF_PROTOCOL_RULES}
${SET_OF_REJECTION_RULES}
${SET_OF_FORWARDING_RULES}
COMMIT

*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]

${SET_OF_NAT_RULES}
COMMIT

*security
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT

*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT

# Completed on $( date )
# Generated by '${APP_SCRIPT}' v${SCRIPT_VERSION} on $( date )
__EOF__
}


###############################################################################
###############################################################################

NETWORK_DEVICE_ADDRS=
# Get_Network_Device_Addresses
# Delete_from_Network_Device_Addresses
# Make_Formatted_Network_Device_List
NETWORK_DEVICE_LIST=
# Make_Formatted_Network_Device_List
# Choose_Network_Device
NETWORK_DEVICE_CHOICE=
# Choose_Network_Device


###############################################################################
#
# Get list of system network devices and their IP addresses
#
# Writes NETWORK_DEVICE_ADDRS[@]
#
Get_Network_Device_Addresses() {

local NIC_ALIAS
local NIC_ALIAS_LIST

local NIC_ADDR_DETAILS
local NIC_SUBNET
local NIC_ADDRESS

NIC_ALIAS_LIST=$( ls ${SYSTEM_NIC_ALIASES_DIR} )

(( $? == 0 )) || Throw_Error "${ERR_CMDFAIL}" "${APP_SCRIPT}" "${FUNCNAME}" \
    "Could not obtain list of network device aliases !"

NETWORK_DEVICE_ADDRS=()

for NIC_ALIAS in ${NIC_ALIAS_LIST}; do

  # Drop the loopback adapter alias from the list
  #
  [[ "${NIC_ALIAS}" != "${LOOPBACK_NIC_ALIAS}" ]] || continue

  # Get the details on the network device
  #
  NIC_ADDR_DETAILS=$( ${IPV4_SHOW_ADDR_CMD} ${NIC_ALIAS} )
  (( $? == 0 )) || continue

  # Grep out the device's IP address
  #
  NIC_ADDRESS=$( printf "%s" "${NIC_ADDR_DETAILS}" | \
      egrep -o "${IPV4_SHOW_INET_ADDR_PREFIX}[[:space:]]+${IP_ADDR_GREP}" | egrep -o "${IP_ADDR_GREP}" )
  (( $? == 0 )) || continue

  # Split the IP address into subnet+addr parts
  #
  NIC_SUBNET=${NIC_ADDRESS%.*}
  NIC_ADDRESS=${NIC_ADDRESS#${NIC_SUBNET}.}

  # Create a database string that lists this device's parameters
  #
  NETWORK_DEVICE_ADDRS+=( "${NIC_ALIAS}  ${NIC_SUBNET}  ${NIC_ADDRESS}" )
done
}


###############################################################################
#
# Remove a network device from the list of device addresses
#
# Rewrites NETWORK_DEVICE_ADDRS[@] with [${1}] removed
#
Delete_from_Network_Device_Addresses() {

local NEW_LIST
local DELETE_INDEX=${1}
local LIST_SIZE=${#NETWORK_DEVICE_ADDRS[@]}

# If the provided index is not in the range [0..ArySize), then bail
#
(( DELETE_INDEX < LIST_SIZE )) || return 1

NEW_LIST=()
for (( INDEX=0; INDEX<LIST_SIZE; INDEX++ )); do

  # Drop the element whose index matches the provided target index
  #
  (( INDEX != DELETE_INDEX )) || continue

  # Collect every other element in a temp array
  #
  NEW_LIST+=( "${NETWORK_DEVICE_ADDRS[${INDEX}]}" )
done

# Copy the temp array back to the original array, with element deleted
#
NETWORK_DEVICE_ADDRS=( "${NEW_LIST[@]}" )
}


###############################################################################
#
# Make a formatted list of system network devices and their IP addresses
#
# Writes NETWORK_DEVICE_LIST[@]
#
Make_Formatted_Network_Device_List() {

local NETWORK_DEVICE
local NIC_ALIAS
local NIC_SUBNET
local NIC_ADDRESS

NETWORK_DEVICE_LIST=()

for NETWORK_DEVICE in "${NETWORK_DEVICE_ADDRS[@]}"; do

  # Read each string from the database, perform word splitting,
  # and assign each word to its associated temp variable
  #
  read -r  NIC_ALIAS  NIC_SUBNET  NIC_ADDRESS  <<< ${NETWORK_DEVICE}

  # Reformat the words obtained to make a new string,
  # collecting the strings in a new, parallel database array
  #
  NETWORK_DEVICE_LIST+=( "${NIC_ALIAS} (${NIC_SUBNET}.${NIC_ADDRESS})" )
done
}


###############################################################################
#
# Make list of system network devices and their IP addresses
#
# Writes NETWORK_DEVICE_CHOICE (an array index)
#
Choose_Network_Device() {

local CHOOSE_LIST
local CANCEL_OPTION="Cancel"

# Display the list of network devices & their parameters,
# to help the user choose the WAN & LAN device aliases
#
echo
${IPV4_SHOW_ADDR_CMD}
echo

# 'select' uses the PS3 prompt string to prompt for a choice
#
PS3="
Select the network device corresponding to the ${1} network: "

# Augment the formatted network device list with a meta-choice
# that allows the user to cancel out of the script
#
CHOOSE_LIST=( "${NETWORK_DEVICE_LIST[@]}" "${CANCEL_OPTION}" )

unset REPLY
until [[ ${REPLY} ]]; do

  # Use 'select' to present a selection menu to the user; the word it
  # returns will be the text of the menu item, but we don't want that;
  # we want its index instead; this number is returned in $REPLY
  #
  select NETWORK_DEVICE_CHOICE in "${CHOOSE_LIST[@]}"; do

    # If the user chooses the 'cancel' option, bail out with an error code;
    # We don't know the index number, but we know the menu item string...
    #
    if [[ "${NETWORK_DEVICE_CHOICE}" == "${CANCEL_OPTION}" ]]; then

      # Provide two signals if the user wants to bail:
      # A negative index for the choice and a non-zero (error) return code
      #
      NETWORK_DEVICE_CHOICE=-1
      return ${ERR_CANCEL}
    fi

    # Otherwise, if a numeric input is out of range, 'select' won't retry;
    # it will instead return with an empty select string; we have to
    # detect this and use 'until' to loop back to call 'select' again
    #
    if [[ -z "${NETWORK_DEVICE_CHOICE}" ]]; then unset REPLY

    # Otherwise, there's the possibility that the user enters something other
    # than a number ($REPLY is the console input), so check for numeric input
    #
    elif [[ "${REPLY}" =~ ${INTEGER_REGEXP} ]]; then

      # If the input is a number, then we're good, but we need to offset it
      # because bash arrays are zero-based and 'select' is 1-based;
      # Note that our meta-choice, "cancel", has already been screened out
      #
      NETWORK_DEVICE_CHOICE=$(( REPLY - 1 ))
      return
    else
      # Else we got garbage, so force 'until' to loop and "play it again"
      #
      unset REPLY
    fi
  done
done
}


###############################################################################
#
# Get the user's choices for WAN & LAN network devices
#
# Sets the rules file parameters
#
Get_Network_Device_Choices() {

local WAN_NETWORK_DEVICE
local LAN_NETWORK_DEVICE

Get_Network_Device_Addresses

Make_Formatted_Network_Device_List

Choose_Network_Device "WAN (external)"
(( $? == 0 )) || Throw_Error "${ERR_CANCEL}" "${APP_SCRIPT}" \
      "user cancelled, exiting ... "

# 'Choose_Network_Device' sets a database array index in $NETWORK_DEVICE_CHOICE;
# The first go-round lets the user select the WAN device
#
WAN_NETWORK_DEVICE=${NETWORK_DEVICE_ADDRS[${NETWORK_DEVICE_CHOICE}]}

# Having extracted the selected database array string, parse it into the
# parameters needed for the rules file and assign them
#
read -r  WAN_NIC_ALIAS  WAN_SUBNET  MY_WAN_ADDRESS  <<< ${WAN_NETWORK_DEVICE}
(( $? == 0 )) || Throw_Error "${ERR_UNSPEC}" "${APP_SCRIPT}" ${FUNCNAME}\
      "Unable to determine WAN device networking paramaters !"

# Next, we need the LAN device -- but when we present a selection menu,
# we can't have the WAN device on the list, so remove it first
#
Delete_from_Network_Device_Addresses ${NETWORK_DEVICE_CHOICE}

Make_Formatted_Network_Device_List

Choose_Network_Device "LAN (internal)"
(( $? == 0 )) || Throw_Error "${ERR_CANCEL}" "${APP_SCRIPT}" \
      "user cancelled, exiting ... "

LAN_NETWORK_DEVICE=${NETWORK_DEVICE_ADDRS[${NETWORK_DEVICE_CHOICE}]}

read -r  LAN_NIC_ALIAS  LAN_SUBNET  MY_LAN_ADDRESS  <<< ${LAN_NETWORK_DEVICE}
(( $? == 0 )) || Throw_Error "${ERR_UNSPEC}" "${APP_SCRIPT}" ${FUNCNAME}\
      "Unable to determine LAN device networking paramaters !"
}


###############################################################################
###############################################################################
#
# Get the port numbers that SSH is bound to
#
Get_SSH_Port_Numbers() {

SSH_PORT_LIST=()

while read -r _ SSH_PORT; do

  SSH_PORT_LIST+=( ${SSH_PORT} )

done < <( grep '^Port' ${SSH_CONFIG_FILE} )

(( ${#SSH_PORT_LIST[@]} > 0 )) || return ${ERR_MISSING}
}


###############################################################################
#
# Get choices for which SSH ports to expose on which network
#
Get_SSH_Port_Choices() {

local SSH_PORT

Get_SSH_Port_Numbers
(( $? == 0 )) || return

SSH_PORT_RULES=()

echo
for SSH_PORT in "${SSH_PORT_LIST[@]}"; do

  GetYesNo_Defaulted "y" "Export port ${SSH_PORT} for SSH on the WAN side?"
  (( $? == 0 )) || continue

  SSH_PORT_RULES+=( "-A TCP -i ${WAN_NIC_ALIAS} -p tcp --dport ${SSH_PORT} -j ACCEPT" )
done

echo
for SSH_PORT in "${SSH_PORT_LIST[@]}"; do

  GetYesNo_Defaulted "y" "Export port ${SSH_PORT} for SSH on the LAN side?"
  (( $? == 0 )) || continue

  SSH_PORT_RULES+=( "-A TCP -i ${LAN_NIC_ALIAS} -p tcp --dport ${SSH_PORT} -j ACCEPT" )
done
}


###############################################################################
#
# Get choices for LAN host port numbers for each service exposed
#
Get_Service_Port_Choices() {

local HOST_PORT_TYPES
local LAN_HOST_PORTS

local PROMPT1
local PROMPT2

HOST_PORT_TYPES=( "SSH" "RDP" )
LAN_HOST_PORTS=( 22 3389 )

echo
for (( INDEX=0; INDEX<${#HOST_PORT_TYPES[@]}; INDEX++ )); do

  PROMPT1="Enter a port number for ${HOST_PORT_TYPES[${INDEX}]} "
  PROMPT2="into hosts on the LAN side [${LAN_HOST_PORTS[${INDEX}]}] "

  unset REPLY
  until [[ ${REPLY} ]]; do

    read -e -r -p "${PROMPT1}${PROMPT2}"

    if [[ -z "${REPLY}" ]]; then
      REPLY=${LAN_HOST_PORTS[${INDEX}]}

    elif [[ "${REPLY}" =~ ${INTEGER_REGEXP} ]]; then
      (( REPLY < 2 || REPLY > 65535 )) && unset REPLY
    else
      unset REPLY
    fi
  done

  LAN_HOST_PORTS[${INDEX}]=${REPLY}
done

LAN_HOST_SSH_PORT=${LAN_HOST_PORTS[0]}
LAN_HOST_RDP_PORT=${LAN_HOST_PORTS[1]}
}


###############################################################################
#
# Get choices for LAN host port numbers for each service exposed
#
Get_Network_Port_Choices() {

Get_SSH_Port_Choices

Get_Service_Port_Choices
}


###############################################################################
#
# Get choices for LAN host port numbers for each service exposed
#
Get_Network_NAT_Choices() {

SSH_HOST_PORT=2291
SSH_HOST_ADDRESS=100

RDP_HOST_PORT=33891
RDP_HOST_ADDRESS=101

NAT_PREROUTE_RULES=()

#return

NAT_PREROUTE_RULES=(

"-A PREROUTING -i ${WAN_NIC_ALIAS} -p tcp --dport ${SSH_HOST_PORT} -j DNAT --to-destination ${LAN_SUBNET}.${SSH_HOST_ADDRESS}:${LAN_HOST_SSH_PORT}"

"-A PREROUTING -i ${WAN_NIC_ALIAS} -p tcp --dport ${RDP_HOST_PORT} -j DNAT --to-destination ${LAN_SUBNET}.${RDP_HOST_ADDRESS}:${LAN_HOST_RDP_PORT}"
)

}


###############################################################################
###############################################################################
#
# Create an iptables rules file
#
Get_Script_Names "${0}"

Qualify_Sudo

Get_Network_Device_Choices

Get_Network_Port_Choices

Get_Network_NAT_Choices

Create_Rules_Stanzas

Create_Rules_File

exit

###############################################################################
###############################################################################

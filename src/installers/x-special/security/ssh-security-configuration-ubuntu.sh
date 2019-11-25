#! /usr/bin/env bash
#
# Security Configuration script for Ubuntu Linux.
# Adapted from a RHEL script obtained from Scott Feeney.
#
# Version 1.0.1
#
############################################################################
#
# MOTD & SSH symbols
#
MOTD_PATH="/etc/motd"
SSH_DIRECTORY="/etc/ssh"
SSH_BANNER_PATH="${SSH_DIRECTORY}/banner"
SSH_DAEMON_CFG_FILE="${SSH_DIRECTORY}/sshd_config"
INSECURE_CIPHERS=( "3des" "arcfour" )
#
# IPTables symbols
#
NIC_ALIASES_SOURCE_FILE="./this-hosts-nic-aliases-EDIT-ME.sh"
IPTABLES_RULES_SOURCE_PATH="./iptables"
IPTABLES_RULES_FILE_BASE="rules"
IPTABLES_DESTINATION="/etc/iptables"
LAN_NIC_ALIAS_TEMPLATE="%LAN_NIC%"
WAN_NIC_ALIAS_TEMPLATE="%WAN_NIC%"
#
# NTP symbols
#
NTP_CONFIG_SOURCE_FILE="./ntp/ntp.conf"
NTP_CONFIG_DEST_FILE="/etc/ntp.conf"
#
# Logging symbols
#
RSYSLOG_DIRECTORY="/etc/rsyslog.d"
SYSLOG_FILENAME="syslog.conf"
DEFAULT_SYSLOG_FILEPATH="/etc/syslog.conf"
LOG_ROTATE_CFGFILE_PATH="/etc/logrotate.conf"
#
# BigFix symbols
#
BIGFIX_SOURCE_FILE_DIR="./bigfix"
BIGFIX_BES_DEB_FILE_GLOB="BESAgent-*.amd64.deb"
BIGFIX_DEST_DIR="/etc/opt/BESClient"
BIGFIX_MASTHEAD_FILE="./bigfix/masthead.afxm"
BIGFIX_ACTIONSITE_FILEPATH="${BIGFIX_DEST_DIR}/actionsite.afxm"
#
# Other symbols
#
LOGIN_DEFS_FILE="/etc/login.defs"
DEB_INSTALLER="dpkg -i"
#
# Symbolic constants
#
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
ThrowError() {
    #
    # General-purpose warning/error handler.
    # Typically stops the script because some fatal condition occurred.
    #
    if (( $# > 3 )); then
        printf "%s: %s: error: %s \n" "${2}" "${3}" "${4}" >&2
    else
        printf "%s: error: %s \n" "${2}" "${3}" >&2
    fi

    # Exit the script if the error code is not ERR_WARNING:
    #
    (( ${1} != ERR_WARNING )) && exit ${1}
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
    #
    # Prompt the user for a yes/no response to a prompt.
    # Allow for a default value if only <Enter> is typed.
    #
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
# Get the name of this script (for 'usage')
#
# $1 = Name of the calling script
# $2 = "unwind": Okay to unwind the link redirects
#
GetScriptName() {
    #
    # Reflective function to determine which script we are.
    #
    local SCRIPT="${1}"

    CORE_SCRIPT="${BASH_SOURCE[0]}"

    if [[ ${2} == [uU]nwind ]]; then

        while [[ -h "${SCRIPT}" ]]; do
            SCRIPT="$( readlink -- "${SCRIPT}" )";
        done
    fi

    APP_SCRIPT=$( basename "${SCRIPT}" .sh )

    SCRIPT_DIR=$( cd "$( dirname "${0}" )" && pwd )
}

############################################################################
#
# Determine the OS version
#
GetOSversion() {
    #
    # Reflective function to determine which Linux we're running under.
    #
    ARCH=$( uname -m )

    DISTRO=$( lsb_release -sc )
    RELEASE=$( lsb_release -sr )

    FLAVOR=Unity
    lsb_release -sd | grep -q GalliumOS
    (( $? == 0 )) && FLAVOR=xfce

    MAJOR=$( lsb_release -sr | cut -d . -f 1 )
    MINOR=$( lsb_release -sr | cut -d . -f 2 )

    [[ -n "${ARCH}" && -n "${DISTRO}" && -n "${RELEASE}" && \
    -n "${MAJOR}" && -n "${MINOR}" ]] && return

    ThrowError "${ERR_UNSPEC}" "${CORE_SCRIPT}" "${FUNCNAME}" \
        "Could not resolve OS version value !"
}

############################################################################
#
# Simple test to see if 'sudo' has already been obtained
#
QualifySuperuser() {
    #
    # Determine if we're being run as 'root'.
    # If so, then listing the '/root' directory will succeed.
    #
    ls /root >/dev/null 2>&1

    (( $? == 0 )) || ThrowError "${ERR_NOSUDO}" "${APP_SCRIPT}" \
        "Must run this script as root. "
}


############################################################################
#
# Check to see if a (set of) 'glob' file names exist, and capture the names
#
# $1  = "basename" if only the basename is to be returned
# $2  = Source directory
# $3  = Depth of search
# $4+ = Source glob(s)
#
# Returns the file list in ${FILE_LIST[@]}, $?=0 if at least one exists
#
FindGlobFilename() {

    local BASE_ONLY
    local FILE_GLOB
    local FILE_NAME
    local RESULT

    BASE_ONLY=${1}
    shift

    FILE_DIR=${1}
    shift

    DEPTH=${1}
    shift

    GLOB_LIST=( "$@" )
    FILE_LIST=()

    (( DEPTH < 1 )) && ThrowError "${ERR_BADSWITCH}" "${APP_SCRIPT}" \
        "Bad value for 'depth', '${DEPTH}' !"

    #
    # Loop once per glob in the provided list
    #
    RESULT=1
    for FILE_GLOB in "$@"; do

        # Resolve the glob into an array of matching filenames:
        #
        while IFS= read -rd '' FILE_NAME; do

            if [[ ${BASE_ONLY,,} == "basename" ]]; then

                FILE_LIST+=( "$( basename ${FILE_NAME} )" )
                if [[ -f "${FILE_DIR}/${FILE_NAME}" ]]; then RESULT=0; fi
            else
                FILE_LIST+=( "${FILE_NAME}" )
                if [[ -f "${FILE_NAME}" ]]; then RESULT=0; fi
            fi

            done < <( find "${FILE_DIR}" -maxdepth ${DEPTH} -type f \
            -iname "${FILE_GLOB}" -print0 2>/dev/null )
    done

    return ${RESULT}
}

############################################################################
#
# Translate the source 'glob' name into the actual file name (required)
#
# $1 = "basename" if only the basename is to be returned
# $2 = Source directory
# $3 = Depth of search
# $4 = Source glob(s)
#
# Returns the file list in ${FILE_LIST[@]}
#
ResolveGlobFilename() {

    FindGlobFilename "$@"

    # If FindGlobFilename fails to find anything, only complain using the
    # first file in the list provided -- hence ${GLOB_LIST} w/o the '[@]':
    #
    (( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
        "Cannot find a file matching '${GLOB_LIST}' in '${FILE_DIR}' !"
}

############################################################################
#
# Install firewall (IPTables) & rules files
#
Install_IPtables() {
    unset ${LAN_NIC_ALIAS}
    unset ${WAN_NIC_ALIAS}
    #
    # Source the parameter file containing the LAN- & WAN-side NIC aliases.
    #
    [[ -r "${NIC_ALIASES_SOURCE_FILE}" ]] || \
        ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
        "Cannot find the NIC aliases file, '${NIC_ALIASES_SOURCE_FILE}' ! "
    #
    source "${NIC_ALIASES_SOURCE_FILE}"
    #
    # Verify that both NIC aliases were actually read from the file.
    #
    [[ ${LAN_NIC_ALIAS} ]] && [[ ${WAN_NIC_ALIAS} ]] || \
        ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
        "Missing at least one NIC aliases in '${NIC_ALIASES_SOURCE_FILE}' ! "
    #
    # Verify that both NIC aliases map to physical NICs in this system.
    #
    ip addr | grep -q "${LAN_NIC_ALIAS}" 2>/dev/null
    (( $? == 0 )) || \
        ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
        "Could not find LAN NIC '${LAN_NIC_ALIAS}' in this host ! "
    #
    ip addr | grep -q "${WAN_NIC_ALIAS}" 2>/dev/null
    (( $? == 0 )) || \
        ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
        "Could not find WAN NIC '${WAN_NIC_ALIAS}' in this host ! "
    #
    # Verify/create the destination for the IPTables rules file(s).
    #
    [[ -d "${IPTABLES_DESTINATION}" ]] || mkdir -p "${IPTABLES_DESTINATION}"
    (( $? == 0 )) || \
        ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not verify/create the '${IPTABLES_DESTINATION}' directory ! "
    #
    # Make sure the 'iptables' packages are installed.
    #
    # We do this here, because the installer will want to save the current
    # IPTables state to the same config files we're about to install.
    #
    apt-get install iptables iptables-persistent
    (( $? == 0 )) || \
        ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not install/verify the 'iptables' packages ! "
    #
    # Then copy & configure the rules template files, one by one.
    #
    unset IP_RULES_WERE_INSTALLED
    for IP_TYPE in v4 v6; do
        #
        # Form the complete name of the files/paths we're dealing with.
        #
        RULES_FILE=${IPTABLES_RULES_FILE_BASE}.${IP_TYPE}
        #
        SOURCE_PATH=${IPTABLES_RULES_SOURCE_PATH}/${RULES_FILE}
        DEST_PATH=${IPTABLES_DESTINATION}/${RULES_FILE}
        #
        # Check the source directory to see if our file is there.
        # If not, it's not an error; we just don't change those rules.
        #
        [[ -r  "${SOURCE_PATH}" ]] || continue
        #
        # Since the rules file exists, copy it to where it belongs,
        # making a backup of any pre-existing version, if present.
        #
        if [[ -x "${DEST_PATH}" ]]; then
            cp -a "${DEST_PATH}" "${DEST_PATH}".bak
            (( $? == 0 )) || \
                ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
                "Could not back up '${DEST_PATH}' to '${DEST_PATH}.bak' ! "
        fi
        #
        cp -a "${SOURCE_PATH}" "${DEST_PATH}"
        (( $? == 0 )) || \
            ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
            "Could not copy '${SOURCE_PATH}' to '${DEST_PATH}' ! "
        #
        # Then edit it in situ to change the '%<parameter>%' occurrences.
        #
        sed -i \
            -e "s|${LAN_NIC_ALIAS_TEMPLATE}|${LAN_NIC_ALIAS}|g" \
            -e "s|${WAN_NIC_ALIAS_TEMPLATE}|${WAN_NIC_ALIAS}|g" \
            "${DEST_PATH}"
        (( $? == 0 )) || \
            ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
            "Could not edit '${DEST_PATH}' to replace templates ! "
        #
        # Make a note that we actually did something,
        # and provide status feedback.
        #
        local IP_RULES_WERE_INSTALLED=true
        echo "*** Installed 'iptables' rules file '${DEST_PATH}' *** "
    done
    #
    # Now check to see if we actually installed something.
    #
    SOURCE_FILES_FORM=${IPTABLES_RULES_SOURCE_PATH}/${IPTABLES_RULES_FILE_BASE}
    #
    [[ ${IP_RULES_WERE_INSTALLED} ]] || \
        ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not find any '${SOURCE_FILES_FORM}.*' files ! "
}

############################################################################
#
# Install NTP service and configuration file.
#
Install_NTP() {
    #
    # Make sure the 'ntp' packages are installed.
    #
    apt-get install ntp
    (( $? == 0 )) || \
        ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
        "Could not install/verify the 'ntp' packages ! "
    #
    # Optionally replace the NTP configuration file.
    #
    GetYesNo_Defaulted "n" "Replace the default NTP config file?"
    if (( $? != 0 )); then
        #
        # Replace the distro's NTP config file with our version,
        # making a backup of any pre-existing version, if present.
        #
        if [[ -x "${NTP_CONFIG_DEST_FILE}" ]]; then
            cp -a "${NTP_CONFIG_DEST_FILE}" "${NTP_CONFIG_DEST_FILE}".bak
            (( $? == 0 )) || \
                ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
                "Could not back up '${NTP_CONFIG_DEST_FILE}' ! "
        fi
        #
        # Then replace the distro's NTP config file with our version.
        #
        cp -a "${NTP_CONFIG_SOURCE_FILE}" "${NTP_CONFIG_DEST_FILE}"
        (( $? == 0 )) || \
            ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
            "Could not copy '${NTP_CONFIG_SOURCE_FILE}' to '${NTP_CONFIG_DEST_FILE}' ! "
        #
        # Restart the NTP service so that it picks up the new config file.
        #
        service ntp restart
        (( $? == 0 )) || \
            ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
            "Could not restart the NTP service ! "
    fi
    #
    # Provide status feedback.
    #
    echo "*** Installed NTP & customized config file *** "
}

############################################################################
#
# Modify password defaults to comply with security rules.
#
Modify_PW_and_Logins() {
    #
    # Note: The following section is for local accounts;
    # All user accounts should be using LDAP authentication,
    # which takes care of the various password requirements.
    #
    sed -e 's|^PASS_MAX_DAYS.*$|PASS_MAX_DAYS 90|' \
        -e 's|^PASS_MIN_LEN.*$|PASS_MIN_LEN 8|' \
        -i.bak "${LOGIN_DEFS_FILE}"
    (( $? == 0 )) || \
        ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not edit password defaults in '${LOGIN_DEFS_FILE}' ! "
    #
    # Deny 'root' login via SSH using a password to authenticate.
    #
    # Start by determining what lines exist in the SSH config file.
    #
    grep -q '^[[:space:]]*#[[:space:]]*PermitRootLogin' \
        "${SSH_DAEMON_CFG_FILE}"
    COMMENT_FOUND=$?

    grep -q '^[[:space:]]*PermitRootLogin' \
        "${SSH_DAEMON_CFG_FILE}"
    RESULT=$(( COMMENT_FOUND + $? ))

    (( RESULT == 1 )) && (( COMMENT_FOUND == 1 )) && RESULT=0
    #
    # Then edit the file accordingly.
    #
    case $RESULT in
        0)  # The config file has a 'PermitRootLogin' line: Replace it.
            sed -r -e "s|^[[:space:]]*PermitRootLogin.*|\
                PermitRootLogin prohibit-password|" \
                -i "${SSH_DAEMON_CFG_FILE}"
            (( $? == 0 )) || \
                ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
                "Can't replace 'PermitRootLogin' in '${SSH_DAEMON_CFG_FILE}' ! "
            ;;
        1)  # The config file has only a '# PermitRootLogin' line: Add one.
            sed -r -e \
                "/^[[:space:]]*#[[:space:]]*PermitRootLogin.*/aPermitRootLogin prohibit-password " \
                -i "${SSH_DAEMON_CFG_FILE}"
            (( $? == 0 )) || \
                ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
                "Can't override 'PermitRootLogin' in '${SSH_DAEMON_CFG_FILE}' ! "
            ;;
        *)  # The config file has no line with 'PermitRootLogin': Append one.
            cat >> "${SSH_DAEMON_CFG_FILE}" <<_END_NEW_SSH_ROOT_LOGIN_CONFIG

# PermitRootLogin yes
PermitRootLogin prohibit-password

_END_NEW_SSH_ROOT_LOGIN_CONFIG
            (( $? == 0 )) || \
                ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
                "Can't add 'PermitRootLogin' to '${SSH_DAEMON_CFG_FILE}' ! "
            ;;
    esac
    #
    # Configure sudoers for access to root account.
    #
    # (( This is not necessary for Ubuntu Linux systems ))
    #
    # Provide status feedback.
    #
    echo "*** Modified password & SSH login rules *** "
}

############################################################################
#
# Disable insecure ciphers in OpenSSH to address SPL tickets.
#
Disable_Insecure_Ciphers() {
    #
    # Start by getting a list of the current ciphers.
    #
    THIS_CIPHER_LIST=$( ssh -Q cipher )
    #
    # Nothing to do if there are no ciphers being used.
    #
    if [[ -z "${THIS_CIPHER_LIST}" ]]; then
        echo "***** Warning: No valid ciphers are being used by SSH..?? ***** "
        return
    fi
    #
    # Start a pair of CSV lists of what we winnow out of the above list.
    #
    ACCEPTED_CIPHERS=""
    REJECTED_CIPHERS=""
    #
    while read ; do
        #
        # If there was nothing read from the cipher list, skip iteration.
        #
        [[ -n "${REPLY}" ]] || continue
        #
        # Grep each cipher against the regexp pattern in the insecure list.
        #
        for BAD_CIPHER in "${INSECURE_CIPHERS[@]}"; do

            [[ "${REPLY}" =~ ${BAD_CIPHER} ]] && break
        done

        if [[ "${REPLY}" =~ ${BAD_CIPHER} ]]; then

            REJECTED_CIPHERS="${REJECTED_CIPHERS},${REPLY}"
        else
            ACCEPTED_CIPHERS="${ACCEPTED_CIPHERS},${REPLY}"
        fi
    done < <( printf "%s" "${THIS_CIPHER_LIST}" )
    #
    # Each string is either empty, or starts with a ',' that needs removal.
    #
    [[ -z "${ACCEPTED_CIPHERS}" ]] || ACCEPTED_CIPHERS=${ACCEPTED_CIPHERS:1}
    [[ -z "${REJECTED_CIPHERS}" ]] || REJECTED_CIPHERS=${REJECTED_CIPHERS:1}
    #
    # Check to see if there are any secure ciphers left.
    #
    if [[ -z "${ACCEPTED_CIPHERS}" ]]; then
        echo "***** Warning: No valid ciphers found for SSH ! ***** "
        return
    fi
    #
    # Determine if there is an existing 'Ciphers' line in the SSH config file.
    #
    grep -q '^Ciphers' "${SSH_DAEMON_CFG_FILE}"

    if (( $? == 0 )); then
        #
        # There exists a 'Ciphers' line -- Replace it.
        #
        cp "${SSH_DAEMON_CFG_FILE}" "${SSH_DAEMON_CFG_FILE}.bak"

        sed -i -e \
          "s|^# Disable .* ciphers|# Disable '${REJECTED_CIPHERS}' ciphers|" \
          "${SSH_DAEMON_CFG_FILE}"
        sed -i -e \
          "s|^Ciphers.*$|Ciphers ${ACCEPTED_CIPHERS}|" \
          "${SSH_DAEMON_CFG_FILE}"

        (( $? == 0 )) || \
            ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
            "Could not edit 'Ciphers' list in '${SSH_DAEMON_CFG_FILE}' ! "
        #
        # Otherwise, add a new 'Ciphers' line.
        #
    else
        cat >> "${SSH_DAEMON_CFG_FILE}" <<_END_NEW_SSH_CIPHERS_CONFIG
#
# Disable '${REJECTED_CIPHERS}' ciphers
Ciphers ${ACCEPTED_CIPHERS}

_END_NEW_SSH_CIPHERS_CONFIG
        (( $? == 0 )) || \
            ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
            "Could not add 'Ciphers' list in '${SSH_DAEMON_CFG_FILE}' ! "
    fi
    #
    # Provide status feedback.
    #
    echo "*** Disabled '${REJECTED_CIPHERS}' ciphers for SSH *** "
}

############################################################################
############################################################################
#
GetScriptName "${0}"
GetOSversion
#
### Verify that this script is being run as 'root'.
#
QualifySuperuser
#
### Set the Banner/MOTD files for logins.
#
#Set_Banner_MOTD
#
### Install iptables & rules files.
#
GetYesNo_Defaulted "n" "Install 'iptables'?"
(( $? == 0 )) && Install_IPtables
#
### Install NTP with a custom config file.
#
GetYesNo_Defaulted "n" "Install NTP?"
(( $? == 0 )) && Install_NTP
#
### Have the syslog file be forwarded to the syslog server.
#
#Configure_System_Logging
#
### Install the BigFix package files.
#
#Install_BigFix
#
### Modify passwords and logins.
#
#Modify_PW_and_Logins
#
### Disable insecure crypto ciphers.
#
Disable_Insecure_Ciphers
#
############################################################################
############################################################################

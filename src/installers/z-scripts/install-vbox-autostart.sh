#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Configure VirtualBox Autostart/Autostop features
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
VBOX_DEFS_DIR=/etc/default
VBOX_DEFS_FULLPATH=${VBOX_DEFS_DIR}/virtualbox

VBOX_AUTOSTART_HDR="VirtualBox Autostart"

VBOX_AUTOSTART_DIR=/etc/vbox
VBOX_AUTOCONF_FULLPATH=${VBOX_AUTOSTART_DIR}/vboxauto.conf

SERVICE_FILE_DIR=/etc/init.d
VBOX_AUTOSTART_SERVICE=vboxautostart-service

# System group required for users to have vbox privileges:
#
VBOX_GROUP=vboxusers


############################################################################
#
USAGE="
VirtualBox provides an ability for virtual machines to be automatically
started when a system boots.

This script performs the configuration steps needed to set up the
'${VBOX_AUTOSTART_SERVICE}' so that users in the '${VBOX_GROUP}' group, who
have auto-start privileges, can specify which of their VMs they wish
to be started at system boot-up.
"

POST_INSTALL="
    Note that each eligible VirtualBox user that wishes to have a particular
    virtual machine automatically start at bootup must manually set each VM
    to be autostarted by entering these commands in a terminal window:

        vboxmanage modifyvm \"<virtual machine name>\" --autostart-enabled on
        vboxmanage modifyvm \"<virtual machine name>\" --autostart-delay <n>

    where <n> is in seconds.  Setting 'enabled' to \"off\" disables autostart.
"


############################################################################
#
SET_NAME="VBox Autostart"
PACKAGE_SET=""

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"


############################################################################
#
# Start by getting a list of this host's 'vboxusers':
#
QualifySudo

VBOX_USER_LIST=$( getent group ${VBOX_GROUP} | cut -d ":" -f 4 | tr "," " " )

[[ -z "${VBOX_USER_LIST}" ]] && ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
        "Cannot find any VirtualBox users! (Is VBox installed?) "

VBOX_USERS=( ${VBOX_USER_LIST} )

[[ ! -x ${SERVICE_FILE_DIR}/${VBOX_AUTOSTART_SERVICE} ]] && \
        ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
"Cannot find the VBox Autostart Service! (Is the Extensions Pack installed?) "


############################################################################
#
# Create the VirtualBox Autostart section of the VBox defaults file:
#
maketmp

cat > ${TMP_PATH} << EOF
# ${VBOX_AUTOSTART_HDR}
VBOXAUTOSTART_DB="${VBOX_AUTOSTART_DIR}"
VBOXAUTOSTART_CONFIG="${VBOX_AUTOCONF_FULLPATH}"
EOF

# If the VirtualBox defaults file doesn't exist, we'll need to create it:
#
if [[ ! -e ${VBOX_DEFS_FULLPATH} ]]; then

    # Create the directory (as needed) for the VirtualBox defaults file,
    # then create the VirtualBox defaults file from the TMP file contents:
    #
    makdir "${VBOX_DEFS_DIR}"

    copy ${TMP_PATH} ${VBOX_DEFS_FULLPATH}

    SetDirPerms "${VBOX_DEFS_FULLPATH}" 644
else
    # It does exist... See if it has the Autostart section in it already:
    #
    SetDirPerms "${VBOX_DEFS_FULLPATH}" 644

    RESULT=$( grep "${VBOX_AUTOSTART_HDR}" ${VBOX_DEFS_FULLPATH} )

    if [[ -z "${RESULT}" ]]; then
        #
        # No, it's missing -- add the TMP file contents to the existing file:
        #
        sudo echo >> ${TMP_PATH}
        sudo cat ${VBOX_DEFS_FULLPATH} >> ${TMP_PATH}
        copy ${TMP_PATH} ${VBOX_DEFS_FULLPATH}
    else
        # Yes, the file & section exists -- rewrite it:
        #
        Set_Config_File_Value ${VBOX_DEFS_FULLPATH} "${VBOX_AUTOSTART_HDR}" \
                VBOXAUTOSTART_DB \"${VBOX_AUTOSTART_DIR}\"

        Set_Config_File_Value ${VBOX_DEFS_FULLPATH} "${VBOX_AUTOSTART_HDR}" \
                VBOXAUTOSTART_CONFIG \"${VBOX_AUTOCONF_FULLPATH}\"
    fi
fi

rm -rf ${TMP_PATH}


############################################################################
#
# Create the VirtualBox Autostart DB directory, and assign its owner/perms:
#
makdir "${VBOX_AUTOSTART_DIR}" 3775 root:${VBOX_GROUP}


############################################################################
#
# Find out which of the users are to be allowed to autostart their VMs:
#
VBOX_AUTO_USERS=()

echo
while (( ${#VBOX_AUTO_USERS[@]} == 0 )); do

    echo "Which users are to have VirtualBox Autostart privileges? "

    for THIS_USER in "${VBOX_USERS[@]}"; do

        Get_YesNo_Defaulted -y "User '${THIS_USER}'?"

        (( $? == 0 )) && VBOX_AUTO_USERS+=( ${THIS_USER} )
    done

    (( ${#VBOX_AUTO_USERS[@]} == 0 )) && echo "Doh! Need at least one! "
done


############################################################################
#
# Create/recreate the VirtualBox Autostart config file:
#
maketmp

cat > ${TMP_PATH} << EOF
# Default policy is to deny starting a VM, the other option is "allow".
default_policy = deny
EOF

DELAY=0
for VBOX_USER in ${VBOX_AUTO_USERS[@]}; do
    #
    # Stagger the startups by 10 seconds each:
    #
    DELAY=$(( DELAY + 10 ))

    echo >> ${TMP_PATH}
    echo "# User is allowed to start virtual machines, " >> ${TMP_PATH}
    echo "# but startups will be delayed for ${DELAY} seconds" >> ${TMP_PATH}

    echo "${VBOX_USER} = {" >> ${TMP_PATH}
    echo "    allow = true" >> ${TMP_PATH}
    echo "    startup_delay = ${DELAY}" >> ${TMP_PATH}
    echo "}" >> ${TMP_PATH}
done

# Move the resulting config file into place, then dump the temp file:
#
copy ${TMP_PATH} "${VBOX_AUTOCONF_FULLPATH}"
SetDirPerms "${VBOX_AUTOCONF_FULLPATH}" 644 root:root

rm -rf ${TMP_PATH}


############################################################################
#
# For each of these users, we need to have them exec the VBox Manage
# command that will enable autostarting for their virtual machines
#
for VBOX_USER in ${VBOX_AUTO_USERS[@]}; do

    sudo -i -H -u ${VBOX_USER} \
            vboxmanage setproperty autostartdbpath "${VBOX_AUTOSTART_DIR}"
done


############################################################################
#
# Stop the service, if it's running...
#
#sudo service ${VBOX_AUTOSTART_SERVICE} stop
#sleep 2

# Now try to start the service...
#
#sudo service ${VBOX_AUTOSTART_SERVICE} start
#sleep 2

# Check to make sure it actually started:
#
#RESULT=$( ps -ef | grep vboxauto )

#[[ -n "${RESULT}" ]] && ThrowError "${ERR_UNSPEC}" "${APP_SCRIPT}" \
#        "Could not start the VBox Autostart service ! "


InstallComplete

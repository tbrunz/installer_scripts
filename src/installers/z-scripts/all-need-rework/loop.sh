#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Manage loop mounting of a file as a block device
# ----------------------------------------------------------------------------
#

unset READ_ONLY

#
# Get the name of this script (for 'usage')
#
SCRIPT="${BASH_SOURCE[0]}"
while [ -h "${SCRIPT}" ] ; do SCRIPT="$(readlink "${SCRIPT}")" ; done
THIS_SCRIPT=$( basename ${SCRIPT} .sh )
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
# Display the one-line usage prompt
#
usage() {
    echo "usage: ${THIS_SCRIPT} [ -t ] <cmd> "
}

#
# Display the 'usage' prompt (-h)
#
if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then

    echo 
    usage
    echo 
    echo "    ${THIS_SCRIPT} mount <file> <mount> [ -r ] [ <dev#> ] "
    echo "    ${THIS_SCRIPT} umount <file> | <mount> | <dev#> "
    echo "    ${THIS_SCRIPT} info   <file> | <mount> | <dev#> "
    echo "    ${THIS_SCRIPT} show "
    echo "    ${THIS_SCRIPT} next "
    echo "    ${THIS_SCRIPT} attach <file> [ -r ] [ <dev#> ] "
    echo "    ${THIS_SCRIPT} detach <file> [ <dev#> ] "
    echo 
    echo "This script does the following: "
    echo "  1.)  "
    echo "  2.)  "
    echo 
    echo "Options: "
    echo "    -t  --test    = Run in test mode; show what is being applied "
    echo 
    echo "FIX ME! This script will unpack and create '/etc/hosts-YYYY-MMDD' (in *nix file "
    echo "format) from the 'HOSTS' file found inside the downloaded 'hosts.zip' file. "
    echo 
    echo "The 'hosts.zip' file is expected to be found in '../hosts-files', relative "
    echo "to this script.  Once created, it will then combine this file with the "
    echo "local hosts file, '/etc/hosts-<system>' (which should have only the local "
    echo "IP-host definitions) to create the file '/etc/hosts-blocking'. "
    echo 
    echo "If <system> is not specified, it defaults to 'home'. "
    echo 
    echo "Finally, the script will copy '/etc/hosts-blocking' to '/etc/hosts', then "
    echo "display all the '/etc/hosts-*' files for visual confirmation. "
    echo 
    echo "Note that this script can be run repeatedly without causing side-effects. "
    echo 

    exit 1
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
if [[ $(echo ${1} | cut -c 1) == "-" ]]; then

    echo "${THIS_SCRIPT}: Unknown switch '${1}' "
    exit 4
fi

#
# Function to translate { <file> | <mount> | <device> } 
# into the set of all three configuration parameters:
# { $LOOP_FILE, $MOUNT_PATH, $DEVICE }
#
GetDeviceInfo() {
    
    BINDING=$( sudo losetup -a )
    DEVICE=$( echo "${BINDING}" | grep ${1} | cut -d ':' -f 1 )
    MOUNT_PATH=$( mount | cut -d ' ' -f 3 | grep ${1} )

    # First, check to see if the argument is a loop device specifier:
    #
    if [ $( echo ${1} | egrep "^loop[0-9]+$" ) ]; then
    
        DEVICE=/dev/${1}
        BINDING=$( sudo losetup ${DEVICE} 2> /dev/null )
        
        # It's a loop device specifier, but is it bound to a file?
        #
        if [ -n "${BINDING}" ]; then
        
            LOOP_FILE=$( echo ${BINDING} | cut -d '(' -f 2 | cut -d ')' -f 1 )

            # So far so good... But is it mounted, too?
            #
            MOUNT_PATH=$( mount | grep ${DEVICE} | cut -d ' ' -f 3 )

            if [ ! $( echo "${MOUNT_PATH}" | grep '^/' ) ]; then
                MOUNT_PATH=""
            fi
        else
            LOOP_FILE=""
            MOUNT_PATH=""
        fi
        
    # Next, check to see if it's a file bound to a device:
    #
    elif [ -n "${DEVICE}" ]; then
    
        LOOP_FILE=${1}

        # So far so good... But is it mounted, too?
        #
        MOUNT_PATH=$( mount | grep ${DEVICE} | cut -d ' ' -f 3 )

        if [ ! $( echo "${MOUNT_PATH}" | grep '^/' ) ]; then
            MOUNT_PATH=""
        fi
    
    # Finally, check to see if it's a mount path for a device: 
    #
    elif [ -n "${MOUNT_PATH}" ]; then
        
        DEVICE=$( mount | grep ${1} | cut -d ' ' -f 1 )
        BINDING=$( sudo losetup ${DEVICE} 2> /dev/null )
        
        # It has to be bound to a file if it's mounted...
        #
        if [ -n "${BINDING}" ]; then
        
            LOOP_FILE=$( echo ${BINDING} | cut -d '(' -f 2 | cut -d ')' -f 1 )
        else
            LOOP_FILE=""
            MOUNT_PATH=""
            DEVICE=""
        fi
    fi
}

#
# Display info about one device to the user
#
DisplayDeviceInfo() {
    if [ -n "${MOUNT_PATH}" ]; then
        
        if [ -z "${HEADER}" ]; then
            df 2> /dev/null | grep "Use%"
            HEADER=true
        fi
        
        df 2> /dev/null | grep ${DEVICE}
        ATTACH_MSG=""
    else
        ATTACH_MSG=", but is not mounted "
    fi
    
    if [ -n ${LOOP_FILE} ]; then

        echo "${DEVICE} is attached to file '${LOOP_FILE}'${ATTACH_MSG} "
    fi
}

# 
# The first argument must be the sub-command to execute...
#
COMMAND=${1}
shift

if [[ -n "${TEST_MODE}" ]]; then 

    echo "Test mode: Executing '${COMMAND}'... "
fi

#
# Verify that the user can obtain 'sudo' privileges...
#
sudo ls /root > /dev/null 2>&1

if [[ $? != 0 ]]; then

    echo "${THIS_SCRIPT}: Cannot run this script without 'root' privileges. "
    exit 8
fi

#
# Respond to a Show command
#
if [[ "${COMMAND}" == "show" || "${COMMAND}" == "s" ]]; then

    DEVICE_LIST=$( sudo losetup -a )

    if [[ -z "${DEVICE_LIST}" ]]; then

        echo "No loop devices are being used. "
        exit
    fi
    
    unset HEADER

    for TOKEN in ${DEVICE_LIST}; do
        
        TOKEN=$( echo ${TOKEN} | cut -d ':' -f 1 )
        
        if [ $( echo ${TOKEN} | egrep "^/dev/loop[0-9]+$" ) ]; then
        
            GetDeviceInfo ${TOKEN}
            DisplayDeviceInfo
        fi
    done
    
    exit
fi

#
# Respond to a Next command
#
if [[ "${COMMAND}" == "next" || "${COMMAND}" == "n" ]]; then

    sudo losetup -f
    exit
fi

#
# Respond to an Info command
#
if [[ "${COMMAND}" == "info" || "${COMMAND}" == "i" ]]; then

    if [ -z ${1} ]; then
        echo "usage: ${THIS_SCRIPT} info <file> | <mount> | <device> "
        exit 16
    fi
    
    GetDeviceInfo ${1}
    
    if [ -n "${DEVICE}" ]; then
        
        DisplayDeviceInfo
    else
        echo "'${1}' does not refer to a loop device. "
    fi
fi

exit




if [[ -n "${READ_ONLY}" ]]; then

    if [[ -z ${1} ]]; then

        SYSTEM=home
    else
        SYSTEM=${1}
        shift
    fi

    HOSTS_BASE=hosts-${SYSTEM}
    HOSTS_BLOCKING=hosts-blocking-${SYSTEM}

    #
    # Verify that '/etc/hosts-<system>' file exists...
    # 
    if [[ ! -f /etc/${HOSTS_BASE} ]]; then

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
# If ${1} was given, then treat it as a path to where the 'hosts.zip' file is.
# If ${1} doesn't exist, then use the default instead (i.e., pendrive install).
#
if [[ -n ${1} ]]; then

    HOSTS_ZIP=${1}
    SOURCE="from command line"
fi

if [[ -n "${TEST_MODE}" ]]; then 

    echo "Test mode: Using '${HOSTS_ZIP}' ${SOURCE} as source of 'hosts.zip' file... "
fi

#
# Verify that we can find the 'hosts.zip' file...
# 
if [[ ! -f ${HOSTS_ZIP} ]]; then

    echo "${THIS_SCRIPT}: Can't find the file '${HOSTS_ZIP}'! "
    ERRORS=true

elif [[ -n "${TEST_MODE}" ]]; then 

    echo "Test mode: Found 'hosts.zip' file as '${HOSTS_ZIP}'... "
fi

#
# If we encountered any errors, bail out now...
#
if [[ ${ERRORS} ]]; then
    exit 8
fi

#
# If there is an existing '/tmp/HOSTS' file present, we need to remove it, 
# as the 'unzip' command will have problems otherwise.  If we can't remove 
# it ourselves, then try 'sudo'.
#
#if [[ ! ${TEST_MODE} && 
#
if [[ -f /tmp/${HOSTS_WIN} && $( rm -f /tmp/${HOSTS_WIN} 2>&1 ) && -f /tmp/${HOSTS_WIN} ]]; then

    if [[ -n "${TEST_MODE}" ]]; then 

        echo "Test mode: Found pre-existing '/tmp/${HOSTS_WIN}' file; attempting to remove... "
    fi

    sudo rm -f /tmp/${HOSTS_WIN}

    if [[ -f /tmp/${HOSTS_WIN} ]]; then

        if [[ -n "${TEST_MODE}" ]]; then 

            echo "Test mode: Could not remove '/tmp/${HOSTS_WIN}'... "
        fi

        echo "${THIS_SCRIPT}: Cannot run without 'sudo' privileges. "
        exit 16

    elif [[ -n "${TEST_MODE}" ]]; then 

        echo "Test mode: Successfully removed '/tmp/${HOSTS_WIN}'... "
    fi
fi

#
# Extract the HOSTS file to '/tmp/'.  Remove any pre-existing file, 
# or else the user will get an unexpected "replace?" prompt...
#
unzip -q ${HOSTS_ZIP} ${HOSTS_WIN} -d /tmp 2>&1

if [[ ! -f /tmp/${HOSTS_WIN} ]]; then

    echo "${THIS_SCRIPT}: Cannot unzip ${HOSTS_ZIP}! "
    exit 32

elif [[ -n "${TEST_MODE}" ]]; then 

    echo "Test mode: Successfully unzipped ${HOSTS_ZIP} into '/tmp/${HOSTS_WIN}'... "
fi

#
# Before we leave the script's directory, install the corresponding fixup script into 
# the '/etc' directory (for future mods)...
#
if [[ -f ${FIXUP_SCRIPT} ]]; then

    sudo cp -f ${FIXUP_SCRIPT} /etc/

else
    echo "${THIS_SCRIPT}: Could not find '${FIXUP_SCRIPT}' ! "
fi

#
# Convert and copy to make 'hosts-blocking'
#
cd /tmp

if [[ -n "${READ_ONLY}" ]]; then

    fromdos -a -d -o ${HOSTS_WIN}

    cat ${HOSTS_WIN} | sed -e '/^127.*localhost/d' | sed -e '/^::.*localhost/d' > ${HOSTS_BLOCKING}

    if [[ -n "${TEST_MODE}" ]]; then 

        echo "Test mode: Converted 'hosts.zip' from DOS format & removed 'localhost' entries... "
    fi
fi

#
# Extract the date from the HOSTS file
#
# Get the whole date string:
#
FILE_DATE=$( grep '[[:blank:]]*Updated:[[:blank:]]*' ${HOSTS_WIN} | cut -d ' ' -f 4 )

if [[ -n "${TEST_MODE}" ]]; then 

    echo "Test mode: Extracted '${FILE_DATE}' from '${HOSTS_WIN}' file... "
fi

#
# Extract the named month & convert to 'MM' format:
# (Note that if we can't translate it, the month goes to '00'.)
#
FILE_MONTH=$( echo ${FILE_DATE} | cut -d '-' -f 1 | tr '[:upper:]' '[:lower:]' )

if [[ -n "${TEST_MODE}" ]]; then 

    echo -n "Test mode: Extracted '${FILE_MONTH}' "
fi

case ${FILE_MONTH} in

    jan | january   )  FILE_MONTH="01" ;;
    feb | february  )  FILE_MONTH="02" ;;
    mar | march     )  FILE_MONTH="03" ;;
    apr | april     )  FILE_MONTH="04" ;;
    may | may       )  FILE_MONTH="05" ;;
    jun | june      )  FILE_MONTH="06" ;;
    jul | july      )  FILE_MONTH="07" ;;
    aug | august    )  FILE_MONTH="08" ;;
    sep | september )  FILE_MONTH="09" ;;
    oct | october   )  FILE_MONTH="10" ;;
    nov | november  )  FILE_MONTH="11" ;;
    dec | december  )  FILE_MONTH="12" ;;
                   *)  FILE_MONTH="00" ;;
esac

if [[ -n "${TEST_MODE}" ]]; then 

    echo "and converted it to '${FILE_MONTH}'... "
fi

#
# Generate the date:
#
FILE_DATE=$( echo "$( echo ${FILE_DATE} | cut -d '-' -f 3 )-${FILE_MONTH}$( echo ${FILE_DATE} | cut -d '-' -f 2 )" )

if [[ -n "${TEST_MODE}" ]]; then 

    echo "Test mode: Created string '${FILE_DATE}'... "
fi

#
# If only reporting, then tell the user & stop here.
#
if [[ -z "${READ_ONLY}" ]]; then

    echo "File '${HOSTS_ZIP}' is internally dated '${FILE_DATE}'. "

    rm ${HOSTS_WIN}
    exit 2
fi

# 
# Create a date-coded versions of HOSTS:
#
HOSTS_DATED="hosts-${FILE_DATE}"

cp ${HOSTS_WIN} ${HOSTS_DATED}

# 
# Pre-qualify the use of 'sudo', so that we won't have side-effects 
# in the case where the user repeatedly fat-fingers the password (or 
# doesn't have permission in the first place).  However, if this is 
# Test Mode, we can allow it to run.
#
sudo rm -f /tmp/${HOSTS_WIN}

if [[ -f /tmp/${HOSTS_WIN} ]]; then

    if [[ -n "${TEST_MODE}" ]]; then 

        echo "Test mode: Could not remove '/tmp/${HOSTS_WIN}' file... "
    fi

    echo "${THIS_SCRIPT}: Cannot run without 'sudo' privileges. "
    exit 16
fi

#
# Change the owner and permissions to match the other 'hosts' files:
#
sudo chown root:root ${HOSTS_BLOCKING} ${HOSTS_DATED}
sudo chmod 644       ${HOSTS_BLOCKING} ${HOSTS_DATED}

# 
# Transfer the results to '/etc'
#
cd /etc

#
# Remove the old date-coded HOSTS & substitute the new one:
#
sudo rm -f hosts-2*

sudo mv /tmp/${HOSTS_BLOCKING} /tmp/${HOSTS_DATED} ./

#
# Create the new 'hosts' file by concatenating the local hosts file to the blocking file:
#
cat ${HOSTS_BASE} ${HOSTS_BLOCKING} > /tmp/hosts
sudo mv /tmp/hosts ./

# 
# Copy the resulting new 'hosts' file to replace the blocking file (now customized):
#
sudo chown root:root hosts*
sudo chmod 644 hosts*

sudo chmod 755 hosts*.sh
sudo cp -fp hosts ${HOSTS_BLOCKING}

#
# Show the results to the user:
#
ls -lF /etc/hosts /etc/hosts-*

exit

##########################################################

#
# Attach the file to the loop device as read-only (-r)
#
if [[ "${1}" == "-r" || "${1}" == "--read-only" ]]; then

    READ_ONLY=true
    shift
fi

if [[ -n "${TEST_MODE}" ]]; then

    echo -n "Test mode: File will be mounted "

    if [[ -n ${READ_ONLY} ]]; then 

        echo -n "Read-Only "
    else
        echo -n "Read-Write "
    fi
fi



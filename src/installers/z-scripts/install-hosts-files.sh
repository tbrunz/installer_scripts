#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Convert a 'hosts.zip' file into '/etc/hosts-*' files
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

### Enhancement: Modify to allow installation of HOSTS
### in a Windows partition w/ '-w' switch

FIXUP_SCRIPT="hosts-fix.sh"

HOSTS_ZIP="../hosts-files/hosts.zip"
SOURCE="canned into script"

HOSTS_WIN=HOSTS

REPLACE=true
unset ERRORS

#
# Respond to a version query (-v)
#
if [[ "${1}" == "-v" || "${1}" == "--version" ]]; then

    echo "${APP_SCRIPT}.sh, v${VERSION} "
    exit ${ERR_USAGE}
fi

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
HELP=true
if [[ "${1}" == "-r" || "${1}" == "--report"  ]]; then unset HELP; fi

if [[ "${1}" == "-i" || "${1}" == "--install" ]]; then

    unset HELP
    shift
fi

# Since the other 'install' scripts accept '-n' & '-u' to install, we will, too:
#
if [[ "${1}" == "-n" || "${1}" == "-u" ]]; then

    unset HELP
    shift
fi

if [[ ${HELP} == true ]]; then

    cat << EOF

usage: ${APP_SCRIPT} [ -t ][ -i | -r ][ <system> [<path to 'hosts.zip' file>] ]

This script does the following:
  1.) Unpacks and installs a 'winhelp2002.mvps.org' hosts.zip file
  2.) Queries a 'hosts.zip' file to determine its internal date

Options:
    -t  --test    = Run in test mode; show what is being applied
    -i  --install = Perform the installation
    -r  --report  = Report the internal date in the 'hosts.zip' file

This script will unpack and create '/etc/hosts-YYYY-MMDD' (in *nix file
format) from the 'HOSTS' file found inside the downloaded 'hosts.zip' file.

The 'hosts.zip' file is expected to be found in '../hosts-files', relative
to this script.  Once created, it will then combine this file with the
local hosts file, '/etc/hosts-<system>' (which should have only the local
IP-host definitions) to create the file '/etc/hosts-blocking'.

If <system> is not specified, it defaults to 'home'.

Finally, the script will copy '/etc/hosts-blocking' to '/etc/hosts', then
display all the '/etc/hosts-*' files for visual confirmation.

Note that this script can be run repeatedly without causing side-effects.

http://www.mvps.org/winhelp2002/hosts.htm

The hosts file contains the mappings of host names to IP addresses; the file
is loaded into memory (cache) at startup.  The system always checks the hosts
list before it queries any DNS servers for an IP number, which enables it to
override addresses in the DNS.

This can effectively prevent an application or web site from accessing any of
the listed sites if a host entry maps to an IP number that simply redirects
connection attempts back to the local machine.

As a result, you can use a hosts file to block ads, banners, third-party
cookies, third-party page counters, web bugs, and most hijackers.  This is
accomplished by blocking the connection(s) that supply this malware.

For example, the following entry, '127.0.0.1 ad.doubleclick.net', blocks all
web pages you are viewing from accessing files supplied by the DoubleClick
server.  This also prevents the server from tracking your movements.  Why?
Because in many cases, "Ad Servers" like Doubleclick (and many others) will
try silently to open a separate connection from the web page you are viewing,
record your movements, then follow you to additional sites you may visit.

In many cases, using a well-designed hosts file can speed the loading of web
pages by not having to wait for these ads, annoying banners, hit counters,
etc. to load.  This also helps to protect your privacy and security by
blocking sites that track your viewing habits, also known as  "click-thru
tracking" or Data Miners.

Simply using a hosts file is not a cure-all against all the dangers on the
Internet, but it does provide another very effective "Layer of Protection".

EOF
    exit ${ERR_USAGE}
fi

#
# Report the version of the 'hosts.zip' file (-r)
#
# Note the logic: If we're reporting, we're *not* replacing...
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
# Any other switch is an error...
#
if [[ $( echo "${1}" | cut -c 1 ) == "-" ]]; then

    echo "${APP_SCRIPT}: Switch error, '${1}' "
    exit ${ERR_BADSWITCH}
fi

#
# Verify that 'fromdos', 'zip', and 'unzip' have been installed,
# or install them if need be:
#
if [[ -n "${REPLACE}" ]]; then

    unset PKG_LIST

    RESULT=$( which fromdos )
    [[ -z "${RESULT}" ]] && PKG_LIST="tofrodos"

    RESULT=$( which zip )
    [[ -z "${RESULT}" ]] && PKG_LIST="${PKG_LIST}  zip"

    RESULT=$( which unzip )
    [[ -z "${RESULT}" ]] && PKG_LIST="${PKG_LIST}  unzip"

    if [[ -n "${PKG_LIST}" ]]; then
        QualifySudo
        sudo apt-get install -y ${PKG_LIST}
        RESULT=$?
    else
        RESULT=0
    fi

    if (( RESULT > 0 )); then
        echo "${APP_SCRIPT}: unable to install utility apps ! "
        ERRORS=true
    fi

elif [[ -n "${TEST_MODE}" ]]; then

    echo "Test mode: Found utility apps... "
fi

#
# The argument must be the suffix applied to the 'hosts' file
# that specifies the local hosts on this machine's LAN.
#
if [[ -n "${REPLACE}" ]]; then

    if [[ -z "${1}" ]]; then

        SYSTEM="base"
    else
        SYSTEM="${1}"
        shift
    fi

    HOSTS_BASE="hosts-${SYSTEM}"
    HOSTS_BLOCKING="hosts-blocking"

    if [[ -n "${TEST_MODE}" ]]; then

        echo "Test mode: Using '${HOSTS_BASE}' as the system file... "
    fi

    #
    # Verify that '/etc/hosts-<system>' file exists...
    #
    if [[ ! -r "/etc/${HOSTS_BASE}" ]]; then

        ls -lF /etc/hosts /etc/hosts-*
        echo
        echo "${APP_SCRIPT}: Can't find '/etc/${HOSTS_BASE}'! "
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
if [[ -n "${1}" ]]; then

    HOSTS_ZIP=${1}
    SOURCE="from command line"
fi

if [[ -n "${TEST_MODE}" ]]; then

    echo -n "Test mode: Using '${HOSTS_ZIP}' "
    echo    "${SOURCE} as source of 'hosts.zip' file... "
fi

#
# Verify that we can find the 'hosts.zip' file...
#
if [[ ! -r "${HOSTS_ZIP}" ]]; then

    echo "${APP_SCRIPT}: Can't find the file '${HOSTS_ZIP}'! "
    ERRORS=true

elif [[ -n "${TEST_MODE}" ]]; then

    echo "Test mode: Found 'hosts.zip' file as '${HOSTS_ZIP}'... "
fi

#
# If we encountered any errors, bail out now...
#
[[ ${ERRORS} ]] && exit ${ERR_UNSPEC}

#
# If there is an existing '/tmp/HOSTS' file present, we need to remove it,
# as the 'unzip' command will have problems otherwise.  If we can't remove
# it ourselves, then try 'sudo'.
#
if [[ -r "/tmp/${HOSTS_WIN}" && \
        $( rm -f "/tmp/${HOSTS_WIN}" 2>&1 ) && -r /tmp/${HOSTS_WIN} ]]; then

        if [[ -n "${TEST_MODE}" ]]; then
            echo "Test mode: Found pre-existing '/tmp/${HOSTS_WIN}' file. "
            echo "Attempting to remove... "
        fi

        QualifySudo
        sudo rm -f "/tmp/${HOSTS_WIN}"

        if [[ -r "/tmp/${HOSTS_WIN}" ]]; then
            echo "${APP_SCRIPT}: Could not remove '/tmp/${HOSTS_WIN}' ! "
            exit ${ERR_FILEIO}

        elif [[ -n "${TEST_MODE}" ]]; then
            echo "Test mode: Successfully removed '/tmp/${HOSTS_WIN}'... "
        fi
    fi

    #
    # Extract the HOSTS file to '/tmp/'.  Remove any pre-existing file,
    # or else the user will get an unexpected "replace?" prompt...
    #
    unzip -q "${HOSTS_ZIP}" "${HOSTS_WIN}" -d /tmp 2>&1

    if [[ ! -r "/tmp/${HOSTS_WIN}" ]]; then
        echo "${APP_SCRIPT}: Cannot unzip ${HOSTS_ZIP} ! "
        exit ${ERR_FILEIO}

    elif [[ -n "${TEST_MODE}" ]]; then
        echo -n "Test mode: Successfully unzipped ${HOSTS_ZIP} "
        echo    "into '/tmp/${HOSTS_WIN}'... "
    fi

    #
    # Before we leave the script's directory, install the corresponding fixup
    # script into the '/etc' directory (for future mods)...
    #
    if [[ -f "${FIXUP_SCRIPT}" ]]; then

        QualifySudo
        sudo cp -f "${FIXUP_SCRIPT}" /etc/

    else
        echo "${APP_SCRIPT}: Could not find '${FIXUP_SCRIPT}' ! "
    fi

    #
    # Convert and copy to make 'hosts-blocking'
    #
    cd /tmp

    if [[ -n "${REPLACE}" ]]; then

        fromdos -a -d -o "${HOSTS_WIN}"

        cat "${HOSTS_WIN}" | sed -e '/^127.*localhost/d' | \
            sed -e '/^::.*localhost/d' > "${HOSTS_BLOCKING}"

        if [[ -n "${TEST_MODE}" ]]; then

            echo -n "Test mode: Converted '${HOSTS_WIN}' from DOS format "
            echo    "& removed 'localhost' entries... "
        fi
    fi

    #
    # Extract the date from the HOSTS file
    #
    # Get the whole date string:
    #
    FILE_DATE=$( grep '[[:blank:]]*Updated:[[:blank:]]*' "${HOSTS_WIN}" | \
        cut -d ' ' -f 4 )

    if [[ -n "${TEST_MODE}" ]]; then
        echo "Test mode: Extracted '${FILE_DATE}' from '${HOSTS_WIN}' file... "
    fi

    #
    # Extract the named month & convert to 'MM' format:
    # (Note that if we can't translate it, the month goes to '00'.)
    #
    FILE_MONTH=$( printf "%s" "${FILE_DATE}" | \
        cut -d '-' -f 1 | tr '[:upper:]' '[:lower:]' )

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
    FILE_DATE=$( printf "%04d" $( printf "%s" "${FILE_DATE}" | \
      cut -d '-' -f 3 ) )-${FILE_MONTH}$( printf "%02d" \
      $( printf "%s" "${FILE_DATE}" | cut -d '-' -f 2 ) )

if [[ -n "${TEST_MODE}" ]]; then
    echo "Test mode: Created string '${FILE_DATE}'... "
fi

#
# If only reporting, then tell the user & stop here.
#
if [[ -z "${REPLACE}" ]]; then

    echo "File '${HOSTS_ZIP}' is internally dated '${FILE_DATE}'. "

    rm "${HOSTS_WIN}"
    exit 2
fi

#
# Create a date-coded versions of HOSTS:
#
HOSTS_DATED="hosts-${FILE_DATE}"

cp "${HOSTS_WIN}" "${HOSTS_DATED}"

#
# Pre-qualify the use of 'sudo', so that we won't have side-effects
# in the case where the user repeatedly fat-fingers the password (or
# doesn't have permission in the first place).  However, if this is
# Test Mode, we can allow it to run.
#
QualifySudo
sudo rm -f "/tmp/${HOSTS_WIN}"

if [[ -f "/tmp/${HOSTS_WIN}" ]]; then

    if [[ -n "${TEST_MODE}" ]]; then

        echo "Test mode: Could not remove '/tmp/${HOSTS_WIN}' file... "
    fi

    echo "${APP_SCRIPT}: Cannot run without 'sudo' privileges. "
    exit 16
fi

#
# Change the owner and permissions to match the other 'hosts' files:
#
sudo chown root.root "${HOSTS_BLOCKING}" "${HOSTS_DATED}"
sudo chmod 644       "${HOSTS_BLOCKING}" "${HOSTS_DATED}"

#
# Transfer the results to '/etc'
#
cd /etc

#
# Remove the old date-coded HOSTS & substitute the new one:
#
sudo rm -f hosts-2*

sudo mv "/tmp/${HOSTS_BLOCKING}" "/tmp/${HOSTS_DATED}" ./

#
# Create the new 'hosts' file by concatenating the local hosts file
# to the blocking file:
#
cat "${HOSTS_BASE}" "${HOSTS_BLOCKING}" > /tmp/hosts
sudo mv /tmp/hosts ./

#
# Copy the resulting new 'hosts' file to replace the blocking file
# (which is now customized):
#
sudo chown root.root hosts*
sudo chmod 644 hosts*

sudo chmod 755 hosts*.sh
sudo cp -fp hosts "${HOSTS_BLOCKING}"

#
# Show the results to the user:
#
ls -lF /etc/hosts /etc/hosts-*


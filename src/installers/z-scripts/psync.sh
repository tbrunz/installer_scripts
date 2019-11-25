#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Update a pendrive/remote host to/from a hard drive image
# ----------------------------------------------------------------------------
#

#
# $1 = 'update' | 'to' | 'from' (direction to synchronize)
#      'update' means update the image from the master image
# $2 = Path to the pendrive/remote root directory (if 'to/from')
# $x = '-n' if a dry-run of 'rsync' is desired
#    = '-d' if no '--delete' for 'rsync' is desired
#    = Port number to use, instead of the default port 22
#

# Microsoft's insane Windows clock can be off by as much as 8 hours!
MODIFY_WINDOW=28801

MASTER_ROOT=$( dirname ${0} )
MASTER_INST=${MASTER_ROOT}/installers

MASTER_YUMI=${MASTER_ROOT}/YUMI
UPDATE_YUMI=YUMI

MASTER_LINUX=${MASTER_INST}/linux
UPDATE_LINUX=linux

MASTER_SCRIPTS=${MASTER_LINUX}/z-scripts
SCRIPT_DIR=.

ERR=

DEF_PORT=22

ERR_WARNING=0
ERR_USAGE=1
ERR_NOSUDO=2
ERR_CMDFAIL=4
ERR_UNSPEC=8
ERR_FILEIO=16
ERR_MISSING=32
ERR_BADSWITCH=64


############################################################################
#
# Get the name of this script (for 'usage')
#
# $1 = Name of the calling script
# $2 = "unwind": Okay to unwind the link redirects
#
Get_Script_Name() {

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
# Throw an error
#
# $1 = Exit code (set to '0' for 'no exit')
# $2 = Name of the script throwing the error
# $3 = Name of the function/routine throwing the error (optional)
# $4 = Message string
#
Throw_Error() {

if (( $# > 3 )); then
    printf "%s: %s: error: %s \n" "${2}" "${3}" "${4}"
else
    printf "%s: error: %s \n" "${2}" "${3}"
fi

# Exit the script if the error code is not ERR_WARNING:
#
(( ${1} > ${ERR_WARNING} )) && exit
}


############################################################################
#
# Determine the OS version
#
Get_OS_Version() {

MAJOR_MINOR=$( pwd | cut -d 'a' -f 2 )

[[ -z "${MAJOR_MINOR}" ]] && MAJOR_MINOR=1310
}


############################################################################
#
# Massage the 'excludes' list to add "--exclude=" to each item
#
Make_Excludes() {

# The FILES directory is for temporary/personal items on the thumb drive;
# 'System Volume Information' is a system folder for NTFS formats;
# 'ldlinux.sys' files are custom-generated for specific thumb drives!
# 'z*gb' files are markers to identify a thumb drive from its contents;

EXCLUDES=(
	"FILES"
	"\"System Volume Information\""
    ".git"
    ".gitignore"
    "ldlinux.sys"
	"z*gb"
	".fuse_hidden*"
)

local EXCLUDES_IDX

local NUM_EXCLUDES=${#EXCLUDES[@]}

if (( NUM_EXCLUDES > 0 )); then

    for (( EXCLUDES_IDX=--NUM_EXCLUDES; EXCLUDES_IDX>=0; EXCLUDES_IDX-- )); do

        EXCLUDES[$EXCLUDES_IDX]="--exclude=${EXCLUDES[$EXCLUDES_IDX]}"
    done
fi
}


############################################################################
#
# Massage the 'includes' list to add "--include=" to each item
#
Make_Includes() {

# If the '-m' switch is provided, then include personal files in FILES;

INCLUDES=(
#        "extras-${MAJOR_MINOR}32"
#        "extras-${MAJOR_MINOR}64"
    )

local INCLUDES_IDX

local NUM_INCLUDES=${#INCLUDES[@]}

if (( NUM_INCLUDES > 0 )); then

    for (( INCLUDES_IDX=--NUM_INCLUDES; INCLUDES_IDX>=0; INCLUDES_IDX-- )); do

        INCLUDES[$INCLUDES_IDX]="--include=${INCLUDES[$INCLUDES_IDX]}"
    done
fi
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
Get_YesNo_Defaulted() {

local PROMPT

case ${1,,} in
y)
    PROMPT=${2}" [Y/n] "
    ;;
n)
    PROMPT=${2}" [y/N] "
    ;;
*)
    PROMPT=${2}" "
    ;;
esac

unset REPLY
while [[ ${REPLY} != "y" && ${REPLY} != "n" ]]; do

    read -e -r -p "${PROMPT}"
    [[ -z "${REPLY}" ]] && REPLY=${1,,}

    REPLY=${REPLY:0:1} && REPLY=${REPLY,,}
done

[[ ${REPLY} == "y" ]] && return
}


############################################################################
############################################################################
#
# Determine what/how to sync
#
Get_Script_Name "${0}"
Get_OS_Version

SCRIPT=$( basename "${0}" )

DIRECTION=${1}
shift

PENDRV_DIR=${1}
shift

# Check the integrity of the respository:
#
if [[ ! -d "${MASTER_SCRIPTS}" ]]; then

    echo 1>&2 "error: Cannot find the '${MASTER_SCRIPTS}' directory ! "
    exit ${ERR_MISSING}
fi

# First, qualify the 'direction' argument:
#
if [[ ${DIRECTION} == "update" ]]; then

    PENDRV_DIR=${MASTER_LINUX}

    if [[ ! -d "${UPDATE_LINUX}" ]]; then
        echo 1>&2 "error: Must run updates from the target image directory ! "
        exit ${ERR_USAGE}
    fi

elif [[ ${DIRECTION} != "to" && ${DIRECTION} != "from" ]]; then

    # Any unrecognized (or missing) 'command' is a error:
    #
    ERR=true
fi

# Second, if there's no 'pendrive' argument, we have an error:
#
[[ -z "${PENDRV_DIR}" ]] && ERR=true

# Third, there may be a port number or switch arguments at the end...
#
# If there are no arguments, then set the defaults:
#
DELETE="--delete"
MY_FILES="--exclude=Z-FILES"
PORT_NUM=
DRY_RUN=
QUIET="2>&1 | grep -v '/$'"
NO_ERR=" | grep -v 'rsync: failed to set times'"

# While there are arguments on the CLI, parse them:
#
while [[ -n "${1}" ]]; do

    getopts ":cmnve" SWITCH

    if [[ $? != 0 ]]; then

        # If not a switch, then it MUST be a port number...
        # (It had better not be just a '-', though; Check below.)
        #
        if [[ -z "${PORT_NUM}" ]]; then
            PORT_NUM=${1}
            shift
            OPTIND=1
        else
            # However, a second non-switch is a screw-up:
            ERR=true
            shift
            OPTIND=1
        fi

    elif [[ ${SWITCH} == "?" ]]; then

        # It's a switch, but it's not one we recognize...
        #
        ERR=true
        shift
        OPTIND=1
    else
        case ${SWITCH} in
        "c")
            DELETE=""
            ;;
        "m")
            MY_FILES=""
            ;;
        "n")
            DRY_RUN="-n"
            ;;
        "v")
            QUIET=
            ;;
        "e")
            NO_ERR=
            ;;
        *)
            echo 1>&2 "error: Internal error parsing the CLI ! "
            exit ${ERR_UNSPEC}
            ;;
        esac
        shift
        OPTIND=1
    fi
done

# Default the port number if nothing was read for port number.
# Here's where we check to see if a bare '-' was entered.
#
if [[ -z "${PORT_NUM}" ]]; then PORT_NUM=${DEF_PORT}

elif [[ "${PORT_NUM:0:1}" == '-' ]]; then ERR=true

elif [[ ! "${PORT_NUM}" =~ ^[0-9]+$ ]]; then ERR=true

elif (( PORT_NUM == DEF_PORT )); then unset ERR

elif (( PORT_NUM < 1024 && PORT_NUM > 65534 )); then ERR=true
fi

# For any error occurring above, throw the 'usage' prompt & quit:
#
if [[ ${ERR} == true ]]; then

    echo 1>&2 -n "usage: ${SCRIPT} [ update | "
    echo 1>&2    "[ to | from [[<user>@]host:]<dir> ] [-n] [-c] [-m] [<port>] "
    exit ${ERR_USAGE}
fi

# If the CLI parameter is not a remote URI, then it must exist locally:
#
REMOTE="n"
LOCAL_DIR=$( printf %s "${PENDRV_DIR}" | cut -d ':' -f 1 )
REMOTE_DIR=$( printf %s "${PENDRV_DIR}" | cut -d ':' -s -f 1 )

if [[ ! -d "${LOCAL_DIR}" ]]; then    # Must be a remote...

    if [[ -z "${REMOTE_DIR}" ]]; then  # ...But it isn't! (it has no ':' char)

        echo 1>&2 "error: Can't find '${DIRECTION}' directory '${PENDRV_DIR}' ! "
        exit ${ERR_FILEIO}
    fi
    #
    # Don't bother testing the remote if we're doing a dry run:
    #
    [[ -z "${DRY_RUN}" ]] && REMOTE="y"
    REMOTE="n" # Was not that useful, so make it always default to 'n'
fi

# Can't run this script using a 'relative' path to the script!
#
if [[ ! -e "${SCRIPT_DIR}/${SCRIPT}" ]]; then
    echo 1>&2 -n "error: Must run this script from "
    echo 1>&2    "the directory containing '${SCRIPT}' ! "
    exit ${ERR_USAGE}
fi

# Create the variables for 'rsync'
#
if [[ ${DIRECTION} == "to" ]]; then
    SRC_DIR=${SCRIPT_DIR}
    DST_DIR=${PENDRV_DIR}

elif [[ ${DIRECTION} == "from" ]]; then
    SRC_DIR=${PENDRV_DIR}
    DST_DIR=${SCRIPT_DIR}
fi

# Make excludes & includes for the 'rsync' command:
#
Make_Excludes
Make_Includes

# At this point, we're ready to synchronize:
#
RSYNC_ARGS="-rltDuvxP ${MY_FILES}"
RSYNC_ARGS="${RSYNC_ARGS} ${DRY_RUN} ${DELETE}"
RSYNC_ARGS="${RSYNC_ARGS} --modify-window=${MODIFY_WINDOW}"
RSYNC_ARGS="${RSYNC_ARGS} --rsh='ssh -p ${PORT_NUM}'"
RSYNC_ARGS="${RSYNC_ARGS} ${SRC_DIR}/ ${DST_DIR}/"
RSYNC_ARGS="${RSYNC_ARGS} ${QUIET} ${NO_ERR}"

# Debug: Print out the command & quit:
#
: <<'COMMENT'
echo
echo "Ready to execute: "
echo "rsync "${EXCLUDES[@]}" "${INCLUDES[@]}" "${RSYNC_ARGS}
echo
exit
COMMENT

# Do the 'rsync'
#
ERR=false

if [[ ${DIRECTION} != "update" ]]; then

    # The remote path must have our script in it, else it's not valid:
    #
    Get_YesNo_Defaulted "${REMOTE}" "Test the other directory?"
    if (( $? == 0 )); then

        echo 1>&2 "...Testing the other directory..."

        rm -rf "/tmp/${SCRIPT}"

        scp -q -P ${PORT_NUM} "${PENDRV_DIR}/${SCRIPT}" /tmp/ 2>/dev/null

        [[ -e "/tmp/${SCRIPT}" ]] || ERR=true

        rm -rf "/tmp/${SCRIPT}"

        if [[ ${ERR} == true ]]; then

            echo 1>&2 "error: Cannot find '${PENDRV_DIR}/${SCRIPT}' ! "
            exit ${ERR_FILEIO}
        fi
        echo 1>&2 "...Test successful..."
        sleep 1
    fi

    eval rsync "${EXCLUDES[@]}" "${INCLUDES[@]}" "${RSYNC_ARGS}"

    exit $?
fi

#
# Here ONLY if the 'direction' argument == "update" (i.e., 4GB thumbdrive):
#

# Sync the YUMI directory...
#
rsync -rltDuvxP ${DRY_RUN} ${DELETE} --modify-window=${MODIFY_WINDOW} \
        ${MASTER_YUMI}/ ${UPDATE_YUMI}/ | grep -v '/$'

# Sync the Linux directory...
#
rsync "${INCLUDES[@]}" "${EXCLUDES[@]}" --filter=._- -rltDuvxP \
        ${DRY_RUN} ${DELETE} --modify-window=${MODIFY_WINDOW} \
        ${MASTER_LINUX}/ ${UPDATE_LINUX}/ << '__FILTERS' | grep -v '/$'
- .git*
- archive
- cygwin.zip
- drivers
- fonts/*.tgz
- fonts/*.zip
- google-talk
- hp15c/*.dmg
- libreoffice
- linux-kernel
- modelio
- picasa
- skype
- trac-svn/books
- Oracle*Extension_Pack*vbox-extpack
- vagrant
- virtualbox*deb
- virtualbox-tools
- vmware-player
__FILTERS

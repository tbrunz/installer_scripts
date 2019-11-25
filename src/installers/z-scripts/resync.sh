#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Synchronize a repository to a pendrive / other directory
# ----------------------------------------------------------------------------
#

declare -A MEDIA_DATA
declare -A REPO_DATA
declare -A SIZE_DATA
declare -A SYNC_DATA

ROOT_NAME="MULTIBOOT"

NUM_MEDIA=0
MEDIA_DATA=(
)

NUM_REPOS=0
REPO_DATA=(
    [1,size]=4   [1,name]="${ROOT_NAME}_4"   [1,path]=""
    [2,size]=64  [2,name]="${ROOT_NAME}_64"  [2,path]=""
)

EXCLUDES=(
    "System Volume Information"
    "FILES"
)

NUM_SIZES=0
SIZE_DATA=(
    [1,size]=0    [1,blocks]=480000
    [2,size]=1    [2,blocks]=900000
    [3,size]=2    [3,blocks]=1800000
    [4,size]=4    [4,blocks]=3500000
    [5,size]=8    [5,blocks]=7000000
    [6,size]=16   [6,blocks]=14000000
    [7,size]=32   [7,blocks]=30000000
    [8,size]=64   [8,blocks]=60000000
    [9,size]=128  [9,blocks]=120000000
    [10,size]=256 [10,blocks]=240000000
)

NUM_SYNCS=0
SYNC_DATA=(
)

RSYNC_OPTIONS="-auvx --modify-window=1"
DRY_RUN="-n"
DELETE_FLAG="--delete"

HOME_DIR="/home"
MEDIA_DIR="/media"


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

ARCH=$( uname -m )

DISTRO=$( grep CODENAME /etc/lsb-release | cut -d = -f 2 )
RELEASE=$( grep RELEASE /etc/lsb-release | cut -d = -f 2 )

MAJOR=$( printf %s ${RELEASE} | cut -d . -f 1 )
MINOR=$( printf %s ${RELEASE} | cut -d . -f 2 )

MEDIA_SUB=$( whoami )
(( MAJOR < 12 || (MAJOR == 12 && MINOR < 7) )) && MEDIA_SUB=""

[[ -n "${ARCH}" && -n "${DISTRO}" && -n "${RELEASE}" && \
        -n "${MAJOR}" && -n "${MINOR}" ]] && return

Throw_Error "${ERR_UNSPEC}" "${CORE_SCRIPT}" "${FUNCNAME}" \
        "Could not resolve OS version value !"
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
# Resolve a path string into an absolute pathname
#
# $1 = Path to resolve
#
# Returns the resolved path in ${ABS_PATH}
#
Resolve_Path() {

# Chop off any trailing '/' character:
#
if [[ $( printf %s "${1}" | rev | cut -c 1 ) == "/" ]]; then

    ABS_PATH=$( printf %s "${1}" | rev | cut -c 2- | rev )
else
    ABS_PATH=${1}
fi

# The path given may be a soft-linked path -- try to resolve it:
#
[[ -n "$( readlink -- "${ABS_PATH}" )" ]] && \
                        ABS_PATH=$( readlink -- "${ABS_PATH}" )

# If the first character starts with '.', then we need to resolve it:
#
if [[ $( printf %s "${ABS_PATH}" | cut -c 1 ) == "." ]]; then

    pushd "${1}" 2>/dev/null 1>&2
    (( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
            "Cannot change directory to '${1}' !"

    ABS_PATH=$( pwd )

    popd 2>/dev/null 1>&2
    (( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
            "Cannot return to original directory from '${1}' !"
fi
}


############################################################################
#
# Determine if the target is local; if so, qualify it
#
# $1 = candidate local or remote path
#
Qualify_Path() {

RESULT=$( printf %s "${1}" | egrep '^[^@]+@[^:]+:' )
[[ -n "${RESULT}" ]] && return

RESULT=$( printf %s "${1}" | egrep '^[^:]+:' )
[[ -n "${RESULT}" ]] && return

[[ -e "${1}" ]] && return

Throw_Error "${ERR_USAGE}" "${APP_SCRIPT}" \
        "Could not find '${1}' in the filesystem ! "
}


############################################################################
#
# Find pendrives mounted in the filesystem, and build a database of them
#
Find_Pendrives() {

local MEDIA_BLOCKS
local MEDIA_PATH
local MEDIA_SIZE
local SIZE_IDX

NUM_MEDIA=0

# Generate an array of media sizes & paths -- there may be more than one:
#
while read -r _ MEDIA_BLOCKS _ _ _ MEDIA_PATH; do
    #
    # Build a list for each matching path; For each matching path, find the
    # media size whose block count 'matches' that of the media for the path;
    # Do this by checking progressively larger media sizes until 'overflow':
    #
    for (( SIZE_IDX=1; SIZE_DATA[${SIZE_IDX},blocks] > 0; SIZE_IDX++ )); do

        if (( MEDIA_BLOCKS > SIZE_DATA[${SIZE_IDX},blocks] )); then

            MEDIA_SIZE=${SIZE_DATA[${SIZE_IDX},size]}
            (( SIZE_IDX > NUM_SIZES )) && NUM_SIZES=${SIZE_IDX}
        fi
    done

    # Check the size of the matching media; if it's too small, reject it:
    #
    if (( MEDIA_SIZE > 0 )); then

        (( NUM_MEDIA++ ))
        MEDIA_DATA[${NUM_MEDIA},size]=${MEDIA_SIZE}
        MEDIA_DATA[${NUM_MEDIA},path]=${MEDIA_PATH}
    fi

done < <( df | grep ${ROOT_NAME} )
}


############################################################################
#
# Find repositories in the filesystem, and build a database of them
#
Find_Repos() {

local REPO_IDX

#####################
#
# FIX ME: The while-read/done-find command should use /x00 to separate the
#         matching paths found; Need to handle the case where no matching
#         directories are found in the filesystem; Run the 'find' command
#         ahead of the while-read loop, as two (or more--make it extensible)
#         separate 'find' commands, then combine the resulting strings to
#         feed the 'done' of the 'while' loop; Echo the paths that are being
#         searched, as they're being searched...
#
#####################

# For each type of repository, search the filesystem for a path to it:
#
for (( REPO_IDX=1; REPO_DATA[${REPO_IDX},size] > 0; REPO_IDX++ )); do

    local NUM_PATHS
    local PATH_LIST=()

    # Generate an array of matching paths -- there may be more than one.
    # Note: This technique is the only safe way of doing this...
    #
    while read -r REPO_PATH; do

        # Build a list of each matching path:
        #
        PATH_LIST+=( "${REPO_PATH}" )

    done < <( find {"${HOME_DIR}","${MEDIA_DIR}"}/"${MEDIA_SUB}" \
        -maxdepth 4 -type d -name "${REPO_DATA[${REPO_IDX},name]}" )

    # How many did we get?  Any result other than '1' is a problem...
    #
    NUM_PATHS=${#PATH_LIST[@]}

    (( ${NUM_PATHS} < 1 )) && Throw_Error "${ERR_USAGE}" "${APP_SCRIPT}" \
        "Could not find any repositories in the filesystem ! "

    (( ${NUM_PATHS} > 1 )) && Throw_Error "${ERR_USAGE}" "${APP_SCRIPT}" \
        "Found ${NUM_PATHS} instances of '${REPO_PATH}' in the filesystem ! "

    # We did get the single path we expected -- Save it in the database:
    #
    (( NUM_REPOS++ ))
    REPO_DATA[${REPO_IDX},path]=${PATH_LIST}
    REPO_DATA[${REPO_DATA[${REPO_IDX},size]}]=${PATH_LIST}
done
}


############################################################################
#
# Find the largest repository (by media size) on the system
#
Find_Largest_Repo() {

local SIZE_IDX
local REPO_IDX

# Start with the largest size of repo/pendrive and work towards the smallest:
#
for (( SIZE_IDX=NUM_SIZES; SIZE_IDX > 1; SIZE_IDX-- )); do

    # Scan all repos to find the one with this size:
    #
    for (( REPO_IDX=NUM_REPOS; REPO_IDX > 0; REPO_IDX-- )); do

        # Assume that this will be "The One"...
        #
        LARGEST_SIZE=${REPO_DATA[${REPO_IDX},size]}
        LARGEST_PATH=${REPO_DATA[${REPO_IDX},path]}
        LARGEST_INDEX=${SIZE_IDX}

        (( SIZE_DATA[${SIZE_IDX},size] == LARGEST_SIZE )) && return
    done
done

# Could not find a repo matching any of the sizes!
#
LARGEST_SIZE=0
LARGEST_PATH=""
LARGEST_INDEX=0
}


############################################################################
#
# Generate a list of every repo combined with the largest repo
#
Find_RepoRepo_Combos() {

local REPO_IDX

# Scan all repos to find those smaller than the largest repo:
#
for (( REPO_IDX=NUM_REPOS; REPO_IDX > 0; REPO_IDX-- )); do

    if (( REPO_DATA[${REPO_IDX},size] < LARGEST_SIZE )); then
        #
        # Save each pair of 'biggest repo path'/'repo path':
        #
        (( NUM_SYNCS++ ))

        SYNC_DATA[${NUM_SYNCS},type]="repo-repo"
        SYNC_DATA[${NUM_SYNCS},size]=${LARGEST_SIZE}

        SYNC_DATA[${NUM_SYNCS},source]=${LARGEST_PATH}
        SYNC_DATA[${NUM_SYNCS},src-type]="repo"

        SYNC_DATA[${NUM_SYNCS},dest]=${REPO_DATA[${REPO_IDX},path]}
        SYNC_DATA[${NUM_SYNCS},dst-type]="repo"
    fi
done
}


############################################################################
#
# Generate a list of every compatible repo-pendrive combination
#
# $1 = Size (in GB) of combinations to add to list
#
Find_RepoMedia_Combos() {

local TARGET_SIZE=${1}
local REPO_IDX
local MEDIA_IDX

# Scan all repos to find the one with this size:
#
for (( REPO_IDX=NUM_REPOS; REPO_IDX > 0; REPO_IDX-- )); do

    if (( REPO_DATA[${REPO_IDX},size] == TARGET_SIZE )); then

        # For this size repo, scan all media to find those with the same size:
        #
        for (( MEDIA_IDX=NUM_MEDIA; MEDIA_IDX > 0; MEDIA_IDX-- )); do

            if (( MEDIA_DATA[${MEDIA_IDX},size] == TARGET_SIZE )); then
                #
                # Save each pair of 'repo path'/'media path' of the same size:
                #
                (( NUM_SYNCS++ ))

                SYNC_DATA[${NUM_SYNCS},type]="repo-media"
                SYNC_DATA[${NUM_SYNCS},size]=${TARGET_SIZE}

                SYNC_DATA[${NUM_SYNCS},source]=${REPO_DATA[${REPO_IDX},path]}
                SYNC_DATA[${NUM_SYNCS},src-type]="repo"

                SYNC_DATA[${NUM_SYNCS},dest]=${MEDIA_DATA[${MEDIA_IDX},path]}
                SYNC_DATA[${NUM_SYNCS},dst-type]="media"
            fi
        done
    fi
done
}


############################################################################
#
# Generate a list of every compatible repo-pendrive combination;
# include any repo-repo combos that include the largest repo
#
Make_Full_Sync_List() {

local SIZE_IDX

# First, find the largest repository in the system;
# (All edits & changes should be made to this 'Master Copy'...)
#
Find_Largest_Repo
(( LARGEST_SIZE == 0 )) && Throw_Error "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Could not find any repositories in the filesystem ! "

# Next, sync the largest repo with any media of its size;
# (I.e., if any repo changes are being imported on a big pendrive, sync them)
#
NUM_SYNCS=0
Find_RepoMedia_Combos ${LARGEST_SIZE}

# Next, update the smaller repos with any changes from the Master repo:
#
Find_RepoRepo_Combos

# Now sync all the smaller repos with their respective media;
# Start with the largest size of repo/pendrive and work towards the smallest:
#
for (( SIZE_IDX=--LARGEST_INDEX; SIZE_IDX > 1; SIZE_IDX-- )); do
    #
    # Find all repo-pendrive combinations that match this size:
    #
    Find_RepoMedia_Combos ${SIZE_DATA[${SIZE_IDX},size]}
done
}


############################################################################
#
# Find all compatible media, and choose one
#
# $1 = Size of media to match
#
Choose_Media() {

local MEDIA_IDX
local PATH_LIST=()

# Generate an array of media paths matching the size -- may be more than one:
#
for (( MEDIA_IDX=1; MEDIA_DATA[${MEDIA_IDX},size] > 0; MEDIA_IDX++ )); do

    # Build a list for each matching path:
    #
    if (( MEDIA_DATA[${MEDIA_IDX},size] == ${1} )); then

        PATH_LIST+=( ${MEDIA_DATA[${MEDIA_IDX},path]} )
    fi
done

# If no matches, then return '0', which will cause an error trap downstream;
#
MEDIA_CHOICE=""
(( ${#PATH_LIST[@]} == 0 )) && return

# If one match, then that's our choice (no need to add an index to de-ref):
#
MEDIA_CHOICE=${PATH_LIST}
(( ${#PATH_LIST[@]} == 1 )) && return

# Else we have to ask the user to make a choice for us:
#
echo "There is more than one compatible media that can sync with this repo; "
echo "Please choose one from the list below (or <Ctrl>-D to cancel): "

select MEDIA_CHOICE in "${PATH_LIST[@]}"; do

    [[ -n "${MEDIA_CHOICE}" ]] && break

    echo "Er, you gotta choose one, please... "
done
}


############################################################################
#
# Try to match a given path with one of the repo or media paths
#
# $1 = Path to match against repo & media paths
#
# Returns ${TYPE_MATCH}, ${PATH_MATCH}, and ${SIZE_MATCH},
# where all three values are <null> if no match is found.
#
Match_Path_to_RepoMedia() {

local PATH_IDX

TYPE_MATCH=""
PATH_MATCH=""
SIZE_MATCH=0

# The PWD might have been reached from a symlink; if so, this will cause
# problems with matching paths, so first try to resolve the link:
#
RESOLVED_PATH=$( readlink -- "${1}" )
[[ -z "${RESOLVED_PATH}" ]] && RESOLVED_PATH=${1}

# For each media path, try to match to the PWD:
#
for (( PATH_IDX=1; PATH_IDX <= NUM_MEDIA; PATH_IDX++ )); do

    if [[ ${MEDIA_DATA[${PATH_IDX},path]} == "${RESOLVED_PATH}" ]]; then

        TYPE_MATCH="media"
        PATH_MATCH=${MEDIA_DATA[${PATH_IDX},path]}
        SIZE_MATCH=${MEDIA_DATA[${PATH_IDX},size]}
        return
    fi
done

# For each repo path, try to match to the PWD:
#
for (( PATH_IDX=1; REPO_DATA[${PATH_IDX},size] > 0; PATH_IDX++ )); do

    if [[ ${REPO_DATA[${PATH_IDX},path]} == "${RESOLVED_PATH}" ]]; then

        TYPE_MATCH="repo"
        PATH_MATCH=${REPO_DATA[${PATH_IDX},path]}
        SIZE_MATCH=${REPO_DATA[${PATH_IDX},size]}
        return
    fi
done
}


############################################################################
#
# Perform a full 'rsync' without an excludes list
#
# $1 = source
# $2 = destination
# $3 = options list
#
Sync_Full() {

local SOURCE=${1}
shift

local DEST=${1}
shift

rsync ${RSYNC_OPTIONS} "$@" "${SOURCE}" "${DEST}" | grep -v '/$'
}


############################################################################
#
# Perform an 'rsync' with an excludes list suitable for a 4GB pendrive
#
# $1 = source
# $2 = destination
# $3 = options list
#
Sync_4GB() {

local SOURCE=${1}
shift

local DEST=${1}
shift

rsync --filter=._- ${RSYNC_OPTIONS} "$@" "${SOURCE}" "${DEST}" <<'EO_SYNC_4GB'
- drivers
- fonts/*.tgz
- fonts/*.zip
- google-talk
- hp15c/*.dmg
- linux-kernel
- picasa
- skype
- trac-svn/books
- unison
- virtualbox-tools
- vmware-player
- xmodulo
EO_SYNC_4GB
}


############################################################################
#
# Massage the 'excludes' list to add "--exclude=" to each item
#
Make_Excludes() {

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
# Display a menu of sync choices and get the user's selection
#
Get_Sync_Choice() {

local SYNC_CHOICE

# Throw up a menu with the combinations of how we can sync the two directories:
#
echo
echo "Please pick one of the following 'rsync' options, or <Ctrl>-D to cancel: "
echo "(Note that this will be a dry-run sync; no changes will be applied) "
echo
select SYNC_CHOICE in "${SYNC_OPTIONS[@]}"; do

    [[ -n "${SYNC_CHOICE}" ]] && break

    echo "Just pick one of the listed options, okay? "
done

# If the user cancelled with <Ctrl>-D, then ${SYNC_CHOICE} will return null:
#
if [[ -z "${SYNC_CHOICE}" ]]; then
    echo "Cancelling..."
    return
fi

# Otherwise, continue: Carry out the selected synchronization...
#
case ${SYNC_CHOICE} in
"${DISPLAY_A} to ${DISPLAY_B}, no deletes")
    Sync_Full "${PATH_A}" "${PATH_B}" "-n" "${EXCLUDES[@]}"
    ;;
"${DISPLAY_A} to ${DISPLAY_B}, w/ --delete")
    Sync_Full "${PATH_A}" "${PATH_B}" "-n" "${EXCLUDES[@]}" "--delete"
    ;;
"${DISPLAY_B} to ${DISPLAY_A}, no deletes")
    Sync_Full "${PATH_B}" "${PATH_A}" "-n" "${EXCLUDES[@]}"
    ;;
"${DISPLAY_B} to ${DISPLAY_A}, w/ --delete")
    Sync_Full "${PATH_B}" "${PATH_A}" "-n" "${EXCLUDES[@]}" "--delete"
    ;;
*)
    Throw_Error "${ERR_CMD}" "${APP_SCRIPT}" \
        "Trying to execute an invalid sync case, '${SYNC_CHOICE}' ! "
    ;;
esac
}


############################################################################
#
# Synchronize one pair of paths
#
# $1 = SYNC_IDX

Synchronize() {

local SYNC_IDX=${1}

local -A SYNC_OPTIONS

local PATH_A=${SYNC_DATA[${SYNC_IDX},source]}/
local PATH_B=${SYNC_DATA[${SYNC_IDX},dest]}/

local DISPLAY_A="'$( basename ${PATH_A} )' (${SYNC_DATA[${SYNC_IDX},src-type]})"
local DISPLAY_B="'$( basename ${PATH_B} )' (${SYNC_DATA[${SYNC_IDX},dst-type]})"

#echo
#echo "*** Synchronizing '${PATH_A}' and '${PATH_B}' *** "
#echo

SYNC_OPTIONS=(
    [A,B,preserve]="${DISPLAY_A} to ${DISPLAY_B}, no deletes"
    [A,B,delete]="${DISPLAY_A} to ${DISPLAY_B}, w/ --delete"
    [B,A,preserve]="${DISPLAY_B} to ${DISPLAY_A}, no deletes"
    [B,A,delete]="${DISPLAY_B} to ${DISPLAY_A}, w/ --delete"
)

Get_Sync_Choice
}


############################################################################
#
# Make a 'usage' prompt:
#
Make_Usage() {

USAGE="
usage: ${APP_SCRIPT} [ -a | -p | -d <size> | <dir> | <src> <dest> ]

This script performs a two-way synchronization between a file repository and
a target directory.  The target directory may be an arbitrary directory, a
mounted thumbdrive/external drive, or a remote filesystem.

Options:
    -a = Auto synchronization of all repos & media on system
    -p = Automatically find matching repo or media for PWD
    -d = Sync just the media matching a given size

The '${APP_SCRIPT}' script can synchronize a specified directory tree with
another directory:

    ${APP_SCRIPT} <src-dir> <dest-dir>

or with a remote directory:

    ${APP_SCRIPT} <src-dir> <[user@]remote-host:dest-dir>
    ${APP_SCRIPT} <[user@]remote-host:src-dir> <dest-dir>

or synchronize a given directory with the PWD or with repo/media that matches:

    ${APP_SCRIPT} <dest-dir>
    ${APP_SCRIPT} <[user@]remote-host:dest-dir>

or automatically synchronize the PWD with repo/media that matches:

    ${APP_SCRIPT} -p

or find and synchronize all repository/media combinations:

    ${APP_SCRIPT} -a

or synchronize just the repository & media matching a given size:

    ${APP_SCRIPT} -d <size, in GB>

The script will do a heroic job of automatically finding and matching up the
correct repositories & mounted media (whose mount names match the repo name).

In each case, each synchronization will perform a dry-run for a selected sync
direction, with or without '--delete' enabled.  It will then prompt to run the
same sync operation again 'live' (or the user can elect to skip the sync
operation altogether).

'Full' synchronizations will first sync the largest repo with mounted media of
the same size, then 'update' smaller repos to be in sync with the largest,
then attempt to sync the smaller repos with mounted media of equivalent size.

(Updating the smaller repos is done using additional '--exclude' arguments
applied to 'rsync').
"
}

############################################################################
#
# Throw an error: The user is trying to sync a directory with itself...
#
Self_Sync_Err() {

Throw_Error "${ERR_USAGE}" "${APP_SCRIPT}" \
        "You're asking to sync a directory to itself ! "
}


############################################################################
#
# APPLICATION STARTS HERE
#
Get_Script_Name "${0}"
Get_OS_Version

Make_Usage
Make_Excludes

# Determine what our parameters/options are -> operating mode:
#
if [[ -z "${1}" ]]; then
    echo "${USAGE}"
    exit
fi

if [[ ${1} == "-a" ]]; then
    #
    # Generate paths automatically, and sync all valid sets:
    # * 64GB repo to each 64GB pendrive
    # * Update 4GB repo
    # * 4GB repo to each 4GB pendrive
    #
    Find_Repos
    Find_Pendrives
    Make_Full_Sync_List

elif [[ ${1} == "-d" ]]; then
    #
    # Generate paths automatically to match this size pendrive:
    #
    Find_Repos
    Find_Pendrives

    # Find all repo-pendrive combinations that match this size:
    #
    NUM_SYNCS=0
    Find_RepoMedia_Combos ${2}

    (( NUM_SYNCS == 0 )) && Throw_Error "${ERR_USAGE}" "${APP_SCRIPT}" \
            "Could not find any ${2} GB repos/media in the filesystem ! "

elif [[ ${1} == "-p" ]]; then
    #
    # Generate paths automatically, using the PWD as a guide:
    #
    Find_Repos
    Find_Pendrives
    Match_Path_to_RepoMedia "${PWD}"

    # Set defaults for this case; will be over-written if '-f' is chosen:
    #
    NUM_SYNCS=1
    SYNC_DATA[${NUM_SYNCS},type]="repo-media"
    SYNC_DATA[${NUM_SYNCS},size]=${SIZE_MATCH}

    # Now see what we were able to match for the PWD:
    #
    case ${TYPE_MATCH} in
    "repo")
        # I'm in a repo directory... How many media paths match me?  Choose:
        #
        Choose_Media ${SIZE_MATCH}

        SYNC_DATA[1,source]=${RESOLVED_PATH}
        SYNC_DATA[1,src-type]="repo"

        SYNC_DATA[1,dest]=${MEDIA_CHOICE}
        SYNC_DATA[1,dst-type]="media"
        ;;
    "media")
        # I'm in a media directory, so there's only one repo that matches:
        #
        SYNC_DATA[1,source]=${PATH_MATCH}
        SYNC_DATA[1,src-type]="repo"

        SYNC_DATA[1,dest]=${RESOLVED_PATH}
        SYNC_DATA[1,dst-type]="media"
        ;;
    *)
        # I'm not in a repo or media directory, maybe do an '-f' sync instead?
        #
        Get_YesNo_Defaulted "n" \
                "Not sure what you want to do...  How about a full sync?"

        if (( $? == 0 )); then
            Make_Full_Sync_List
        else
            NUM_SYNCS=0
        fi
        ;;
    esac

else
    # Non-auto mode -- at least one path is required:
    #
    SOURCE_TYPE="file"
    DEST_TYPE="file"

    if [[ -n "${1}" ]]; then

        Resolve_Path "${1}"
        Qualify_Path ${ABS_PATH}
        SOURCE_DIR=${ABS_PATH}

    else
        Throw_Error "${ERR_USAGE}" "${APP_SCRIPT}" \
            "Need to provide at least one path to sync! (use '-f' or '-a' ?) "
    fi

    # Check to see if a second path has been provided:
    #
    if [[ -n "${2}" ]]; then

        Resolve_Path "${2}"
        Qualify_Path ${ABS_PATH}
        DEST_DIR=${ABS_PATH}

        [[ ${SOURCE_DIR} == "${DEST_DIR}" ]] && Self_Sync_Err

   else
        # One path (only) given -- Generate the second path automatically:
        #
        Find_Repos
        Find_Pendrives

        # Resolve & type the (provided) source directory:
        #
        Match_Path_to_RepoMedia "${SOURCE_DIR}"
        SOURCE_TYPE="${TYPE_MATCH}"
        SOURCE_DIR="${RESOLVED_PATH}"

        # Resolve & type the PWD as the destination directory:
        #
        Match_Path_to_RepoMedia "${PWD}"
        DEST_TYPE="${TYPE_MATCH}"
        DEST_DIR="${RESOLVED_PATH}"

        # Are they the same?  If so, ::face palm::
        #
        [[ ${SOURCE_DIR} == "${DEST_DIR}" ]] && Self_Sync_Err
    fi

    # Non-auto mode creates ${SOURCE_DIR} & ${DEST_DIR}; make a one-item list:
    #
    NUM_SYNCS=1

    SYNC_DATA[1,source]=${SOURCE_DIR}
    SYNC_DATA[1,src-type]="path"

    SYNC_DATA[1,dest]=${DEST_DIR}
    SYNC_DATA[1,dst-type]="path"

    SYNC_DATA[${NUM_SYNCS},type]="file"
    SYNC_DATA[${NUM_SYNCS},size]=0

    if [[ ${SOURCE_TYPE} == "repo" && ${DEST_TYPE} == "repo" ]]; then

        SYNC_DATA[1,src-type]="repo"
        SYNC_DATA[1,dst-type]="repo"
        SYNC_DATA[${NUM_SYNCS},type]="repo-repo"
    fi
fi

# Is there anything to do at this point?
#
if (( NUM_SYNCS == 0 )); then

    echo "Nothing to sync ! "
    exit
fi

# For debugging purposes:
echo
echo "Ready to sync the following: "

for (( SYNC_IDX=1; SYNC_IDX <= NUM_SYNCS; SYNC_IDX++ )); do

    echo -n "  ${SYNC_DATA[${SYNC_IDX},type]} type: "
    echo -n "'${SYNC_DATA[${SYNC_IDX},source]}' to "
    echo    "'${SYNC_DATA[${SYNC_IDX},dest]}'... "
done
echo

# Step through the sync list (which is ordered), and do each sync job:
#
for (( SYNC_IDX=1; SYNC_IDX <= NUM_SYNCS; SYNC_IDX++ )); do

    Synchronize ${SYNC_IDX}
done

############################################################################

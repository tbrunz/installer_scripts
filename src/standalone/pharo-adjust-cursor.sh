#! /usr/bin/env bash
#
echo 1>&2 "This script isn't finished yet!"
#exit 1

# Create an associative array of tags to be matched in file names, which
# will uniquely indentify the type of Pharo application a directory holds.
# An array will allow use of a loop to locate the matching app file names.
declare -A PHARO_APP_KEYWORDS=(
    ["KEYWORD_APP_PHARO_LAUNCHER"]="launcher"
    ["KEYWORD_APP_PHARO_THINGS"]="Things"
)

# Create an associative array of Pharo application name scrings.
# These allow us to translate a tag that matches a file name to a
# string which is more suitable for use in user messages.
declare -A PHARO_APP_NAMES=(
    ["${PHARO_APP_KEYWORDS["KEYWORD_APP_PHARO_LAUNCHER"]}"]="Pharo Launcher"
    ["${PHARO_APP_KEYWORDS["KEYWORD_APP_PHARO_THINGS"]}"]="Pharo IoT"
)

# Create an associative array of file names of the bash scripts that
# we're targeting for modification.  We will attempt to make exact
# matches of file names to these strings to select files for editing.
declare -A PHARO_SCRIPT_NAMES=(
    ["SCRIPT_NAME_PHARO_LAUNCHER"]="pharo-launcher"
    ["SCRIPT_NAME_PHARO_THINGS_APP"]="pharo"
    ["SCRIPT_NAME_PHARO_THINGS_GUI"]="pharo-ui"
)

# Create an associative array of arbitrary tags that will be used to
# select the editing action for bash scripts that are to be modified.
declare -A PHARO_EDIT_ACTIONS=(
    ["INSERT_BIG_CURSOR"]="insert"
    ["REMOVE_BIG_CURSOR"]="remove"
)


###############################################################################
#
# Echo the argument to the Standard Error stream.
#
Display_Error () {
    local ERROR_MSG=${1}

    # If $1 is not defined, we have a programming error...
    [[ ${ERROR_MSG} ]] || ERROR_MSG="Undefined error!"

    # Display the error message; if $2 is defined, the quit the script.
    echo 1>&2 "${1}"
    [[ ${2} ]] && exit 1
}


###############################################################################
#
# Notify the user of files that we're modifying.
#
Notify_of_File_Being_Modified () {
    local FILE_PATH=${1}

    [[ -n "${FILE_PATH}" ]] && echo "Editing file '${1}'... " && return

    Display_Error "File name required! "
}


###############################################################################
#
# Warn about directories that we don't have write permission for.
#
Warn_If_Directory_Not_Writable () {
    local SCRIPT_PATH=${1}
    local ERROR_MSG

    ERROR_MSG="Cannot write files in directory"
    ERROR_MSG="${ERROR_MSG} '$( dirname "${SCRIPT_PATH}" )'! Skipping... "

    Display_Error "${ERROR_MSG}"
}


###############################################################################
#
# Warn about directories that aren't Pharo apps, yet have no subdirectories.
#
Warn_If_Not_Pharo_Directory () {
    local ERROR_MSG

    # If we determine that the working directory is a Pharo
    # application directory, then we "fail to warn".  Having
    # already matched an application keyword in a filename is
    # a sufficient indication of this situation.
    [[ ${THIS_APP_KEYWORD} ]] && return 1

    # If this is not a Pharo app directory, then we require the
    # working directory to have at least one subdirectory;
    # We will examine these in turn for Pharo applications.
    # If the subdirectories array has at least one element,
    # then we also "fail to warn":
    (( ${#SUBDIRECTORIES[@]} > 0 )) && return 1

    # The working directory is not a Pharo app directory, and
    # it has no subdirectories -- this is an error condition,
    # so display the error and return 0 to trigger follow-on
    # error handling:
    ERROR_MSG="Directory '${WORKING_DIRECTORY}' does not appear to be a Pharo"
    ERROR_MSG="${ERROR_MSG} directory and has no Pharo subdirectories! "

    Display_Error "${ERROR_MSG}"
}


###############################################################################
#
# Warn about Pharo app directories we recognize that have no scripts in them.
#
Warn_If_App_Without_Scripts () {
    local ERROR_MSG

    # If there is at least one script file present, don't warn.
    (( ${#PHARO_FILE_PATHS[@]} > 0 )) && return 1

    # Otherwise, assemble a descriptive warning message and display it.
    # Name the directory and say which Pharo app we believe it contains.
    ERROR_MSG="Directory '${WORKING_DIRECTORY}' appears to be a"
    ERROR_MSG="${ERROR_MSG} ${PHARO_APP_NAMES[ ${THIS_APP_KEYWORD} ]}"
    ERROR_MSG="${ERROR_MSG} directory, but it doesn't have any scripts! "

    Display_Error "${ERROR_MSG}"
}


###############################################################################
#
# Ensure the provided argument is a valid directory path.
#
Ensure_is_a_Directory () {

    [[ -z "${1}" ]] && Display_Error "Directory path required! " "die"

    [[ -d "${1}" ]] || Display_Error "Argument not a directory! " "die"
}


###############################################################################
#
# Ensure that the provided argument is a valid directory, but not a VM dir.
#
VM_TAG="vm"

Ensure_is_Not_a_VM_Directory () {
    local ERROR_MSG

    # First, we must have an argument, and it must be a directory path:
    Ensure_is_a_Directory "${1}"

    # Additionally, the path must not match a string indicating a Pharo VM.
    [[ ! "${1}" =~ ${VM_TAG} ]] && return

    # If it appears to be a VM path, warn the user and continue.
    ERROR_MSG="Directory ${1} appears to be a virtual machine directory"
    ERROR_MSG="${ERROR_MSG} and so will be ignored... "

    Display_Error "${ERROR_MSG}"
}


###############################################################################
#
# Patterns in the Pharo scripts to search for and replace with:
#
PATTERN_0="env[[:space:]]+SQUEAK_FAKEBIGCURSOR=1"
PATTERN_1="env SQUEAK_FAKEBIGCURSOR=1"
PATTERN_2='exec'
PATTERN_3='"\$LINUX'
PATTERN_4='vm\/\$VM'


###############################################################################
#
# Rules for Pharo Launcher, file 'pharo-launcher':
#
# Example: ~/Pharo/pharolauncher/pharo-launcher
#
#    exec "$LINUX/pharo" \
#
#    exec env SQUEAK_FAKEBIGCURSOR=1 \
#        "$LINUX/pharo" \
#
PharoLauncher_InstallBigCursor () {
    sed -i -r -e "/${PATTERN_2}/ s|^([[:space:]]*${PATTERN_2}[[:space:]]+)(${PATTERN_3}.+)$|\1${PATTERN_1} \\\\\n\t\2|" \
        "${SCRIPT_PATH_TO_EDIT}"
}

PharoLauncher_RemoveBigCursor () {
    sed -i -r -e "/${PATTERN_0}/ N; s|^([[:space:]]*${PATTERN_2}[[:space:]]+)${PATTERN_0}.*\n[[:space:]]*(${PATTERN_3}.+)$|\1\2|" \
        "${SCRIPT_PATH_TO_EDIT}"
}


###############################################################################
#
# Rules for Pharo IOT, file 'pharo':
#
# Example: ~/Pharo/pharoiot/pharo
#
#    vm/$VM/pharo --headless PharoThings
#
#    env SQUEAK_FAKEBIGCURSOR=1 vm/$VM/pharo --headless PharoThings
#
PharoIOT_InstallBigCursor () {
    sed -i -r -e "/^[[:space:]]+${PATTERN_4}/ s|^([[:space:]]+)(${PATTERN_4}.+)$|\1${PATTERN_1} \2|" \
        "${SCRIPT_PATH_TO_EDIT}"
}

PharoIOT_RemoveBigCursor () {
    sed -i -r -e "/^[[:space:]]+${PATTERN_0}/ s|^([[:space:]]+)${PATTERN_0}[[:space:]]+(.*)$|\1\2|" \
        "${SCRIPT_PATH_TO_EDIT}"
}


###############################################################################
#
# Rules for Pharo IOT, file 'pharo-ui':
#
# Example: ~/Pharo/pharoiot/pharo-ui
#
#    vm/$VM/pharo PharoThings
#
#    env SQUEAK_FAKEBIGCURSOR=1 vm/$VM/pharo PharoThings
#
PharoUI_InstallBigCursor () {
    sed -i -r -e "/^[[:space:]]+${PATTERN_4}/ s|^([[:space:]]+)(${PATTERN_4}.+)$|\1${PATTERN_1} \2|" \
        "${SCRIPT_PATH_TO_EDIT}"
}

PharoUI_RemoveBigCursor () {
    sed -i -r -e "/^[[:space:]]+${PATTERN_0}/ s|^([[:space:]]+)${PATTERN_0}[[:space:]]+(.*)$|\1\2|" \
        "${SCRIPT_PATH_TO_EDIT}"
}


###############################################################################
#
# Create an associative array of function names to call for editing
# the Pharo application bash scripts.
#
# The keys to these will be assembled dynamically at run-time and
# used to select the function for modifying the target bash script.
#
declare -A CONVERSIONS

       KEY=${PHARO_APP_KEYWORDS["KEYWORD_APP_PHARO_LAUNCHER"]}
KEY=${KEY}_${PHARO_SCRIPT_NAMES["SCRIPT_NAME_PHARO_LAUNCHER"]}
KEY=${KEY}_${PHARO_EDIT_ACTIONS["INSERT_BIG_CURSOR"]}

CONVERSIONS[${KEY}]="PharoLauncher_InstallBigCursor"

       KEY=${PHARO_APP_KEYWORDS["KEYWORD_APP_PHARO_LAUNCHER"]}
KEY=${KEY}_${PHARO_SCRIPT_NAMES["SCRIPT_NAME_PHARO_LAUNCHER"]}
KEY=${KEY}_${PHARO_EDIT_ACTIONS["REMOVE_BIG_CURSOR"]}

CONVERSIONS[${KEY}]="PharoLauncher_RemoveBigCursor"

       KEY=${PHARO_APP_KEYWORDS["KEYWORD_APP_PHARO_THINGS"]}
KEY=${KEY}_${PHARO_SCRIPT_NAMES["SCRIPT_NAME_PHARO_THINGS_APP"]}
KEY=${KEY}_${PHARO_EDIT_ACTIONS["INSERT_BIG_CURSOR"]}

CONVERSIONS[${KEY}]="PharoIOT_InstallBigCursor"

       KEY=${PHARO_APP_KEYWORDS["KEYWORD_APP_PHARO_THINGS"]}
KEY=${KEY}_${PHARO_SCRIPT_NAMES["SCRIPT_NAME_PHARO_THINGS_APP"]}
KEY=${KEY}_${PHARO_EDIT_ACTIONS["REMOVE_BIG_CURSOR"]}

CONVERSIONS[${KEY}]="PharoIOT_RemoveBigCursor"

       KEY=${PHARO_APP_KEYWORDS["KEYWORD_APP_PHARO_THINGS"]}
KEY=${KEY}_${PHARO_SCRIPT_NAMES["SCRIPT_NAME_PHARO_THINGS_GUI"]}
KEY=${KEY}_${PHARO_EDIT_ACTIONS["INSERT_BIG_CURSOR"]}

CONVERSIONS[${KEY}]="PharoUI_InstallBigCursor"

       KEY=${PHARO_APP_KEYWORDS["KEYWORD_APP_PHARO_THINGS"]}
KEY=${KEY}_${PHARO_SCRIPT_NAMES["SCRIPT_NAME_PHARO_THINGS_GUI"]}
KEY=${KEY}_${PHARO_EDIT_ACTIONS["REMOVE_BIG_CURSOR"]}

CONVERSIONS[${KEY}]="PharoUI_RemoveBigCursor"


###############################################################################
#
# For bash scripts we recognize, apply the appropriate edit to fix the cursor.
#
BASH_TAG="Bourne"

Edit_Pharo_Script () {
    local SCRIPT_PATH=${1}
    local SCRIPT_NAME
    local EDIT_FUNCTION_KEY
    local EDIT_FUNCTION

    # Must ensure that the argument is a valid path to a regular file.
    [[ -f "${SCRIPT_PATH}" ]] || return 1

    # We only edit bash script files; reject if it's not a bash script.
    file "${SCRIPT_PATH}" | grep -q "${BASH_TAG}"
    (( $? == 0 )) || return 1

    # We need the file name to form a key to look up the edit function.
    SCRIPT_NAME=$( basename "${SCRIPT_PATH}" )

    # Form an associate array key from the Pharo application type, the
    # script name, and the editing action desired by the user.
    EDIT_FUNCTION_KEY=${THIS_APP_KEYWORD}_${SCRIPT_NAME}_${SCRIPT_EDIT_ACTION}

    # Use the key to resolve the name of the function needed to edit the file.
    EDIT_FUNCTION=${CONVERSIONS["${EDIT_FUNCTION_KEY}"]}

    # If this key is bogus (i.e., the file is not a target bash script),
    # then the resolved function name will be a blank string.
    [[ -n "${EDIT_FUNCTION}" ]] || return 1

    # Make a name for backing up the script file before editing.
    # Back up the script file here instead of via 'sed',
    # so we only need this code in one place.
    cp -a "${SCRIPT_PATH}" "${SCRIPT_PATH}.$( date +%s )"

    # If that failed, we won't be able to edit the script either...
    (( $? != 0 )) && Warn_Directory_Not_Writable "${SCRIPT_PATH}" && return 1

    # Echo the name of the script being modified, for reassurance.
    Notify_of_File_Being_Modified "${SCRIPT_PATH}"

    # Here's the payoff, the moment we've been waiting for...
    SCRIPT_PATH_TO_EDIT=${SCRIPT_PATH}
    ${EDIT_FUNCTION}
}


###############################################################################
#
# Obtain a list of paths to bash scripts in the working directory.
# Also create a list of subdirectories if this is the top-level directory.
#
Examine_Directory () {
    WORKING_DIRECTORY=${1}
    THIS_APP_KEYWORD=""
    PHARO_FILE_PATHS=()

    # Check that the directory is a directory, but not a Pharo VM directory:
    Ensure_is_Not_a_VM_Directory "${WORKING_DIRECTORY}" || return 1

    # One by one, examine each item found in the working directory:
    for FILE_PATH in "${WORKING_DIRECTORY}"/*; do

        # Determine what kind of 'file' this FILE_PATH is.  We're
        # interested in both bash script files and subdirectories.
        if [[ -d "${FILE_PATH}" ]]; then
            # If it's a directory, do NOT accumulate it in the list of
            # subdirectories UNLESS we're examining a top-level directory.
            # Otherwise, we would clobber an array being used in a loop!
            [[ ! ${TOP_LEVEL} ]] && SUBDIRECTORIES+=( "${FILE_PATH}" )
        else
            PHARO_FILE_PATHS+=( "${FILE_PATH}" )
        fi

        # If we haven't yet matched an application keyword, then check
        # the filename against the list of known application keywords
        # that uniquely identify which Pharo app this directory holds.
        if [[ -z "${THIS_APP_KEYWORD}" ]]; then

            # Iterate through the list of keywords for known Phara apps.
            for APP_KEYWORD in "${PHARO_APP_KEYWORDS[@]}"; do

                # Try to match against just the filename, since the full
                # path could contain directory names that falsely match.
                THIS_APP_KEYWORD=$( printf "%s" \
                    "$( basename "${FILE_PATH}" )" | grep -o "${APP_KEYWORD}" )

                # If this file doesn't identify a Pharo app, then it will
                # remain an empty string, enabling the test on the next file.
                # Once we've made a match, stop checking in this directory.
                [[ -n "${THIS_APP_KEYWORD}" ]] && break
            done
        fi
    done
}


###############################################################################
#
# Process the set of bash scripts that were found in a Pharo app directory.
#
Process_Pharo_Files () {
    # Having collected a list of bash scripts in the working directory,
    # we require that at least one filename matched a keyword for a
    # Pharo application.  If this is not the case, there's nothing to
    # do here, since we won't modify scripts that are not the scripts
    # of a Pharo application.  This isn't fatal; just try the next one.
    [[ -n "${THIS_APP_KEYWORD}" ]] || return 1

    # On the other hand, if this is a Pharo application directory, then
    # we expect to find a target bash script.  Verify that the list of
    # bash scripts we've accumulated has at least one member.  If not,
    # then warn the user of this anomaly and bail out of this function.
    Warn_If_App_Without_Scripts && return 1

    # Otherwise, we have a known Pharo application and we found at least
    # one bash script.  Process the set, modifying those scripts that we
    # recognize, according to the user's action and the script type.
    for FILE_PATH in "${PHARO_FILE_PATHS[@]}"; do
        #Edit_Pharo_Script "${FILE_PATH}" || return 1
        Edit_Pharo_Script "${FILE_PATH}"
        (( $? == 0 )) && continue
        Display_Error "Failed edit for '${FILE_PATH}'... "
    done
}


###############################################################################
#
# Recur one level into subdirectories, processing those that have Pharo apps.
#
Process_Subdirectories () {
    # Do not process the subdirectories of a Pharo application directory.
    # Why? Because a Pharo application directory should not contain
    # subdirectories of other Pharo applications.  Having matched a
    # Pharo application keyword previously is sufficient indication
    # of this situation, so just ignore any subdirectories & return.
    [[ ${THIS_APP_KEYWORD} ]] && return 2

    # Otherwise, we require that at least one subdirectory exists to
    # examine recursively.  If none were found, we're not able to
    # examine any Pharo application directory -- warn the user & return.
    Warn_If_Not_Pharo_Directory && return 1

    # Important: Since we're about to recur into a set of subdirectories,
    # we *must* set a flag to *not* mess with ${SUBDIRECTORIES[@]},
    # because we're using it here to track our recursions.
    TOP_LEVEL=false
    for SUBDIRECTORY in "${SUBDIRECTORIES[@]}"; do
        # Examine each subdirectory, one-by-one, but only check the
        # bash scripts we find in them; do not recur further into any
        # subdirectories.  (Bash doesn't really do recursion well.)
        # The user must launch this script from either a Pharo app dir,
        # or from a directory containing Pharo app subdirs.  If launched
        # too high up in the directory tree, the above error trap will
        # be triggered, warning the user, and nothing will be done.
        Examine_Directory "${SUBDIRECTORY}"
        Process_Pharo_Files
    done
}


###############################################################################
#
Main () {
    local TOP_LEVEL_DIRECTORY

    # Start with the assumption that the working directory is a top-lovel
    # directory, which may be either a Pharo application directory, or a
    # directory containing one or more Pharo applications in subdirectories.
    TOP_LEVEL_DIRECTORY=$( pwd )
    TOP_LEVEL=true
    SUBDIRECTORIES=( )

    # Examine the top-level directory contents, then do one of two things:
    # If it's a Pharo application directory, modify its bash scripts;
    # otherwise, examine every subdirectory and for those that contain
    # Pharo applications, modify their bash scripts accordingly.
    Examine_Directory "${TOP_LEVEL_DIRECTORY}"
    Process_Pharo_Files
    Process_Subdirectories
}

Main

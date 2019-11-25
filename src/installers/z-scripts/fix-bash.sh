#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Edit .bashrc to fix the 'll', 'la', 'l' aliases
# ----------------------------------------------------------------------------
#

#
# Maintain a list of "excluded users"; i.e., a list of directories
# in '/home' that we know a priori will not need to be fixed up.
# For example, if '/home' is a separate partition, there will be a
# '/home/lost+found' directory -- don't bother with it.
#
EXCLUDED_USERS="lost+found"

THIS_HOME=/home

DO_BASHRC=yes
DO_BASH_LOGOUT=yes

#
# Get the name of this script (for 'usage')
#
SOURCE="${BASH_SOURCE[0]}"
while [[ -h "${SOURCE}" ]] ; do SOURCE="$(readlink "${SOURCE}")" ; done
THIS_SCRIPT=$( basename ${SOURCE} .sh )
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

#
# Respond to a version query (-v)
#
if [[ "${1}" == "-v" || "${1}" == "--version" ]]; then

    echo "${THIS_SCRIPT}, v${VERSION} "
    exit 2
fi

#
# Display the 'usage' prompt (-h)
#
unset HELP
if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then HELP=true; fi
if [[ "${1}" != "-f" && "${1}" != "--fix"  ]]; then HELP=true; fi

if [[ ${HELP} == true ]]; then
    echo
    echo -n "usage: sudo ${THIS_SCRIPT} [ -f | -v | -h ][ -t ] | "
    echo    "[ -nb ][ -nl ][ [list of] user(s) ]"
    echo
    echo "This script does two things: "
    echo "  1.) Renames '.bash_logout' to '.bash_logout-orig' "
    echo "  2.) Changes '.bashrc' alias definitions for 'll', 'l', & 'la' "
    echo
    echo "It applies these changes for one or more specified user accounts. "
    echo
    echo "Options: "
    echo "    -f  --fix     = Perform the fixups "
    echo "    -v  --version = Display software version "
    echo "    -h  --help    = Display this help menu "
    echo "    -t  --test    = Run in test mode; show what would be applied "
    echo
    echo "    -nb  --no-bashrc = Don't change the '.bashrc' file "
    echo "    -nl  --no-logout = Don't change the '.bash_logout' file "
    echo
    echo  "Specifically, this script changes the following section of the "
    echo "'.bashrc' file in each user's account: "
    echo
    echo "    # some more ls aliases "
    echo "    alias ll='ls -alF' "
    echo "    alias la='ls -A' "
    echo "    alias l='ls -CF' "
    echo
    echo " to become: "
    echo
    echo "    # some more ls aliases "
    echo "    alias ll='ls -lF' "
    echo "    alias la='ls -alF' "
    echo
    echo "If there are no aliases for 'll' or 'la', they will be created. "
    echo
    echo "The list of users can be zero or more names of user accounts "
    echo "on the system, separated by spaces, and optionally preceded by "
    echo "'-t' to display what the script will find & apply without the "
    echo "'-t' option.  The list of users is optional, and corresponds to "
    echo "actual directories in '/home', not to usernames in 'passwd'. "
    echo
    echo "If no users are specified on the command line as arguments, "
    echo "then the script will find all users in '/home' and attempt to "
    echo "fix their '.bashrc' files. Note that 'root' will be added to "
    echo "the list, and can also be specified explicitly in a user list. "
    echo
    echo "The head of the script contains an environment variable, "
    echo "EXCLUDED_USERS, that contains a list of directories in '/home' "
    echo "that are to be excluded from consideration. By default, this "
    echo "exclusion list contains 'lost+found', and may be edited as "
    echo "as desired. "
    echo
    echo "Note that this script can be run repeatedly without causing "
    echo "side-effects. "
    echo

    exit 1
fi

#
# Check to see if we operate in 'test mode'
#
unset TEST_MODE
shift

if [[ "${1}" == "-t" || "${1}" == "--test" ]]; then

    TEST_MODE=test
    shift
fi

#
# Check for "no bashrc change"
#
if [[ "${1}" == "-nb" || "${1}" == "--no-bashrc" ]]; then

    unset DO_BASHRC
    shift
fi

#
# Check for "no bashrc change"
#
if [[ "${1}" == "-nl" || "${1}" == "--no-logout" ]]; then

    unset DO_BASH_LOGOUT
    shift
fi

#
# Check AGAIN for "no bashrc change" -- it might have been second
#
if [[ "${1}" == "-nb" || "${1}" == "--no-bashrc" ]]; then

    unset DO_BASHRC
    shift
fi

#
# Any other switch is an error...
#
if [[ $(echo ${1} | cut -c 1) == "-" ]]; then

    echo "${THIS_SCRIPT}: Switch error, '${1}' "
    exit 4
fi

#
# Someone's unclear on the concept if they disable both actions...
#
if [[ -z "${DO_BASHRC}${DO_BASH_LOGOUT}" ]]; then

    echo "${THIS_SCRIPT}: Nothing to do! "
    exit 8
fi

#
# Algorithm:
#
# Verify that the user has launched us using 'sudo'.
#
ls /root > /dev/null 2>&1

if [[ $? != 0 ]]; then

    echo "${THIS_SCRIPT}: Must run this script as 'root'. "
    exit 8
fi

#
# If one or more users are explicitly given as arguments, then
# make a list of those users from the command line arguments.
#
if [[ -n "${1}" ]]; then

    USER_LIST="$*"
#
# If no user is specified as an argument, then create a list of
# users from the directories in the '/home' directory, and add
# 'root' to the list (it's a special case).
#
else
    USER_LIST="root $( find /home -type d -path "/home/*" -prune )"

fi

#
# For each user in the list, check it to see if it's an account
# that has a '.bashrc' file.  If so, then convert it.
#
for USER_DIR in ${USER_LIST}; do

    #
    # Create the directory path parts needed for this case
    #
    # ENHANCE: Translate the user name into a directory by
    #          looking up the user in '/etc/passwd'
    #
    THIS_USER=$( basename ${USER_DIR} )
    THIS_DIR=${THIS_HOME}/${THIS_USER}

    #
    # Do we exclude this "user"?
    #
    if [[ ${EXCLUDED_USERS} != *"${THIS_USER}"* ]]; then

        # No, not excluded, therefore proceed...

        if [[ ${THIS_USER} == "root" || -f ${THIS_DIR}/.bashrc \
                || -f ${THIS_DIR}/.bash_logout ]]; then

            # Remember, 'root' is a special case:
            # Its home directory is not in '/home'...

            if [[ ${THIS_USER} == "root" ]]; then
                THIS_DIR=/root
            fi

            # Determine if we can/should change the '.bashrc' file...

            unset BASHRC
            if [[ -n "$DO_BASHRC" &&
                    -z "$( ls ${THIS_DIR}/.bashrc 2>&1 | grep -i no )" ]]; then
                BASHRC=yes
            fi

            # Determine if we can/should change the '.bash_logout' file...

            unset BASH_LOGOUT
            [[ -n "$DO_BASH_LOGOUT" &&
                    -z "$( ls ${THIS_DIR}/.bash_logout 2>&1 | grep -i no )" ]] \
                    && BASH_LOGOUT=yes

            # If we're in 'test mode', just report what we *would* modify...

            if [[ -n "$TEST_MODE" ]]; then

                if [[ -n "$BASHRC" && -n "$BASH_LOGOUT" ]]; then

                    echo -n "Test mode: Found both '.bashrc' and "
                    echo    "'.bash_logout' in ${THIS_DIR} ...  "
                else
                    [[ -n "$BASHRC" ]] && \
                        echo "Test mode: Found '.bashrc' in ${THIS_DIR} ...  "
                    [[ -n "$BASH_LOGOUT" ]] && \
                        echo "Test mode: Found '.bash_logout' in ${THIS_DIR} ...  "
                fi

            else
                #
                # The following 'cat' command will have a file;
                # Pipe it through a series of 'sed' commands to edit it.
                #
                echo "Fixing up user ${THIS_USER} ...  "

                if [[ -n "$BASHRC" ]]; then

                    # We need to copy it to '/tmp' in order to make the edits...

                    cp ${THIS_DIR}/.bashrc /tmp/${THIS_SCRIPT}-${THIS_USER}

                    chmod 666 /tmp/${THIS_SCRIPT}-${THIS_USER}

                    # Ensure that there exists 'll' & 'la' lines in the file:

                    if [[ ! $( grep '^[[:blank:]]*alias ll=' \
                            /tmp/${THIS_SCRIPT}-${THIS_USER} ) ]]; then

                        echo "alias ll='ls -lF'" \
                            >> /tmp/${THIS_SCRIPT}-${THIS_USER}
                    fi

                    if [[ ! $( grep '^[[:blank:]]*alias la=' \
                            /tmp/${THIS_SCRIPT}-${THIS_USER} ) ]]; then

                        echo "alias la='ls -alF'" \
                            >> /tmp/${THIS_SCRIPT}-${THIS_USER}
                    fi

                    # Now they exist, make sure they are what they should be...
                    #
                    # We 'cat' the file into 'sed' to make the changes:
                    #
                    #     /^[[:blank:]]*alias ll=
                    #         means "Find a line that starts with whitespace
                    #         followed by 'alias ll='."
                    #
                    #     /s/^\([[:blank:]]*\).*$
                    #         means "In this line, match starting whitespace,
                    #         plus the rest of the line; but also remember the
                    #         whitespace matched at the front (before 'alias')."
                    #
                    #     /\1alias ll=\'ls -lF\'
                    #         means "Replace what was matched (the entire line)
                    #         with the remembered starting whitespace (\1),
                    #         then with (literally) our desired alias command."
                    #
                    #     '/d' in the last line means "Delete the line that we
                    #         find (the 'l' definition)."

                    cat /tmp/${THIS_SCRIPT}-${THIS_USER}                    | \
                    sed -e "s/^\([[:blank:]]*alias ll=\).*$/\1\'ls -lF\'/"  | \
                    sed -e "s/^\([[:blank:]]*alias la=\).*$/\1\'ls -alF\'/" | \
                    sed -e '/^[[:blank:]]*alias l=/d'                         \
                    > /tmp/${THIS_SCRIPT}-${THIS_USER}-fixed

                    #
                    # Replace the user's .bashrc file & clean up...
                    #
                    cp /tmp/${THIS_SCRIPT}-${THIS_USER}-fixed ${THIS_DIR}/.bashrc

                    rm /tmp/${THIS_SCRIPT}-${THIS_USER}*
                fi

                if [[ -n "$BASH_LOGOUT" ]]; then

                    #
                    # Rename the user's .bash_logout file...
                    #
                    mv ${THIS_DIR}/.bash_logout ${THIS_DIR}/.bash_logout-orig
                fi
            fi

        #
        # Otherwise, if a '.bashrc' file can't be found, see if the directory
        # for the user even exists.  If it does, then see if the dir belongs
        # to a real user by checking the 'passwd' file for the (supposed) user;
        # 'false' users such as '/home/lost+found' aren't in the 'passwd' file.
        #
        # If the user is real, note that the '.bashrc' can't found.  If the user
        # actually is "lost+found", simply ignore it since this is expected (as
        # in cases where the '/home' directory is a separate partition).
        #
        # Otherwise, this is an unexpected non-user directory, a user that does
        # not use 'bash', etc... Just mention that it's being skipped & move on.
        #
        elif [[ -n "${THIS_USER}" ]]; then

            if [[ ! -d ${THIS_DIR} ]]; then

                echo -n "${THIS_SCRIPT}: Can't find user "
                echo    "'${THIS_USER}' in ${THIS_HOME} ! "

            elif [[ -n "$( grep ^${THIS_USER}: /etc/passwd )" ]]; then

                echo -n "${THIS_SCRIPT}: Can't find '.bashrc' or "
                echo    "'.bash_logout' in ${THIS_USER}'s account ! "

            else
                if [[ -f ${THIS_DIR}/.bash_logout-orig ]]; then

                    # Okay, user exists, no '.bashrc' or '.bash_logout', but
                    # we did find a '.bash_logout-orig' file --
                    # This one's already been done.

                    echo -n "No '.bashrc' file, but '${THIS_DIR}/.bash_logout' "
                    echo    "has already been renamed. "
                else
                    echo -n "No '.bashrc' or '.bash_logout' file found "
                    echo    "in '${THIS_DIR}'; Ignoring ... "
                fi
            fi

        # Else no list was given, so just ignore it and go on to the next one
        fi

    # Else this was user on the excluded list, so just go to the next one
    fi
done

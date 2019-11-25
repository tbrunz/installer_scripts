#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install the Exercism CLI
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

SET_NAME="Exercism"

INSTALL_SOURCE_DIR=shell
TARGET_DIR_REL_PATH=.config/exercism
TARGET_DIR_PATH=~/${TARGET_DIR_REL_PATH}

EXEC_FILE_NAME=exercism
EXEC_DIR_PATH=/usr/local/bin

BASH_SOURCE_FILE=~/.bashrc
BASH_CMPL_FILE=exercism_completion.bash

EXERCISM_PAGE=http://exercism.io
SETTINGS_PAGE=${EXERCISM_PAGE}/my/settings

UUID_GREP="[[:alnum:]]{8}-([[:alnum:]]{4}-){3}[[:alnum:]]{12}"

USAGE="
Exercism is an online platform designed to help you improve your coding
skills through practice and mentorship.

Exercism provides you with thousands of exercises spread across numerous
language tracks.  Once you start a language track you are presented with a
core set of exercises to complete.  Each is a fun and interesting challenge
designed to teach you a little more about the features of a language.

You complete a challenge by downloading the exercise to your computer and
solving it in your normal working environment.  Once you've finished, you
submit it online and one of our mentors will give you feedback on how you
could improve it using features of the language that you may not be familiar
with.  After a couple of rounds of refactoring, you will complete your
exercise and unlock both the next core exercise and also a series of related
side-exercises for you to practice on.

Exercism is entirely open source and relies on the contributions of thousands
of wonderful people, including our leadership team, our mentors, our track
maintainers, and thousands of contributors.

Exercism requires an account (which grants you a token that acts essentially
as a password to your settings and submissions).  You sign up at exercism.io
using either your GitHub account, or by using your email address and a choosen
password.  If you sign up using an email address, you confirm it via email.

https://exercism.io/getting-started
"

POST_INSTALL="
    To use Exercism, you need to complete several steps:

    Sign up
Sign up at exercism.io using either your GitHub account, or by using your
email address and choose a password.  If you sign up using an email address,
you will need to confirm it.  Look for the email, click the link, then log in.

    Installing the Exercism CLI
You shouldn't need to install the Exercism CLI -- this script should do that
for you.  However, if you need the install package for a different machine
architecture, the latest versions are here:

        http://github.com/exercism/cli/releases/latest

If this install script did not successfully install the CLI for you, then find
the package for your Linux platform's architecture and download it.  A CLI
installation walkthrough is here: https://exercism.io/cli-walkthrough

    Language and exercises
Once signed up, you will see a list of all the language tracks you can join.
You can click through as many as you want to explore.  Once you've found a
language you want to join, click the 'Join Track' button.  You will then be
taken into your new track.  You'll see a core set of exercises at the top and
some side-exercises below.

Start with the first core exercise on the track, which is normally called
'Hello World'.  Click on the exercise to begin.  You will see some information
and some instructions on the left-hand side and a button on the right-hand
side labelled 'Begin Walkthrough'. Click on this and follow the instructions
if you haven't already installed the CLI package.

    There's a lot more information on the website:  https://exercism.io/
"

#
# The user must include an 'update' switch (-n or -u)...
#
[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

# Now find the install package (from a local tarball):
#
SOURCE_DIR=../exercism
SOURCE_GLOB="exercism-linux-64bit.tgz"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
CLI_PACKAGE=${FILE_LIST}

# Untar the installation tarball & install its elements:
#
QualifySudo
maketmp -d
tar_zip "gz" "${CLI_PACKAGE}" -C "${TMP_PATH}"

# Okay to allow script to overwrite an existing executable:
#
move "${TMP_PATH}/${EXEC_FILE_NAME}" "${EXEC_DIR_PATH}"
SetDirPerms "${EXEC_DIR_PATH}/${EXEC_FILE_NAME}"

# Okay to allow script to overwrite an existing bash completion file:
#
makdir "${TARGET_DIR_PATH}" 770 "$( whoami )"
move "${TMP_PATH}/${INSTALL_SOURCE_DIR}/${BASH_CMPL_FILE}" \
    "${TARGET_DIR_PATH}"
SetDirPerms "${TARGET_DIR_PATH}/${BASH_CMPL_FILE}" 664 "$( whoami )"

# Set the bash completion file to be automatically sourced.
# Only add this code snippet if it's missing:
#
grep "${BASH_CMPL_FILE}" "${BASH_SOURCE_FILE}" &>/dev/null

if (( $? != 0 )); then cat >> "${BASH_SOURCE_FILE}" << BASHEOF

if [ -f ~/${TARGET_DIR_REL_PATH}/${BASH_CMPL_FILE} ]; then
    source ~/${TARGET_DIR_REL_PATH}/${BASH_CMPL_FILE}
fi

BASHEOF
fi

# Delete the temp files:
#
sudo rm -rf ${TMP_PATH}

# Loop to get the Exercism token from the user:
#
Get_User_Token () {
    echo "Surf to ${SETTINGS_PAGE} to get your token... "
    while true; do

        read -r -p "Paste your token here: "
        (( $? != 0 )) && continue

        printf "%s" "${REPLY}" | egrep "${UUID_GREP}" &>/dev/null

        (( $? == 0 )) && return
    done
}

# Loop to get the Exercism token from the user, then config Exercism with it:
#
Set_User_Token () {
    while true; do
        echo
        Get_User_Token

        ${EXEC_FILE_NAME} configure --token="${REPLY}"
        (( $? == 0 )) && return
    done
}

# Install or re-install the user's token:
#
echo
echo "The Exercism CLI package has been installed. "
Get_YesNo_Defaulted -y "Do you have an existing Exercism account?"

if (( $? != 0 )); then
    echo "Well, go to ${EXERCISM_PAGE} and sign up.  Now! "
    echo -n "Then, "
fi

# Now install the token in the user's Exercism configuration folder:
#
Set_User_Token

# This is probably superfluous, if the token installation works, but why not?
#
echo
echo "**********************************************************************"
echo "If the Exercism CLI is installed & working correctly, you should see "
echo
echo "    A command-line interface for the v2 redesign of Exercism."
echo
echo "Followed by a CLI menu of command options. "
echo "**********************************************************************"
echo

# Run the Exercism CLI without any arguments, which is their test procedure:
#
${EXEC_FILE_NAME}

(( $? == 0 )) && InstallComplete

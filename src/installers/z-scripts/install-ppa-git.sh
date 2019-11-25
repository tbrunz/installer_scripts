#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'git' using the Ubuntu Git Maintainers team's PPA repository
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

GetOSversion
SET_NAME="Git (PPA)"

MAX_SYSTEM_ID=999

GIT_USR="git"
GIT_GRP="git"

GIT_HOME="/opt/git"

SHELL_FILE="/etc/shells"
GIT_SHELL="/usr/bin/git-shell"

USR_FILE="/etc/passwd"
USR_FILE_UID_COL=3

GRP_FILE="/etc/group"
GRP_FILE_GID_COL=3

#
# Function to locate an available UID or GID in the "system ID" range
#
Get_System_ID () {
local ID_TYPE=${1}
local ID_NAME=${2}

# Look up a user ID or group ID
#
ID_TYPE=${ID_TYPE,,}
ID_TYPE=${ID_TYPE:0:2}

case ${ID_TYPE} in
"-u")
ID_TYPE="passwd"
;;
"-g")
ID_TYPE="group"
;;
*)
ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
  "Cannot parse '${ID_TYPE}' to '-u' or '-g' ! "
;;
esac

RESULT=$( getent "${ID_TYPE}" "${ID_NAME}" 2>/dev/null )

(( $? != 0 )) && return ${ERR_MISSING}

printf "%s" "${RESULT}" | cut -d ':' -f 3
}

USAGE="
Git is a version control system (VCS) for tracking changes in computer files
and coordinating work on those files among multiple people.  It is primarily
used for software development, but it can be used to keep track of changes in
any files.  As a distributed revision control system it is aimed at speed,
data integrity, and support for distributed, non-linear workflows.

As with most other distributed VCS, and unlike most client-server systems,
every Git directory on every computer is a full-fledged repository with a
complete history and full version tracking abilities, independent of network
access or a central server.

Git was created by Linus Torvalds in 2005 to help with development of the
Linux kernel.  Like the Linux kernel, Git is free software distributed under
the terms of the GNU General Public License version 2.

https://git-scm.com
https://github.com/git-lfs/git-lfs
"

POST_INSTALL="
A restricted 'git' account that uses 'git-shell' has been created, and each
user has been added to its group.  Use this account to own local 'base' repos.
"

#
# If installing in a Chromebook container, we're likely using Debian;
# In that case, we need to install additional packages:
#
if (( MAJOR < 14 ))
then
  PACKAGE_SET="git  software-properties-common
  python-software-properties  "
else
  # If installing in Ubuntu, then we're using an Ubuntu PPA:
  #
  PACKAGE_SET="git  git-core  git-doc  ppa-purge  "

  REPO_NAME="${SET_NAME}"
  REPO_URL="ppa:git-core/ppa"
  REPO_GREP="git-core.*${DISTRO}"
fi

SOURCE_DIR="../git"
SOURCE_GLOB="git*sh"

PerformAppInstallation "-r" "$@"

# Check for a 'git' user & group; if missing, we'll need to create them
#
ADD_USR=true
USR_ID=$( Get_System_ID -u "${GIT_USR}" )
(( $? == 0 )) && unset -v ADD_USR

ADD_GRP=true
GRP_ID=$( Get_System_ID -g "${GIT_GRP}" )
(( $? == 0 )) && unset -v ADD_GRP

# We can handle cases where neither a 'git' user & group are defined (i.e.,
# define them), or where both are already defined (i.e., do nothing), and
# even where the group is defined but not the user (i.e., define the user),
# but it's a problem if user is defined but not the group...
# If this is the case, quit and allow the user to correct:
#
[[ -z "${ADD_USR}" ]] && [[ -n "${ADD_GRP}" ]] && ThrowError \
  "${ERR_UNSPEC}" "${APP_SCRIPT}" \
    "Bad config: '${GIT_USR}' user is defined, but not '${GIT_GRP}' group ! "

# Determine what we need: If GID is needed, so is UID.
#
if [[ -n "${ADD_GRP}" ]]; then
  #
  # Since we need both a UID & GID, find the highest System ID that
  # is available for both values:
  #
  unset -v USR_ID
  unset -v GRP_ID

  for (( TRY_ID=MAX_SYSTEM_ID ; TRY_ID > 0 ; TRY_ID-- )); do

    USR_ID=$( Get_System_ID -u "${TRY_ID}" )
    (( $? == 0 )) && continue

    GRP_ID=$( Get_System_ID -g "${TRY_ID}" )
    (( $? == 0 )) && continue

    # If we get here, TRY_ID is not being used as either a UID or GID.
    #
    USR_ID=${TRY_ID}
    GRP_ID=${TRY_ID}
    break
  done

  # If GRP_ID got a value, then USR_ID got the same value; we're done.
  # Otherwise, there are *no* IDs available on this system!
  #
  [[ -n "${GRP_ID}" ]] || ThrowError "${ERR_UNSPEC}" "${APP_SCRIPT}" \
    "Cannot find an unused pair of System IDs on this OS !? "

else
  if [[ ${ADD_USR} ]]; then
    #
    # See if the UID matching the GID is available to assign as USR_ID
    #
    TRY_ID=${GRP_ID}

    USR_ID=$( Get_System_ID -u "${GRP_ID}" )
    if (( $? == 0 )); then
      #
      # No, so we need to search for one that is available...
      #
      for (( TRY_ID=MAX_SYSTEM_ID ; TRY_ID > 0 ; TRY_ID-- )); do

        USR_ID=$( Get_System_ID -u "${TRY_ID}" )
        (( $? != 0 )) && break
      done
    fi

    [[ -z "${USR_ID}" ]] || ThrowError "${ERR_UNSPEC}" "${APP_SCRIPT}" \
      "Cannot find an unused pair of System IDs on this OS !? "

    USR_ID=${TRY_ID}
  fi
fi

# Create the group, as needed.  (Must create this first)
#
if [[ -n "${ADD_GRP}" ]]; then
  sudo addgroup --system --gid "${GRP_ID}" "${GIT_GRP}"

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Cannot create new group '${GIT_GRP}' with GID ${GRP_ID} ! "
fi

# Create the new user, as needed:
#
if [[ -n "${ADD_USR}" ]]; then

  sudo adduser --system --uid "${USR_ID}" --gid "${GRP_ID}" \
    --home "${GIT_HOME}" "${GIT_USR}"

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Cannot create new user '${GIT_USR}' with UID ${USR_ID} ! "
fi

makdir "${GIT_HOME}" 2775 "root:${GIT_USR}"

# Is 'git-shell' already installed and in the shell list?
#
grep -q "${GIT_SHELL}" "${SHELL_FILE}"

if (( $? != 0 )); then
  #
  # Verify that installing 'git' also installed the 'git-shell':
  #
  which "${GIT_SHELL}" &>/dev/null

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Cannot add shell '${GIT_SHELL}' to the list of shells ! "

  # Then add 'git-shell' to the list of shells
  #
  echo "${GIT_SHELL}" | sudo tee -a "${SHELL_FILE}" >/dev/null

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Cannot add shell '${GIT_SHELL}' to the list of shells ! "
fi

# Force the shell to the git-shell:
#
sudo chsh --shell "${GIT_SHELL}" "${GIT_USR}"

# Add other users to the 'git' group:
#
GetUserAccountInfo

for THIS_USER in "${USER_LIST[@]}"; do

    sudo adduser --quiet "${THIS_USER}" "${GIT_GRP}"
    (( $? == 0 )) && continue

    echo -n "    Could not add '${THIS_USER}' "
    echo    "to group '${GIT_GRP}', skipping... "
done

# Install the set of Git scripts (git bash completion, git prompt, etc)
#
ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

for GIT_SCRIPT in "${FILE_LIST[@]}"; do

    TARGET_NAME=.$( basename "${GIT_SCRIPT}" )

    cp "${GIT_SCRIPT}" ~/"${TARGET_NAME}"
done

chmod 775 ~/.git*.sh

InstallComplete

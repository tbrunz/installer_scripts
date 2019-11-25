#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install git-lfs using the PPA repository
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
SET_NAME="Git LFS (PPA)"

USAGE="
This script installs 'git-lfs', the Git Large File System.  (If Git has not
been previously installed, it will also install Git.)

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

RESULT=$( which git 2>&1 )

POST_INSTALL="
!!IMPORTANT!!
     Users must run 'git lfs install' (one time) to enable git-lfs.
!!IMPORTANT!!

'git lfs install' enables git-lfs for every repo of that user.

If the user prefers to enable git-lfs on a case-by-case basis, they can run
'git lfs install --local' in each repo that they wish to have git-lfs enabled.

Running 'git lfs uninstall' will disable git-lfs.  Similarly, for local  use,
running 'git lfs uninstall --local' will disable for only the selected repo.
"

[[ -z "${RESULT}" ]] && POST_INSTALL="${POST_INSTALL}

If you intend to create shared repositories on this machine, consider adding
a restricted 'git' account that uses 'git-shell'.

https://hackaday.com/2018/06/27/keep-it-close-a-private-git-server-crash-course/

https://stackoverflow.com/questions/3242282/how-to-configure-an-existing-git-repo-to-be-shared-by-a-unix-group/
"

PACKAGE_SET="git  git-core  git-doc  ppa-purge  "

SOURCE_DIR="../git"
SOURCE_GLOB="git*sh"

REPO_NAME="${SET_NAME}"
REPO_URL="ppa:git-core/ppa"
REPO_GREP="git-core.*${DISTRO}"

PerformAppInstallation "-r" "$@"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

for GIT_SCRIPT in "${FILE_LIST[@]}"; do

  TARGET_NAME=.$( basename "${GIT_SCRIPT}" )

  cp "${GIT_SCRIPT}" ~/"${TARGET_NAME}"
done

chmod 775 ~/.git*.sh

#
# There should be an additional third-party install script for git-lfs...
# This script can be downloaded by executing the following command:
# curl -s >script.deb.sh https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh
#
# Note that this script will run 'apt-get update' for us.
#
[[ -r "${SOURCE_DIR}/script.deb.sh" ]] || \
  ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
    "Cannot find '${SOURCE_DIR}/script.deb.sh' ! "

sudo bash -c "source ${SOURCE_DIR}/script.deb.sh"

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
  "Cannot source '${SOURCE_DIR}/script.deb.sh' ! "

PACKAGE_SET="git-lfs"
PerformAppInstallation "$@"

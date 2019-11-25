#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Vim packages (without GUI support)
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

SCRIPT_DIR=.vim/plugin

SET_NAME="Vim"
PACKAGE_SET="vim  vim-doc  vim-scripts  vim-conque  "
#PACKAGE_SET="vim  vim-gtk3  vim-doc  vim-gui-common  vim-scripts  vim-conque  "
#PACKAGE_SET="vim  vim-gnome  vim-doc  vim-gui-common  vim-scripts  vim-conque  "
SOURCE_DIR="../vim"

# If we have any vim scripts to install, list them in the 'usage' prompt:
#
SCRIPT_LIST="This script installs vim (but not gvim)."

SCRIPT_GLOB="*.vim"
FindGlobFilename "basename" "${SOURCE_DIR}" 1 ${SCRIPT_GLOB}

if (( $? == 0 )); then
    SCRIPT_LIST="This script installs vim and useful vim scripts:"

    for SCRIPT_FILE in "${FILE_LIST[@]}"; do

  SCRIPT_LIST="${SCRIPT_LIST}""$( printf "\n%s \n" "    * ${SCRIPT_FILE}")"
    done
fi

USAGE="
Vim is a text editor written by Bram Moolenaar and first released publicly in
1991.  Based on the 'vi' editor common to Unix-like systems, Vim is designed
for use both from a command line interface (as 'vim') and as a standalone
application (as 'gvim') in a graphical user interface.  Vim is free and open
source software and has been developed to be cross-platform.

Like vi, Vim's interface is based not on menus or icons but on commands given
in a text user interface; its GUI mode, gVim (not installed with this package), 
adds menus and toolbars for commonly-used commands but the full functionality 
is still expressed through its command line mode.

${SCRIPT_LIST}

http://www.vim.org/
"

PerformAppInstallation "-r" "$@"

SCRIPT_GLOB="*"
FindGlobFilename "basename" "${SOURCE_DIR}" 1 ${SCRIPT_GLOB}

#
# Get a list of user accounts & their info, and install scripts to each:
#
GetUserAccountInfo

echo
for THIS_USER in "${USER_LIST[@]}"; do

    HOME_DIR=${HOME_LIST[${THIS_USER}]}
    SCRIPT_INSTALL_DIR=${HOME_DIR}/${SCRIPT_DIR}

    if [[ ! -d "${HOME_DIR}" ]]; then continue; fi

    echo "...installing ${SET_NAME} scripts for '${THIS_USER}' "

    # Create the user's script directory (as needed):
    #
    makdirin "${HOME_DIR}" "${SCRIPT_DIR}" \
                            750 ${THIS_USER}:${GID_LIST[${THIS_USER}]}

    for SCRIPT_FILE in "${FILE_LIST[@]}"; do

        copy "${SOURCE_DIR}/${SCRIPT_FILE}" "${SCRIPT_INSTALL_DIR}/"

        sudo chown -R ${UID_LIST[${THIS_USER}]}:${GID_LIST[${THIS_USER}]} \
                        "${SCRIPT_INSTALL_DIR}/${SCRIPT_FILE}"

        sudo chmod 644 "${SCRIPT_INSTALL_DIR}/${SCRIPT_FILE}"
    done
done

#
# Don't forget to install a set for root.  Can't do it as part of the above
# (due to limitations of 'sudo'), so copy the last regular user's set:
#
sudo mkdir -p "/root/${SCRIPT_DIR}/"
sudo cp -rf "${SCRIPT_INSTALL_DIR}" "$( dirname /root/${SCRIPT_DIR} )"

InstallComplete

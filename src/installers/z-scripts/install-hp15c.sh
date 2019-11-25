#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install HP-15C Calculator Simulator
# ----------------------------------------------------------------------------
#

#
# Source the common core includes:
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

SET_NAME="HP-15C Calculator"

PACKAGE_SET=""
[[ "${FLAVOR}" != "xfce" ]] && PACKAGE_SET="alacarte  "

SOURCE_DIR=../hp15c

LOCAL_APPS_DIR=/opt
INSTALL_DIR=${LOCAL_APPS_DIR}/hp15c

APP_FILE_NAME=HP-15C
APP_FILE_PATH=${INSTALL_DIR}/${APP_FILE_NAME}

ICON_DIR=${INSTALL_DIR}/doc/images
ICON_FILE_PATH=${ICON_DIR}/favicon.ico

SYSTEM_LAUNCHER_DIR=/usr/share/applications

FONT_FILE_GLOB="*.ttf"

SYSTEM_FONTS_DIR=/usr/share/fonts
SYSTEM_TTF_CALC_FONT_DIR=${SYSTEM_FONTS_DIR}/truetype/ttf-hp15c

USERS_FONTS_DIR=.fonts

USAGE="
An amazingly faithful simulation of the HP-15C RPN engineering calculator
written in Tcl/Tk by Torsten Manz.  Implements all the functions, memory,
and programmability features of the HP-15C, as well as its appearance.

http://hp-15c.homepage.t-online.de/

Note that the automatically-installed TTF font file is required to use the
calculator.
"

: <<"__COMMENT"
POST_INSTALL="
To make a menu launcher for ${SET_NAME}:

    Search for the application 'alacarte' ('Main Menu')
    Click on Accessories (in the left column)
    Click the 'New Item' button (on the right)

        Name    = HP-15C Calculator
        Command = /opt/hp15c/HP-15C
        Comment = HP-15C calculator simulator

    Load icon from /opt/hp15c/doc/images/favicon.ico
    Icon for Linux = HP-15C_48x48.png
__COMMENT

POST_INSTALL="
Note that you may need to log out and log back in for the dock to find
or pin the launcher icon.

Note that the '${INSTALL_DIR}/progs' directory contains several useful
programs written on/for the calculator simulator; each comes with an
HTML help file.

Note that this is a European product, so the default separator between
integers and decimals is ',' not '.'; you can change this from the
configuration menu by right-clicking on the bezel area of the calculator
window.

Also, you might be interested in:
- grpn (Repo; GTK, but kinda crude, shows R + I simultaneously)
- orpie (Repo; Runs in a terminal window, shows R + I simultaneously)
- rpncalc ('.deb'; HP-28S sim, runs in a terminal using typed commands)
"

#
# Display the usage if there are no parameters provided
#
[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

#
# *** APPLICATION ***
#
# Glob the files that correspond to the system's bit size, then
# translate the source 'glob' name into the actual file name:
#
GetOSversion
if [[ ${ARCH} == "x86_64" ]]; then

    SOURCE_GLOB="*Linux_x86_64*.zip"
else
    SOURCE_GLOB="*Linux_x86_32*.zip"
fi

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

#
# Create the installation directory (owned by root):
#
QualifySudo
makdir "${INSTALL_DIR}"

#
# Unzip the install package into the directory just created:
#
echo "Unzipping the ${SET_NAME} files... "
sleep 2

sudo unzip "${FILE_LIST}" -d "${INSTALL_DIR}"
(( $? > 0 )) && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
        "Cannot unzip the installation tarball into '${INSTALL_DIR}' !"

sudo chown -R root:root "${INSTALL_DIR}"
sudo chmod 755 "${APP_FILE_PATH}"

RESULT=$( which tclsh )
[[ -z ${RESULT} ]] && PACKAGE_SET="${PACKAGE_SET} tcl  "

#
# *** APPLICATION SUPPORT PACKAGES ***
#
PerformAppInstallation "-r" "$@"

#
# *** FONT PACKAGE ***
#
# Copy the calculator font to the collection of OS fonts;
# Start by making a subdir in the System TTF directory for the calc fonts:
#
makdir "${SYSTEM_TTF_CALC_FONT_DIR}"

#
# Translate the font 'glob' name into the actual file name(s), then
# Copy the font file(s) into the directory just created:
#
ResolveGlobFilename "fullpath" "${INSTALL_DIR}" 1 ${FONT_FILE_GLOB}

for FONT_FILE in "${FILE_LIST[@]}"; do

    copy "${FONT_FILE}" "${SYSTEM_TTF_CALC_FONT_DIR}/"

    sudo chmod 644 "${SYSTEM_TTF_CALC_FONT_DIR}"/*
done

#
# Get a list of user accounts & their info, and install fonts for each:
#
: <<"__COMMENT"
GetUserAccountInfo
QualifySudo

echo
for THIS_USER in "${USER_LIST[@]}"; do

    if [[ -d "${HOME_LIST[${THIS_USER}]}" ]]; then

        echo "...installing fonts for '${THIS_USER}' "

        # Create the user's font directory (as needed):
        #
        FONT_INSTALL_DIR=${HOME_LIST[${THIS_USER}]}/${USERS_FONTS_DIR}

        makdir "${FONT_INSTALL_DIR}"

        chgdir "${SYSTEM_TTF_CALC_FONT_DIR}"

        copy * "${FONT_INSTALL_DIR}/"

        sudo chown -R ${UID_LIST[${THIS_USER}]}:${GID_LIST[${THIS_USER}]} \
                    "${FONT_INSTALL_DIR}"

        sudo chmod -R 644 "${FONT_INSTALL_DIR}"
        sudo chmod 750 "${FONT_INSTALL_DIR}"
    fi
done
__COMMENT

#
# Copy the .desktop launcher file into place and customize for this app:
#
SOURCE_GLOB="*.desktop"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
APP_LAUNCHER_PATH=${FILE_LIST}

sudo desktop-file-install --dir=${SYSTEM_LAUNCHER_DIR} --mode=644 \
--set-name="HP-15C Calculator" \
--set-generic-name="Calculator" \
--set-comment="HP-15C calculator simulator" \
--set-icon=${ICON_FILE_PATH} \
--set-key="Exec"        --set-value="${APP_FILE_PATH}" \
--set-key="Terminal"    --set-value="false" \
--set-key="Type"        --set-value="Application" \
--set-key="Categories"  --set-value="Utility;" \
${APP_LAUNCHER_PATH}

InstallComplete

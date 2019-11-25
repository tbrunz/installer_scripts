#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install gedit plug-ins (versions 2.0-3.6 & 3.8+)
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


InstallGedit() {
#
# Install gedit and zenity if they aren't installed by Default
#
SET_NAME="gEdit"
PACKAGE_SET="gedit  gedit-plugins  zenity  "

PerformAppInstallation "-r"
}


InstallGedit38plus() {
#
# Create the installation directory, then copy the install package
# payloads into the directory created, one by one:
#
makdir "${PLUGIN_DIR}"

for PLUGIN in "${TMP_PATH}"/* ; do

    PLUGIN=$( basename ${PLUGIN} )

    # Within each plugin directory (just unpacked) is either of
    # 1.) a '.plugin' file + a '.py' file
    # 2.) a '.plugin' file + a directory with a matching name
    #
    for PART in "${PLUGIN}.plugin" "${PLUGIN}.py" "${PLUGIN}" ; do

        # Create a pathname to each of the three possibilities...
        #
        THIS_PATH=${TMP_PATH}/${PLUGIN}/${PART}

        # Then, for the two that actually exist, copy them to the plugin dir:
        #
        if [[ -f "${THIS_PATH}" || -d "${THIS_PATH}" ]]; then
            copy "${THIS_PATH}" "${PLUGIN_DIR}/"
        fi
    done

    echo "...Installed plugin '${PLUGIN}'. "
    #sudo chmod 755 "${PLUGIN_DIR}"/*
    sleep 1
done
}


InstallGedit23() {
#
# Create the installation directory, then copy the install package
# payload into the directory created:
#
makdir "${PLUGIN_DIR}"

copy ${TMP_PATH}/* "${PLUGIN_DIR}/"

#sudo chmod 755 "${PLUGIN_DIR}"/*

sleep 2
}


#
# Extract the version number for 'gedit':
#
GEDIT_VERS=$( gedit --version 2>/dev/null \
        | egrep -o '\b[[:digit:]]+[.][[:digit:]]+' 2>/dev/null )

GEDIT_MAJOR=$( printf %s ${GEDIT_VERS} | cut -d '.' -f 1 )
GEDIT_MINOR=$( printf %s ${GEDIT_VERS} | cut -d '.' -f 2 )

if [[ -z "${GEDIT_MAJOR}${GEDIT_MINOR}" ]]; then

#    ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
#            "Could not get a version number for 'gedit' ! "
    InstallGedit

    echo "
        'gedit' and 'zenity' are now installed.  You need to re-run this script
        in order to install the set of gedit plug-ins. "
    echo
    return
fi

USAGE_38_PLUS="
Advanced Find:
    Find/Replace in active document or all opened documents.
    Find/Replace in currently selected text.
    Find in all files in a selected directory.
    Supports select and find next/previous.
    Supports find via regular expressions.
    Supports multi-line patterns.
    Highlights search results + shows results in bottom panel.
https://code.google.com/p/advanced-find/

Control Your Tabs:
    Ctrl + Tab / Ctrl + Shift + Tab = switch tabs in most recently used order.
    Ctrl + Page Up / Ctrl + Page Down = switch tabs in tab-bar order.
https://github.com/jefferyto/gedit-control-your-tabs/

Necronomicon:
    The 'File > Recently Closed' sub-menu lists recently-closed files.
    To reopen one of these files, select the corresponding menu item.
    Ctrl+Shift+O will also reopen the most recently closed file.
https://github.com/jefferyto/gedit-necronomicon/

Smart Highlighting:
    Highlights all occurrences of selected text.
    Matches occurrences using regular expressions.
    Highlighting colors and matching options are configurable.
https://code.google.com/p/smart-highlighting-gedit/
"

USAGE_2_3="
Split View:
    Show a split view of a single document.

Intelligent Text Completion:
    This 'gedit' plugin aims to make editing easier by automatically
    adding text that you probably would have typed anyway.

    Features:
        * Auto-close brackets and quotes
        * Auto-complete XML tags
        * Detects lists and automatically creates new list items
        * Auto-indent after function or list

    http://code.google.com/p/gedit-intelligent-text-completion/
"

POST_INSTALL="
    You will need to restart 'gedit' for the changes to take effect.
    Then go to 'Edit > Preferences > Plugins' and check the boxes for
    each plugin to be enabled.  Refer to the 'usage' for details on each.
"

#
# Set up the variables that are dependent on the version of 'gedit':
#
if (( GEDIT_MAJOR == 3 && GEDIT_MINOR > 7 )); then
    GEDIT_VERS=3.8
    SET_NAME="gedit 3.8+ plugins"
    USAGE=${USAGE_38_PLUS}

    SOURCE_GLOB="gedit3*.tgz"
    PLUGIN_DIR=/usr/lib/gedit/plugins

elif (( GEDIT_MAJOR > 2 && GEDIT_MAJOR < 4 )); then
    GEDIT_VERS=3
    SET_NAME="gedit 3.0-3.6 plugins"
    USAGE=${USAGE_2_3}

    SOURCE_GLOB="*gedit3.tgz"
    PLUGIN_DIR=/usr/lib/gedit/plugins

elif (( GEDIT_MAJOR > 1 && GEDIT_MAJOR < 3 )); then
    GEDIT_VERS=2
    SET_NAME="gedit 2.0 plugins"
    USAGE=${USAGE_2_3}

    SOURCE_GLOB="*gedit2.tgz"
    PLUGIN_DIR=/usr/lib/gedit-2/plugins

else
    ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
            "These plugins don't work with gedit version ${GEDIT_VERS} ! "
fi

#
# If no arguments, display the 'usage' prompt:
#
[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

#
# Otherwise, get a list of the scripts to install:
#
SOURCE_DIR="../gedit"
ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

#
# Copy the install package(s) to a temp directory & unpack:
#
QualifySudo
maketmp -d

for TAR_FILE in "${FILE_LIST[@]}" ; do

    tar_zip "gz" "${TAR_FILE}" -C "${TMP_PATH}"
done

#
# Perform the installation
#
if [[ ${GEDIT_VERS} == "3.8" ]]; then InstallGedit38plus

elif [[ ${GEDIT_VERS} == "3" || ${GEDIT_VERS} == "2" ]]; then InstallGedit23

else
    sudo rm -rf ${TMP_PATH}
    ThrowError "${ERR_UNSPEC}" "${APP_SCRIPT}" \
            "Internal failure resolving the version of 'gedit' ! "
fi

#
# Clean up & complete...
#
sudo rm -rf ${TMP_PATH}

InstallComplete

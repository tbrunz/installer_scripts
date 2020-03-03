#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Misc fixups for Ubuntu installations
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


# NOTE: This script is a set of independent stanzas, each of which must
# handle its own errors, report its own results, and not exit the script.


##############################################################################
#
# Disable the "you can upgrade your distro now" nag-mails.
#
QualifySudo
[[ -f "/etc/update-motd.d/91-release-upgrade" ]] && \
    sudo chmod -x /etc/update-motd.d/91-release-upgrade


##############################################################################
#
# Fix the bad icon reference for the 'grpn' calculator app,
# (Only if it's actually installed, of course.)
#
ICONS_FOLDER=/usr/share/icons
GNOME_ICONS_APPS=gnome/48x48/apps
CALC_ICON=accessories-calculator.png

GRPN_ICON_PATH=${ICONS_FOLDER}/${GNOME_ICONS_APPS}/${CALC_ICON}

LAUNCHER_FOLDER=/usr/share/applications
GRPN_LAUNCHER=grpn.desktop
GRPN_ICON_LINE="Icon=grpn"

if [[ -x "${LAUNCHER_FOLDER}/${GRPN_LAUNCHER}" ]]; then

    sed -i -r -e \
        "s|${GRPN_ICON_LINE}|${GRPN_ICON_PATH}|" \
        "${LAUNCHER_FOLDER}/${GRPN_LAUNCHER}"
fi


##############################################################################
#
# Fix the apt-get & 'lvmetad' error notification papercuts.
# (This is done silently, and as necessary.)
#
UPDATE_NOTIFIER_DIR=/var/lib/update-notifier/package-data-downloads/partial

# Tell LVM to cache its data to prevent the 'lvmetad' annoyance errors.
# (This fix will not throw an error if LVM is not in use on the system.)
#
QualifySudo
sudo pvscan --cache 2>/dev/null

# Make sure the owner of the package downloads 'partial' directory is '_apt'.
# Note that some distros don't have this folder...
#
RESULT=$( getent passwd _apt )

if [[ -n "${RESULT}" && -d "${UPDATE_NOTIFIER_DIR}" ]]; then

    sudo chown _apt "${UPDATE_NOTIFIER_DIR}"
fi


##############################################################################
#
# Reduce the swap file/partition use
#
SYSTEM_CONTROL_FILE=/etc/sysctl.conf

SWAPPINESS_CTL="vm.swappiness"
CACHE_PRESSURE="vm.vfs_cache_pressure"

__Append_Blank_Line () {
    echo "" | sudo tee -a "${SYSTEM_CONTROL_FILE}" >/dev/null
}

__Append_Swappiness_Line () {
    echo "vm.swappiness=10" | \
            sudo tee -a "${SYSTEM_CONTROL_FILE}" >/dev/null
}

__Append_Cache_Pressure_Line () {
    echo "vm.vfs_cache_pressure=50" | \
            sudo tee -a "${SYSTEM_CONTROL_FILE}" >/dev/null
}

echo
Get_YesNo_Defaulted 'y' \
    "Do you want to throttle the use of swap?"

if (( $? == 0 )); then
    sudo cp -f "${SYSTEM_CONTROL_FILE}" "${SYSTEM_CONTROL_FILE}".bak

    sudo sed -i -r -e 's|^(vm.swappiness)[[:space:]]*=.*$|\1=10|' \
            "${SYSTEM_CONTROL_FILE}"

    sudo sed -i -r -e 's|^(vm.vfs_cache_pressure)[[:space:]]*=.*$|\1=50|' \
            "${SYSTEM_CONTROL_FILE}"

    grep -q '^vm.swappiness' "${SYSTEM_CONTROL_FILE}"
    RESULT=$(( $? == 0 ? 0 : 2 ))

    grep -q '^vm.vfs_cache_pressure' "${SYSTEM_CONTROL_FILE}"
    RESULT=$(( $? == 0 ? RESULT : RESULT + 1 ))

    case ${RESULT} in
    0)  # Both are present; nothing to do...
        ;;
    1)  # Need a cache pressure line:
        __Append_Blank_Line
        __Append_Cache_Pressure_Line
        ;;
    2)  # Need a swappiness line:
        __Append_Blank_Line
        __Append_Swappiness_Line
        ;;
    3)  # Neither are present; add both:
        __Append_Blank_Line
        __Append_Swappiness_Line
        __Append_Cache_Pressure_Line
        ;;
    *)  # Something blew up!
        echo >&2 "${0}: Failure attempting to edit '${SYSTEM_CONTROL_FILE}' ! "
        return 1
        ;;
    esac
fi


##############################################################################
#
# Ask the user if he wishes to disable suspend/hibernate.
#
SERVICES=(
    "sleep"
    "suspend"
    "hibernate"
    "hybrid-sleep"
    )

SOURCE_DIR=../x-special/disable-suspend
SOURCE_FILE=com.ubuntu.disable-suspend.pkla
DEST_DIR=/etc/polkit-1/localauthority/50-local.d/

echo
Get_YesNo_Defaulted 'y' \
    "Do you want to disable the ability to suspend/hibernate this PC?"

if (( $? == 0 )); then

    if (( MAJOR < 16 )); then
        copy "${SOURCE_DIR}"/"${SOURCE_FILE}" "${DEST_DIR}"
    else
        QualifySudo
        for SERVICE in "${SERVICES[@]}"; do
            #
            # Manually run this with "unmask" to re-enable.
            # Check '/etc/systemd/system/<service>=<path>'.
            # When disabled, the <path> is '/dev/null'.
            #
            sudo systemctl mask ${SERVICE}.target
        done
    fi

    echo "You will need to re-enable this manually."
fi
#echo


##############################################################################
#
# Ask if we should make the usernames visible in the notification area.
#
UNITY=$( printf "%s" "${XDG_CURRENT_DESKTOP}" | grep -i unity )

if (( $? == 0 )); then
    SHOW_NAME=false

    echo
    Get_YesNo_Defaulted 'y' \
        "Do you want to show usernames in the notification area?"

    (( $? == 0 )) && SHOW_NAME=true

    gsettings set \
        com.canonical.indicator.session show-real-name-on-panel ${SHOW_NAME}

    echo
    echo "  *** TODO: Need to mod this script to apply this to each account ! "
fi


##############################################################################
#
# Fix the defective GNOME Resource file 'defaults.list' entry in /etc/X11.
# (This will be skipped if the affected files are not detected.)
#
GNOMERC_FILE=/etc/X11/Xsession.d/55gnome-session_gnomerc
GNOMERC_DEFECT=/usr/share/gnome:/usr/local/share
GNOMERC_REPAIR=/usr/local/share:/usr/share/gnome

grep "${GNOMERC_DEFECT}" "${GNOMERC_FILE}" &>/dev/null

if (( $? == 0 )); then
    echo
    echo
    Get_YesNo_Defaulted 'y' "Do you want to fix the GNOME resource file?"
    if (( $? == 0 )); then

        QualifySudo
        sudo sed -i \
            -e "s|${GNOMERC_DEFECT}|${GNOMERC_REPAIR}|" "${GNOMERC_FILE}"

        if (( $? == 0 )); then
            echo "The GNOME Resource file has been fixed. "
        else
            echo "Could not make changes to ${GNOMERC_FILE} ! "
        fi
    fi
fi


##############################################################################
#
# Remove the Unity "shopping" lens.
# (This will be skipped if the shopping lens package is not detected.)
#
UNITY_SHOPPING_PKG="unity-lens-shopping"

dpkg -s "${UNITY_SHOPPING_PKG}" >/dev/null 2>&1

if (( $? == 0 )); then

    echo
    Get_YesNo_Defaulted 'y' "Do you want to remove '${UNITY_SHOPPING_PKG}'?"
    if (( $? == 0 )); then

        QualifySudo
        sudo apt-get -qy purge "${UNITY_SHOPPING_PKG}"

        if (( $? == 0 )); then
            echo "Done. "
        else
            echo "Could not remove package '${UNITY_SHOPPING_PKG}' ! "
        fi
    fi
fi


##############################################################################
#
# Disable the Unity shopping scopes.
# (Affects 14.04 Trusty & earlier LTS versions, skipped for later versions.)
#
if (( MAJOR < 16 )); then

    echo
    Get_YesNo_Defaulted 'y' "Do you want to remove the Unity shopping scopes?"
    if (( $? == 0 )); then

        gsettings set com.canonical.Unity.Lenses disabled-scopes \
            "['more_suggestions-amazon.scope', 'more_suggestions-u1ms.scope',
        'more_suggestions-populartracks.scope', 'music-musicstore.scope',
        'more_suggestions-ebay.scope', 'more_suggestions-ubuntushop.scope',
        'more_suggestions-skimlinks.scope']"

        if (( $? == 0 )); then
            echo "Shopping Scopes have been removed from Unity. "
        else
            echo "Could not remove Shopping Scopes from Unity ! "
        fi
    else
        echo -n "(No attempt has been made to add them back "
        echo    "if they were previously removed.)"
    fi
fi


##############################################################################
#
# Disable 'apport' to prevent annoying crash pop-ups
#
APPORT_FILE=/etc/default/apport

echo
Get_YesNo_Defaulted 'y' \
    "Do you want to disable crash reporting ('apport')?"
if (( $? == 0 )); then

    KEY_VALUE=0
    ENABLE_STATE="disabled"
    sudo service apport stop >/dev/null 2>&1
else
    KEY_VALUE=1
    ENABLE_STATE="enabled"
fi

QualifySudo
sudo sed -i -r -e "s/enabled=1/enabled=${KEY_VALUE}/" "${APPORT_FILE}"

if (( $? == 0 )); then
    echo "The 'apport' service is now ${ENABLE_STATE}. "
else
    echo "Attempt to edit '${APPORT_FILE}' failed ! "
fi


##############################################################################
#
# Fix the bug that results in multi-level RAID arrays not being built.
# (Affects 14.04 Trusty & earlier LTS versions; this bug was fixed by 16.04.)
#
DEST_DIR=/lib/udev/rules.d

SOURCE_DIR="../x-special/mdadm"
SOURCE_GLOB="*md-raid*"

if (( MAJOR < 16 )); then
    echo
    Get_YesNo_Defaulted 'y' \
        "Do you want to fix the multi-level RAID array assembly bug?"

    if (( $? == 0 )); then

        if [[ -d "${DEST_DIR}" ]]; then

            ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

            QualifySudo
            for FILE_PATH in "${FILE_LIST[@]}"; do

                copy "${FILE_PATH}" "${DEST_DIR}"/
            done

            echo "Done. "
        else
            echo "Cannot find directory '${DEST_DIR}' ! "
        fi
    fi
fi


##############################################################################
#
# Blacklist the Intel MEI / MEI_ME security risk spyhole.
# MEI = Intel Management Engine (separate CPU/OS within enterprise PCs)
#
MEI_CONF_FILE=blacklist-mei.conf

echo
Get_YesNo_Defaulted 'y' \
    "Do you want to blacklist the MEI/MEI_ME kernel driver modules?"

if (( $? == 0 )); then

    QualifySudo
    echo "blacklist mei" | sudo tee -a /etc/modprobe.d/${MEI_CONF_FILE}
    echo "blacklist mei_me" | sudo tee -a /etc/modprobe.d/${MEI_CONF_FILE}
fi


##############################################################################
#
# If Nvidia drivers are being used, offer to fix the empty-initial-config bug.
# (Skipped if Nvidia drivers are not detected on the system.)
#
RESULT=$( which nvidia-xconfig )

if [[ -n "${RESULT}" ]]; then

    echo
    Get_YesNo_Defaulted 'n' \
        "Do you want to work around the Nvidia empty-initial-config bug?"

    if (( $? == 0 )); then
        QualifySudo
        sudo nvidia-xconfig --allow-empty-initial-configuration
    else
        QualifySudo
        sudo nvidia-xconfig --no-allow-empty-initial-configuration
    fi
fi


##############################################################################
#
# Add CompizConfig Setting Manager (14.04 Trusty and later versions).
# Enables minimizing single-window apps from the dock launcher icon.
# (Only available for 14.04 Trusty and later versions.)
#

COMPIZ_MANAGER_PKG=compizconfig-settings-manager

RESULT=$( dpkg -s "${COMPIZ_MANAGER_PKG}" 2>&1 )
UNITY=$( printf "%s" "${XDG_CURRENT_DESKTOP}" | grep -i unity )

if (( $? == 0 && MAJOR >= 14 )); then

    echo
    Get_YesNo_Defaulted 'n' \
        "Do you want to enable minimizing single-window apps from the dock?"

    if (( $? == 0 )); then

        printf %s "${RESULT}" | grep -q "not installed"
        CCSM=$(( 1 - $? ))

        if (( CCSM == 1 )); then
            QualifySudo
            sudo apt-get install -y ${COMPIZ_MANAGER_PKG}
            CCSM=$?
        fi

        if (( CCSM == 0 )); then

            echo "
    To enable minimizing single-window apps from the dock launcher icon,
    run 'compizconfig-settings-manager' (from the Dash), then locate the
    'Ubuntu Unity Plugin' icon (in the window); click it, then select the
    'Launcher' tab and find the 'Minimize single window applications'
    checkbox and enable it.  (Changes takes effect immediately.)
    "

        fi # Tool already installed | installed correctly
    fi # User doesn't want it
fi # Can't install the tool


##############################################################################
#
# Enable setting Unity low graphics mode (good for VM or old PC use).
# (Only available for 14.04 Trusty and later versions.)
#
#
DCONF_PKG="dconf-editor"

UNITY=$( printf "%s" "${XDG_CURRENT_DESKTOP}" | grep -i unity )

if (( $? == 0 && MAJOR >= 14 )); then

    echo
    Get_YesNo_Defaulted 'y' \
        "Do you want to be able to enable Unity low graphics mode?"

    if (( $? == 0 )); then

        gsettings set com.canonical.Unity lowgfx true
        RESULT=$?
    else
        gsettings set com.canonical.Unity lowgfx false
        RESULT=$?
    fi

    # Install the GUI tool to make it easy to change this later:
    #
    if (( ${RESULT} == 0 )); then
        QualifySudo
        RESULT=$( sudo apt-get install -y ${DCONF_PKG} )

        echo "
    To enable/disable Unity low graphics mode in the future, search for
    and launch 'dconf-editor' from the Dash.  Open 'com', then 'canonical',
    then 'unity', and locate 'lowgfx' in the list on the right.  Check the
    checkbox to enable.

    Alternatively, you can control this feature with the command line.  Use
        gsettings get com.canonical.Unity lowgfx

    to query the setting and
        gsettings set com.canonical.Unity lowgfx true|false

    to set the desired option.
    "
    fi
fi


##############################################################################

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
# Fix the apt-get & 'lvmetad' error notification papercuts:
#
UPDATE_NOTIFIER_DIR=/var/lib/update-notifier/package-data-downloads/partial

# Tell LVM to cache its data to prevent the 'lvmetad' annoyance errors.
# (This will not throw an error even if LVM is not in use on the system.)
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
# Notify the user about how to enable 'gnotifier' in Firefox:
#
echo "
    Ctrl-click the following link or open Firefox and surf to

        https://addons.mozilla.org/en-US/firefox/addon/gnotifier/

    to install 'GNotifier', which integrates Firefox's notifications with
    the native notification system used by the Linux desktop.
"

#read -r -s -n 1 -p "Press any key to continue. "
#echo


##############################################################################
#
# Notify the user about how to enable download progress bar in Firefox:
#
echo "
    Ctrl-click the following link or open Firefox and surf to

        https://addons.mozilla.org/en-US/firefox/addon/unityfox-revived/

    to install 'UnityFox-Revived', which adds a download counter & progress
    bar to the launcher icon in the Unity desktop (similar to Nautilus).
"

#read -r -s -n 1 -p "Press any key to continue. "
#echo


##############################################################################
#
# Notify the user about how to add a reset button to Firefox:
#
echo "
    Ctrl-click the following link or open Firefox and surf to

        https://addons.mozilla.org/En-us/firefox/addon/re-start/

    to install a 'reset' button in the Firefox 'hamburger' menu.
"

read -r -s -n 1 -p "Press any key to continue. "
echo


##############################################################################
#
# Ask the user if he wishes to disable suspend/hibernate:
#
SOURCE_DIR=../x-special/disable-suspend
SOURCE_FILE=com.ubuntu.disable-suspend.pkla
DEST_DIR=/etc/polkit-1/localauthority/50-local.d/

echo
Get_YesNo_Defaulted 'y' \
    "Do you want to disable the ability to suspend/hibernate this PC?"

if (( $? == 0 )); then

    copy "${SOURCE_DIR}"/"${SOURCE_FILE}" "${DEST_DIR}"
fi
#echo


##############################################################################
#
# Ask if we should make the usernames visible in the notification area:
#
SHOW_NAME=false

echo
Get_YesNo_Defaulted 'y' \
    "Do you want to show usernames in the notification area?"

(( $? == 0 )) && SHOW_NAME=true

gsettings set \
    com.canonical.indicator.session show-real-name-on-panel ${SHOW_NAME}

echo
echo "  *** TODO: Need to mod this script to apply this to each account ! "


##############################################################################
#
# Fix the defective GNOME Resource file 'defaults.list' entry in /etc/X11:
#
GNOMERC_FILE=/etc/X11/Xsession.d/55gnome-session_gnomerc
GNOMERC_DEFECT=/usr/share/gnome:/usr/local/share
GNOMERC_REPAIR=/usr/local/share:/usr/share/gnome

grep "${GNOMERC_REPAIR}" "${GNOMERC_FILE}" >/dev/null 2>&1

if (( $? > 0 )); then

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
# Remove the Unity "shopping" lens:
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
# Disable the Unity shopping scopes:
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
    "Do you want to disable crash report pop-ups ('apport')?"
if (( $? == 0 )); then

    KEY_VALUE=0
    ENABLE_STATE="disabled"
    sudo service apport stop >/dev/null 2>&1
else
    KEY_VALUE=1
    ENABLE_STATE="enabled"
fi

QualifySudo
sudo sed -i -r -e "s/enabled=1/enabled=${KEY_VALUE}/" ${APPORT_FILE}

if (( $? == 0 )); then
    echo "The 'apport' service is now ${ENABLE_STATE}. "
else
    echo "Attempt to edit '${APPORT_FILE}' failed ! "
fi


##############################################################################
#
# Fix the bug that results in multi-level RAID arrays not being built
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
# Blacklist the Intel MEI / MEI_ME security risk spyhole
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
# If Nvidia drivers are being used, offer to fix the empty-initial-config bug
#
RESULT=$( which nvidia-xconfig )

if [[ -n "${RESULT}" ]]; then

    echo
    Get_YesNo_Defaulted 'y' \
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
# Add CompizConfig Setting Manager
#  - Enables minimizing single-window apps from the launcher dock
#  - Enables setting Unity low graphics mode (good for VM use)
#

#
# With the 16.04 SRU (12/01/17ff), this will change:
# The below checkbox will be removed, and instead the following
# 'dconf' setting must be used instead:
#
# To enable, "gsettings set com.canonical.Unity lowgfx true"
# To disable, "gsettings set com.canonical.Unity lowgfx false"
#


COMPIZ_MANAGER_PKG=compizconfig-settings-manager

RESULT=$( dpkg -s "${COMPIZ_MANAGER_PKG}" 2>&1 )

if (( MAJOR >= 14 )); then

    echo
    Get_YesNo_Defaulted 'y' \
        "Do you want to be able to enable Unity low graphics mode (CCSM)?"

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
    Run 'compizconfig-settings-manager' (from the Dash), then locate the
    'Ubuntu Unity Plugin' icon (in the window); click it, then select:

    1. The 'General' tab and find the 'Enable Low Graphics Mode' checkbox
    and enable it.  (Changes take effect immediately.)

    2. The 'Launcher' tab and find the 'Minimize single window applications'
    checkbox and enable it.  (Changes takes effect immediately.)
            "
            #            read -r -s -n 1 -p "Press any key to continue. "
            #            echo

        fi # Tool already installed | installed correctly
    fi # User doesn't want it
fi # Can't install the tool


##############################################################################

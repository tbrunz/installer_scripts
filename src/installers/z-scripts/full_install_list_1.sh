#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install a list of apps by calling a series of installation scripts
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

echo "This script is too out of date to run without editing first..."
exit

##############################################################################
#
# List of the installer scripts that are to be run, in order, with the 
# indicated switches.  Edit this list, as desired, to add/remove/reorder.
#
SCRIPT_LIST=(

"install-apt-cacher.sh -n"
"do-update-all.sh"

"install-base.sh -n"
"install-fonts.sh -n"

"install-gedit-plugins.sh -n"
"install-vim.sh -n"

"install-crossover-deb.sh -n"
"install-mawk.sh -n"
"install-gawk.sh -n"
"install-perf-test.sh -n"

"install-java.sh 7 -n"
"install-jbidwatcher.sh -n"
"install-hp15c.sh -n"

"install-ppa-manager.sh -p"
"install-ppa-audio-recorder.sh -p"
"install-ppa-chrome.sh -p"
"install-ppa-grub-customizer.sh -p"
"install-ppa-ubuntu-tweak.sh -p"
"install-ppa-banshee.sh -p"
"install-ppa-wine.sh -p"

"install-subversion.sh -u"

"install-ppa-manager.sh -n"
"install-ppa-audio-recorder.sh -n"
"install-ppa-chrome.sh -n"
"install-ppa-grub-customizer.sh -n"
"install-ppa-ubuntu-tweak.sh -n"

"install-multimedia.sh -n"
"install-ppa-banshee.sh -n"
"install-ppa-wine.sh 1.7 -n"
"install-gnome3.sh -n"
"install-ppa-gnome3.sh -u"
"install-fwknop.sh -n"

"fix-apt.sh"
"fix-bash.sh"
"fix-ubuntu.sh"
)


##############################################################################
#
# Add the APT keys & repositories for the list of desired PPA-type installers 
# by calling each 'install-ppa' script with the '-p' option.
#
Call_Installer_Scripts() {

local SCRIPT_FILE

(( ${#SCRIPT_LIST[@]} < 1 )) && return

for SCRIPT_FILE in "${SCRIPT_LIST[@]}"; do
    
    # Do NOT quote the script file argument, so that its switches will be 
    # presented separately; otherwise the whole string looks like a filename.
    #
    echo
    sleep 1
    read -r -s -n 1 \
        -p "Ready to install '${SCRIPT_FILE}'; Press any key to continue... "
    echo
    sudo bash ${SCRIPT_FILE}
done
}


##############################################################################
#
# Add the APT keys & repositories for the list of desired PPA-type installers 
# by calling each 'install-ppa' script with the '-p' option.
#
Install_Hosts_Files(){

Get_YesNo_Defaulted "y" \
        "Do you want to install the 'hosts blocking' files?"

(( $? != 0 )) && return

if [[ ! -f /etc/hosts-base ]]; then

    Get_YesNo_Defaulted "y" \
            "Can't find '/etc/hosts-base'; Re-try installation?"
    
    (( $? != 0 )) && return
fi

[[ -f /etc/hosts-base ]] && sudo bash install-hosts-files.sh
}


##############################################################################
#
# Add the APT keys & repositories for the list of desired PPA-type installers 
# by calling each 'install-ppa' script with the '-p' option.
#
Install_VirtualBox(){

echo
Get_YesNo_Defaulted "n" \
        "Do you want to install the Ubuntu repo version of VirtualBox?"

if (( $? == 0 )); then

    sudo bash install-virtualbox.sh -n
else
    sudo bash install-ppa-virtualbox.sh 4.3 -u
fi
}


##############################################################################

QualifySudo

Install_Hosts_Files

Call_Installer_Scripts

Install_VirtualBox

##############################################################################


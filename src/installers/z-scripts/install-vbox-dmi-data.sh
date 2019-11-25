#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install DMI data to a VirtualBox virtual machine's BIOS
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


declare -A DMI_DATA_LIST

VBOX_MANAGE_CMD=vboxmanage


USAGE="
This script sets the DMI Data of an indicated virtual machine, using either the 
host's DMI Data or pre-supplied DMI Data (in this case, for an HP Pavilion PC).

In order for a virtual machine to fully emulate a host platform, to the point 
where an installed application or operating system (in particular, Windows XP) 
will self-activate, it is necessary to propagate the DMI Data in the host's 
BIOS into the corresponding DMI Data of the VM's BIOS.

When running Windows XP as the guest OS, this allows the XP installation to 
automatically authenticate and activate.  (This does not work with Windows 
Vista and later OSes, as they use a different activation mechanism.)
"

SET_NAME="VBox DMI Data"

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

# First off, is VirtualBox even installed on this machine?
#
VBOX_MGR_LOC=$( which ${VBOX_MANAGE_CMD} )

[[ -z "${VBOX_MGR_LOC}" ]] && ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
        "Cannot find the VirtualBox manager app! (Is VBox installed?) "

# Assemble a list of all virtual machines installed on this host:
#
VM_LIST=()

while read -r VM_NAME ; do

    VM_LIST+=( "${VM_NAME}" )

done < <( ${VBOX_MANAGE_CMD} list vms | cut -d '"' -f 2 )

# How many did we find?  If none, trouble.. If one, no need to ask..
#
NUM_VMS=${#VM_LIST[@]}

(( NUM_VMS == 0 )) && ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
        "Cannot find any virtual machines! (Have you created any?) "

if (( NUM_VMS == 1 )); then

    VM_NAME=${VM_LIST}
    
    Get_YesNo_Defaulted "y" "Found only one VM, '${VM_NAME}'; is this okay?"
    
    (( $? > 0 )) && exit ${ERR_UNSPEC}
    
else
    # Create a menu that shows all virtual machines installed on this host:
    #
    echo
    echo "Select which virtual machine you wish to set the DMI data for: "
    
    select VM_NAME in "${VM_LIST[@]}"; do

        [[ -n "${VM_NAME}" ]] && break
            
        echo "Just pick one of the listed machines, okay? "
    done
fi

# Determine what type of BIOS the VM has:
#
RESULT=$( vboxmanage showvminfo "${VM_NAME}" | grep Firmware | grep EFI )

if [[ -z "${RESULT}" ]]; then

    BIOS_EFI=pcbios
else
    BIOS_EFI=efi
fi

# Read the host's DMI Data:
#
Read_Host_DMI() {

    local SEPARATOR=":"

    QualifySudo
    sudo dmidecode -${1} | \
    sed -nre "s/[[:space:]]${2}[[:space:]]*${SEPARATOR}[[:space:]]*(.+)/\1/p"
}

# If this host is the WinXP OEM license source, offer to read its values:
#
Get_YesNo_Defaulted "n" "Do you wish to use the DMI data of this host?"
    
if (( $? == 0 )); then
    DMI_DATA_LIST=(
    
    [DmiBIOSVendor]=$( Read_Host_DMI t0 "Vendor" )
    [DmiBIOSVersion]=$( Read_Host_DMI t0 "Version" )
    [DmiBIOSReleaseDate]=$( Read_Host_DMI t0 "Release Date" )
    
    [DmiBIOSReleaseMajor]="2"
    [DmiBIOSReleaseMinor]="1"
    [DmiBIOSFirmwareMajor]="2"
    [DmiBIOSFirmwareMinor]="1"
    
    [DmiSystemVendor]=$( Read_Host_DMI t1 "Manufacturer" )
    [DmiSystemProduct]=$( Read_Host_DMI t1 "Product Name" )
    [DmiSystemVersion]=$( Read_Host_DMI t1 "Version" )
    [DmiSystemSerial]=$( Read_Host_DMI t1 "Serial Number" )
    [DmiSystemUuid]=$( Read_Host_DMI t1 "UUID" )
    [DmiSystemFamily]=$( Read_Host_DMI t1 "Family" )
    
    [DmiOEMVBoxVer]=$( Read_Host_DMI t11 "String 2" )
    [DmiOEMVBoxRev]=$( Read_Host_DMI t11 "String 3" )
    )
else
    DMI_DATA_LIST=(
    
    [DmiBIOSVendor]="Hewlett-Packard"
    [DmiBIOSVersion]="A69"
    [DmiBIOSReleaseDate]="08/28/2004."
    
    [DmiBIOSReleaseMajor]="2"
    [DmiBIOSReleaseMinor]="1"
    [DmiBIOSFirmwareMajor]="2"
    [DmiBIOSFirmwareMinor]="1"
    
    [DmiSystemVendor]="Hewlett-Packard"
    [DmiSystemProduct]="Pavilion Elite D5100T0"
    [DmiSystemVersion]="Not Specified"
    [DmiSystemSerial]="6X89ZB1"
    [DmiSystemUuid]="44454C4C-5800-1038-8039-B6C04F5A4231"
    [DmiSystemFamily]=""
    
    [DmiOEMVBoxVer]="5[0003]"
    [DmiOEMVBoxRev]="13[PP18L]"
    )
fi

# Set the DMI variables:
#
for VARIABLE_NAME in "${!DMI_DATA_LIST[@]}"; do

    VBoxManage setextradata "${VM_NAME}" \
            "VBoxInternal/Devices/${BIOS_EFI}/0/Config/${VARIABLE_NAME}" \
            "${DMI_DATA_LIST[${VARIABLE_NAME}]}"
done

# Check the DMI variables ('set', then 'get' to confirm); 
# Start by making a pair of temporary files for sorting:
#
maketmp
UNSORTED_LINES=${TMP_PATH}

maketmp
SORTED_RESULTS=${TMP_PATH}

# Read each line into a file (since files can accumulate the newlines):
#
for VARIABLE_NAME in "${!DMI_DATA_LIST[@]}"; do
   
    echo -n "VBoxInternal/Devices/${BIOS_EFI}/0/Config/${VARIABLE_NAME}, " >> \
            ${UNSORTED_LINES}
    VBoxManage getextradata "${VM_NAME}" \
            "VBoxInternal/Devices/${BIOS_EFI}/0/Config/${VARIABLE_NAME}" >> \
            ${UNSORTED_LINES}
done

# Now sort the file contents into another file, then regurgitate the results:
#
sort ${UNSORTED_LINES} > ${SORTED_RESULTS}
echo

cat ${SORTED_RESULTS}
echo

# Finally, throw away the temp files:
#
rm ${UNSORTED_LINES} ${SORTED_RESULTS}

#############################################################################

